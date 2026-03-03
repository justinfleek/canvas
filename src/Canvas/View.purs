-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                           // canvas // view
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas View — Pure render function for the paint application.
-- |
-- | ## Design Philosophy
-- |
-- | The view is a pure function: AppState -> Element Msg
-- | No effects, no DOM manipulation — just Element construction.
-- |
-- | ## Render Structure
-- |
-- | ```
-- | .canvas-app
-- |   .canvas-toolbar
-- |     .brush-selector
-- |     .media-selector
-- |     .color-picker
-- |   .canvas-surface
-- |     .paint-layers
-- |       .layer[n] (particles + committed strokes)
-- |     .active-stroke-layer
-- |     .ui-layer
-- |       .gravity-indicator
-- |       .debug-overlay
-- |   .canvas-statusbar
-- |     .gravity-display
-- |     .particle-count
-- |     .fps
-- | ```
-- |
-- | ## Device Integration
-- |
-- | The view shows gravity direction based on device tilt.
-- | When device tilts, gravity indicator rotates, and paint flows.
-- |
-- | ## Dependencies
-- | - Hydrogen.Render.Element (pure element construction)
-- | - Hydrogen.Schema.Brush (all brush types)
-- | - Hydrogen.Schema.Canvas.Physics (gravity, orientation)
-- | - Canvas.State (application state)

module Canvas.View
  ( -- * Main View
    view
  
  -- * Stylus Input Type
  , StylusInput
  
  -- * Brush Category
  , BrushCategory
      ( CategoryEssentials
      , CategoryPencil
      , CategoryInk
      , CategoryWatercolor
      , CategoryOil
      , CategoryDigital
      , CategoryExpressive
      )
  , allBrushCategories
  
  -- * Msg Type
  , Msg
      ( ToolSelected
      , BrushPresetSelected
      , BrushCategorySelected
      , MediaTypeSelected
      , ColorChanged
      , ColorHSVChanged
      , BrushSizeChanged
      , BrushOpacityChanged
      -- Media settings
      , WetnessChanged
      , ViscosityChanged
      , DilutionChanged
      , PigmentLoadChanged
      , PointerDown
      , PointerMoved
      , PointerUp
      , CanvasTouched
      , CanvasMoved
      , CanvasReleased
      , OrientationChanged
      , ToggleGravity
      , TogglePlaying
      , ClearCanvas
      , Undo
      , Redo
      , Tick
      , LayerSelected
      , AddLayer
      , LayerVisibilityToggled
      , DeleteLayer
      , MoveLayerUp
      , MoveLayerDown
      -- Easter egg events
      , KeyDown
      , KeyboardShortcut
      , DeviceMotion
      -- Viewport gesture events
      , ViewportPan
      , ViewportZoom
      , ViewportZoomAt
      , ViewportRotate
      , ViewportReset
      -- Two-finger gesture events
      , TwoFingerTouch
      , TwoFingerEnd
      -- Export
      , ExportCanvas
      )
  
  -- * Sub-views
  , renderToolbar
  , renderCanvas
  , renderStatusBar
  , renderBrushSelector
  , renderMediaSelector
  , renderGravityIndicator
  , renderParticles
  , renderDebugOverlay
  , renderLayerPanel
  , renderPropertiesPanel
  , renderColorPicker
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( class Eq
  , class Show
  , show
  , (<>)
  , (*)
  , (/)
  , (<)
  , (>)
  , (+)
  , (-)
  , map
  , max
  , min
  , negate
  , not
  , (==)
  , (&&)
  )

import Data.Array (length) as Array
import Data.Int (floor, toNumber) as IntConv
import Data.Maybe (Maybe(Just, Nothing))
import Data.String.CodeUnits (charAt, singleton) as Str
import Data.Tuple (Tuple(Tuple))

-- Hydrogen Element (pure rendering)
import Hydrogen.Render.Element as E
import Hydrogen.Render.Element
  ( Element
  , div_
  , button_
  , span_
  , text
  , onClick
  , onMouseDown
  , onMouseMove
  , onMouseUp
  , onTouchStart
  , onTouchMove
  , onTouchEnd
  , class_
  , styles
  , id_
  )

-- ARIA accessibility attributes
import Hydrogen.Render.Element.Attributes
  ( ariaAtomic
  , ariaLabel
  , ariaLive
  , role
  , tabIndex
  )

-- Hydrogen Brush System
import Hydrogen.Schema.Brush.WetMedia
  ( WetMediaType
      ( Watercolor
      , OilPaint
      , Acrylic
      , Gouache
      , Ink
      , WetIntoWet
      )
  , allWetMediaTypes
  , wetMediaTypeDescription
  )

import Hydrogen.Schema.Brush.Preset.Library as Presets
import Hydrogen.Schema.Brush.Preset.Types (PresetMeta)

-- Hydrogen Math (pure PureScript, no FFI)
import Hydrogen.Math.Core (atan2, pi)

-- Hydrogen Canvas Physics
import Hydrogen.Schema.Canvas.Physics
  ( DeviceOrientation
  , GravityVector
  , gravity2D
  , gravityMagnitude
  , gravityX
  , gravityY
  , gravityZ
  )

-- Canvas State
import Canvas.State as State
import Canvas.State (AppState)
import Canvas.Types
  ( Tool(BrushTool, EraserTool, PanTool, EyedropperTool)
  , Color
  , LayerId
  , backgroundLayerId
  )
import Canvas.Paint.Particle as Paint
import Canvas.Physics.Gravity as Gravity
import Canvas.Layer.Types (Layer, sortedLayers, layerId, layerName, layerVisible)

-- Easter eggs
import Canvas.Easter as Easter

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // view state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Specialized AppState for this module's Msg type.
-- | AppState is now parameterized by message type for 3D layer handlers.
type ViewState = AppState Msg

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // msg type
-- ═════════════════════════════════════════════════════════════════════════════

-- | Stylus/touch input with full pressure and tilt data.
-- |
-- | Captures the complete state of a stylus or touch input:
-- | - Position (x, y) in canvas coordinates
-- | - Pressure (0.0-1.0) from pen force or touch force
-- | - Tilt X/Y (-90 to 90 degrees) from pen angle
-- | - Pointer type ("pen", "touch", or "mouse")
type StylusInput =
  { x :: Number
  , y :: Number
  , pressure :: Number
  , tiltX :: Number
  , tiltY :: Number
  , pointerType :: String
  }

-- | Messages that the view can emit.
-- |
-- | These are handled by the update function in Main.
-- | Brush preset category for organized display.
data BrushCategory
  = CategoryEssentials      -- ^ Core brushes everyone needs
  | CategoryPencil          -- ^ Graphite, charcoal, conte
  | CategoryInk             -- ^ Technical pens, brush pens, dip pens
  | CategoryWatercolor      -- ^ Washes, wet-on-wet, dry brush
  | CategoryOil             -- ^ Round, flat, filbert, palette knife
  | CategoryDigital         -- ^ Hard/soft round, airbrush, glow
  | CategoryExpressive      -- ^ Mood-based presets (calm, intense, nostalgic)

derive instance eqBrushCategory :: Eq BrushCategory

instance showBrushCategory :: Show BrushCategory where
  show CategoryEssentials = "Essentials"
  show CategoryPencil = "Pencil"
  show CategoryInk = "Ink"
  show CategoryWatercolor = "Watercolor"
  show CategoryOil = "Oil"
  show CategoryDigital = "Digital"
  show CategoryExpressive = "Expressive"

-- | All brush categories for iteration.
allBrushCategories :: Array BrushCategory
allBrushCategories = 
  [ CategoryEssentials
  , CategoryPencil
  , CategoryInk
  , CategoryWatercolor
  , CategoryOil
  , CategoryDigital
  , CategoryExpressive
  ]

data Msg
  = ToolSelected Tool
  | BrushPresetSelected String           -- ^ Preset name
  | BrushCategorySelected BrushCategory  -- ^ Change brush category
  | MediaTypeSelected WetMediaType
  | ColorChanged Color
  | ColorHSVChanged Int Int Int          -- ^ HSV color (h: 0-360, s: 0-100, v: 0-100)
  | BrushSizeChanged Number              -- ^ Change brush size (1-500)
  | BrushOpacityChanged Number           -- ^ Change brush opacity (0-1)
  -- Media settings
  | WetnessChanged Number                -- ^ Change wetness (0-100)
  | ViscosityChanged Number              -- ^ Change viscosity (0-100)
  | DilutionChanged Number               -- ^ Change dilution (0-100)
  | PigmentLoadChanged Number            -- ^ Change pigment load (0-100)
  -- Pointer events with full stylus data
  | PointerDown StylusInput              -- ^ Stylus/touch down with pressure/tilt
  | PointerMoved StylusInput             -- ^ Stylus/touch move with pressure/tilt
  | PointerUp                            -- ^ Stylus/touch lifted
  -- Legacy events (for compatibility, no pressure/tilt)
  | CanvasTouched Number Number          -- ^ x, y in canvas coords (legacy)
  | CanvasMoved Number Number            -- ^ x, y in canvas coords (legacy)
  | CanvasReleased
  | OrientationChanged DeviceOrientation -- ^ From device sensors
  | ToggleGravity
  | TogglePlaying
  | ClearCanvas
  | Undo
  | Redo
  | Tick Number                          -- ^ Delta time in ms
  | LayerSelected LayerId                -- ^ Select a layer
  | AddLayer                             -- ^ Add new layer
  | LayerVisibilityToggled LayerId       -- ^ Toggle layer visibility
  | DeleteLayer LayerId                  -- ^ Delete a layer
  | MoveLayerUp LayerId                  -- ^ Move layer up in stack
  | MoveLayerDown LayerId                -- ^ Move layer down in stack
  -- Easter egg events
  | KeyDown String                       -- ^ Key pressed (for Konami code)
  | KeyboardShortcut                     -- ^ Full keyboard event with modifiers
      { key :: String                    -- ^ Key (e.g., "z", "y", "ArrowUp")
      , ctrlKey :: Boolean               -- ^ Ctrl/Cmd pressed
      , shiftKey :: Boolean              -- ^ Shift pressed
      , altKey :: Boolean                -- ^ Alt pressed
      }
  | DeviceMotion                         -- ^ Device motion event (for shake detection)
      { accelerationX :: Number
      , accelerationY :: Number
      , accelerationZ :: Number
      , timestamp :: Number
      }
  -- Viewport gesture events
  | ViewportPan Number Number            -- ^ Pan by (dx, dy)
  | ViewportZoom Number                  -- ^ Zoom by scale factor
  | ViewportZoomAt Number Number Number  -- ^ Zoom at (x, y) by scale factor
  | ViewportRotate Number                -- ^ Rotate by angle (radians)
  | ViewportReset                        -- ^ Reset to initial viewport
  -- Two-finger gesture events (processed from touch events)
  | TwoFingerTouch                       -- ^ Two fingers touching
      { x1 :: Number, y1 :: Number       -- ^ First touch point
      , x2 :: Number, y2 :: Number       -- ^ Second touch point
      }
  | TwoFingerEnd                         -- ^ Two-finger gesture ended
  -- Export
  | ExportCanvas String                  -- ^ Export canvas (format: "png", "svg")

derive instance eqMsg :: Eq Msg

instance showMsg :: Show Msg where
  show (ToolSelected t) = "ToolSelected(" <> show t <> ")"
  show (BrushPresetSelected p) = "BrushPresetSelected(" <> p <> ")"
  show (BrushCategorySelected c) = "BrushCategorySelected(" <> show c <> ")"
  show (MediaTypeSelected m) = "MediaTypeSelected(" <> show m <> ")"
  show (ColorChanged _) = "ColorChanged"
  show (ColorHSVChanged h s v) = "ColorHSVChanged(" <> show h <> "," <> show s <> "," <> show v <> ")"
  show (BrushSizeChanged s) = "BrushSizeChanged(" <> show s <> ")"
  show (BrushOpacityChanged o) = "BrushOpacityChanged(" <> show o <> ")"
  show (WetnessChanged w) = "WetnessChanged(" <> show w <> ")"
  show (ViscosityChanged v) = "ViscosityChanged(" <> show v <> ")"
  show (DilutionChanged d) = "DilutionChanged(" <> show d <> ")"
  show (PigmentLoadChanged p) = "PigmentLoadChanged(" <> show p <> ")"
  show (PointerDown s) = "PointerDown(" <> show s.x <> "," <> show s.y <> " p=" <> show s.pressure <> " t=" <> s.pointerType <> ")"
  show (PointerMoved s) = "PointerMoved(" <> show s.x <> "," <> show s.y <> " p=" <> show s.pressure <> ")"
  show PointerUp = "PointerUp"
  show (CanvasTouched x y) = "CanvasTouched(" <> show x <> "," <> show y <> ")"
  show (CanvasMoved x y) = "CanvasMoved(" <> show x <> "," <> show y <> ")"
  show CanvasReleased = "CanvasReleased"
  show (OrientationChanged _) = "OrientationChanged"
  show ToggleGravity = "ToggleGravity"
  show TogglePlaying = "TogglePlaying"
  show ClearCanvas = "ClearCanvas"
  show Undo = "Undo"
  show Redo = "Redo"
  show (Tick dt) = "Tick(" <> show dt <> ")"
  show (LayerSelected lid) = "LayerSelected(" <> show lid <> ")"
  show AddLayer = "AddLayer"
  show (LayerVisibilityToggled lid) = "LayerVisibilityToggled(" <> show lid <> ")"
  show (DeleteLayer lid) = "DeleteLayer(" <> show lid <> ")"
  show (MoveLayerUp lid) = "MoveLayerUp(" <> show lid <> ")"
  show (MoveLayerDown lid) = "MoveLayerDown(" <> show lid <> ")"
  show (KeyDown key) = "KeyDown(" <> key <> ")"
  show (KeyboardShortcut k) = "KeyboardShortcut(" <> k.key <> " ctrl=" <> show k.ctrlKey <> " shift=" <> show k.shiftKey <> ")"
  show (DeviceMotion m) = "DeviceMotion(ax=" <> show m.accelerationX <> ",ay=" <> show m.accelerationY <> ")"
  show (ViewportPan dx dy) = "ViewportPan(" <> show dx <> "," <> show dy <> ")"
  show (ViewportZoom s) = "ViewportZoom(" <> show s <> ")"
  show (ViewportZoomAt x y s) = "ViewportZoomAt(" <> show x <> "," <> show y <> "," <> show s <> ")"
  show (ViewportRotate r) = "ViewportRotate(" <> show r <> ")"
  show ViewportReset = "ViewportReset"
  show (TwoFingerTouch t) = "TwoFingerTouch(" <> show t.x1 <> "," <> show t.y1 <> " / " <> show t.x2 <> "," <> show t.y2 <> ")"
  show TwoFingerEnd = "TwoFingerEnd"
  show (ExportCanvas fmt) = "ExportCanvas(" <> fmt <> ")"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // main view
-- ═════════════════════════════════════════════════════════════════════════════

-- | Main view function: State -> Element
-- |
-- | Pure function that renders the entire application.
-- | Includes confetti overlay for easter egg celebration.
-- |
-- | ## Accessibility
-- | - Main container has role="application" for complex widget
-- | - Regions are labeled with ARIA landmarks
-- | - Live region for status announcements
view :: ViewState -> Element Msg
view state =
  div_
    ([ class_ "canvas-app"
    , role "application"
    , ariaLabel "Canvas Paint Application"
    ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "width" "100vw"
        , Tuple "height" "100vh"
        , Tuple "overflow" "hidden"
        , Tuple "touch-action" "none"
        , Tuple "user-select" "none"
        ])
    [ renderToolbar state
    , div_
        ([ class_ "canvas-main"
        , role "main"
        , ariaLabel "Main canvas workspace"
        ] <> styles
            [ Tuple "flex" "1"
            , Tuple "display" "flex"
            , Tuple "position" "relative"
            , Tuple "overflow" "hidden"
            ])
        [ -- Left sidebar: Properties panel
          renderPropertiesPanel state
        -- Center: Canvas
        , renderCanvas state
        -- Right sidebar: Layer panel
        , renderLayerPanel state
        ]
    , renderStatusBar state
    -- Easter egg: Confetti overlay (renders on top when active)
    , renderConfettiOverlay state
    ]

-- | Render confetti overlay for Konami code celebration.
-- |
-- | When the Konami code is entered, confetti explodes from the center!
renderConfettiOverlay :: ViewState -> Element Msg
renderConfettiOverlay state =
  Easter.renderConfetti (State.easterEggState state)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                  // toolbar
-- ═════════════════════════════════════════════════════════════════════════════

-- | Toolbar with tools, brushes, media, and actions.
-- |
-- | ## Accessibility
-- | - Toolbar role for screen readers
-- | - Contains tool groups with group roles
renderToolbar :: ViewState -> Element Msg
renderToolbar state =
  div_
    ([ class_ "canvas-toolbar"
    , role "toolbar"
    , ariaLabel "Canvas tools"
    ] <> styles
        [ Tuple "display" "flex"
        , Tuple "gap" "8px"
        , Tuple "padding" "8px"
        , Tuple "background" "#1a1a2e"
        , Tuple "border-bottom" "1px solid #333"
        ])
    [ renderToolButtons state
    , renderBrushSelector state
    , renderMediaSelector state
    , renderActionButtons state
    ]

-- | Tool selection buttons.
-- |
-- | ## Accessibility
-- | - Group role for related buttons
-- | - Each tool button has ariaLabel
renderToolButtons :: ViewState -> Element Msg
renderToolButtons state =
  div_
    ([ class_ "tool-buttons"
    , role "group"
    , ariaLabel "Drawing tools"
    ] <> styles [ Tuple "display" "flex", Tuple "gap" "4px" ])
    [ toolButton BrushTool "Brush" "Paint brush tool" state
    , toolButton EraserTool "Eraser" "Eraser tool" state
    , toolButton PanTool "Pan" "Pan and move canvas" state
    , toolButton EyedropperTool "Pick" "Color picker tool" state
    ]

-- | Single tool button.
-- |
-- | ## Accessibility
-- | - ariaLabel describes the tool function
-- | - aria-pressed indicates if tool is active
toolButton :: Tool -> String -> String -> ViewState -> Element Msg
toolButton tool label description state =
  let isActive = State.currentTool state == tool
      activeClass = if isActive then "tool-btn active" else "tool-btn"
  in button_
    ([ class_ activeClass
    , onClick (ToolSelected tool)
    , ariaLabel description
    , E.attr "aria-pressed" (if isActive then "true" else "false")
    ] <> styles
        [ Tuple "padding" "8px 12px"
        , Tuple "border" "none"
        , Tuple "border-radius" "4px"
        , Tuple "background" (if isActive then "#4a4a6a" else "#2a2a4e")
        , Tuple "color" "#fff"
        , Tuple "cursor" "pointer"
        ])
    [ text label ]

-- | Action buttons (clear, undo, redo, play/pause).
-- |
-- | ## Accessibility
-- | - Group role for related actions
-- | - Each button has descriptive ariaLabel
renderActionButtons :: ViewState -> Element Msg
renderActionButtons state =
  div_
    ([ class_ "action-buttons"
    , role "group"
    , ariaLabel "Canvas actions"
    ] <> styles [ Tuple "display" "flex", Tuple "gap" "4px", Tuple "margin-left" "auto" ])
    [ actionButton Undo "Undo" "Undo last action (Ctrl+Z)" (State.canUndo state)
    , actionButton Redo "Redo" "Redo undone action (Ctrl+Shift+Z)" (State.canRedo state)
    , actionButton ClearCanvas "Clear" "Clear all paint from canvas" true
    , actionButton ToggleGravity "Gravity" "Toggle gravity effect" true
    , actionButton TogglePlaying 
        (if State.isPlaying state then "Pause" else "Play") 
        (if State.isPlaying state then "Pause physics simulation" else "Resume physics simulation")
        true
    ]

-- | Single action button.
-- |
-- | ## Accessibility
-- | - ariaLabel describes the action
-- | - aria-disabled for disabled buttons
actionButton :: Msg -> String -> String -> Boolean -> Element Msg
actionButton msg label description enabled =
  button_
    ([ class_ "action-btn"
    , onClick msg
    , ariaLabel description
    , E.attr "aria-disabled" (if enabled then "false" else "true")
    ] <> styles
        [ Tuple "padding" "8px 12px"
        , Tuple "border" "none"
        , Tuple "border-radius" "4px"
        , Tuple "background" (if enabled then "#2a2a4e" else "#1a1a2e")
        , Tuple "color" (if enabled then "#fff" else "#666")
        , Tuple "cursor" (if enabled then "pointer" else "not-allowed")
        ])
    [ text label ]

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // brush selector
-- ═════════════════════════════════════════════════════════════════════════════

-- | Brush preset selector with categories.
-- |
-- | Shows category tabs and presets organized by type.
-- | Highlights the currently selected preset.
renderBrushSelector :: ViewState -> Element Msg
renderBrushSelector state =
  let 
    selectedPreset = State.brushPresetName (State.brushConfig state)
    -- Show essentials by default (most used presets)
    presets = Presets.essentialsKit
  in div_
    ([ class_ "brush-selector" ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "4px"
        ])
    [ -- Category tabs
      div_
        ([ class_ "brush-categories" ] <> styles
            [ Tuple "display" "flex"
            , Tuple "gap" "2px"
            , Tuple "flex-wrap" "wrap"
            ])
        (map renderCategoryTab allBrushCategories)
    -- Preset buttons
    , div_
        ([ class_ "brush-presets" ] <> styles
            [ Tuple "display" "flex"
            , Tuple "gap" "2px"
            , Tuple "flex-wrap" "wrap"
            ])
        (map (brushPresetButton selectedPreset) presets)
    ]

-- | Render a category tab button.
renderCategoryTab :: BrushCategory -> Element Msg
renderCategoryTab category =
  button_
    ([ class_ "category-tab"
    , onClick (BrushCategorySelected category)
    , E.title ("Show " <> show category <> " presets")
    ] <> styles
        [ Tuple "padding" "3px 6px"
        , Tuple "border" "none"
        , Tuple "border-radius" "3px"
        , Tuple "background" "#2a2a4e"
        , Tuple "color" "#aaa"
        , Tuple "font-size" "9px"
        , Tuple "cursor" "pointer"
        ])
    [ text (categoryShortName category) ]

-- | Short name for category tabs.
categoryShortName :: BrushCategory -> String
categoryShortName CategoryEssentials = "Ess"
categoryShortName CategoryPencil = "Pen"
categoryShortName CategoryInk = "Ink"
categoryShortName CategoryWatercolor = "WC"
categoryShortName CategoryOil = "Oil"
categoryShortName CategoryDigital = "Dig"
categoryShortName CategoryExpressive = "Exp"

-- | Brush preset button from PresetMeta.
-- |
-- | Highlights if this preset is currently selected.
brushPresetButton :: String -> PresetMeta -> Element Msg
brushPresetButton selectedName preset =
  let 
    isSelected = preset.name == selectedName
    bgColor = if isSelected then "#5a5a8e" else "#3a3a5e"
    borderStyle = if isSelected then "2px solid #8080ff" else "2px solid transparent"
  in button_
    ([ class_ "brush-btn"
    , onClick (BrushPresetSelected preset.name)
    , E.title preset.description
    ] <> styles
        [ Tuple "padding" "4px 8px"
        , Tuple "border" borderStyle
        , Tuple "border-radius" "3px"
        , Tuple "background" bgColor
        , Tuple "color" (if isSelected then "#fff" else "#ccc")
        , Tuple "font-size" "11px"
        , Tuple "cursor" "pointer"
        ])
    [ text (shortPresetName preset.name) ]

-- | Shorten preset name for button display.
shortPresetName :: String -> String
shortPresetName name = name  -- Full name for now, could truncate if needed

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // media selector
-- ═════════════════════════════════════════════════════════════════════════════

-- | Media type selector (Watercolor, Oil, Acrylic, etc).
-- |
-- | Dynamically populated from allWetMediaTypes with full descriptions.
-- | Highlights the currently selected media type.
renderMediaSelector :: ViewState -> Element Msg
renderMediaSelector state =
  let 
    currentPreset = State.brushPreset (State.brushConfig state)
    currentMedia = presetToMedia currentPreset
  in div_
    ([ class_ "media-selector" ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "2px"
        ])
    [ span_ (styles [ Tuple "font-size" "10px", Tuple "color" "#888" ]) [ text "Media" ]
    , div_
        (styles [ Tuple "display" "flex", Tuple "gap" "2px", Tuple "flex-wrap" "wrap" ])
        (map (mediaButton currentMedia) allWetMediaTypes)
    ]

-- | Map PaintPreset to WetMediaType for UI comparison.
presetToMedia :: Paint.PaintPreset -> WetMediaType
presetToMedia Paint.Watercolor = Watercolor
presetToMedia Paint.OilPaint = OilPaint
presetToMedia Paint.Acrylic = Acrylic
presetToMedia Paint.Gouache = Gouache
presetToMedia Paint.Ink = Ink
presetToMedia Paint.Honey = Watercolor  -- Honey maps to WetIntoWet behavior

-- | Single media type button with tooltip description.
-- |
-- | Highlights if this media type is currently selected.
mediaButton :: WetMediaType -> WetMediaType -> Element Msg
mediaButton currentMedia mediaType =
  let 
    isSelected = mediaType == currentMedia
    bgColor = if isSelected then "#5a5a8e" else "#3a3a5e"
    borderStyle = if isSelected then "2px solid #8080ff" else "2px solid transparent"
  in button_
    ([ class_ "media-btn"
    , onClick (MediaTypeSelected mediaType)
    , E.title (wetMediaTypeDescription mediaType)
    ] <> styles
        [ Tuple "padding" "4px 8px"
        , Tuple "border" borderStyle
        , Tuple "border-radius" "3px"
        , Tuple "background" bgColor
        , Tuple "color" (if isSelected then "#fff" else "#ccc")
        , Tuple "font-size" "11px"
        , Tuple "cursor" "pointer"
        ])
    [ text (mediaLabel mediaType) ]

-- | Short label for media type.
-- |
-- | Complete pattern match for all WetMediaType variants.
mediaLabel :: WetMediaType -> String
mediaLabel Watercolor = "WC"
mediaLabel OilPaint = "Oil"
mediaLabel Acrylic = "Acr"
mediaLabel Gouache = "Gou"
mediaLabel Ink = "Ink"
mediaLabel WetIntoWet = "W/W"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // canvas surface
-- ═════════════════════════════════════════════════════════════════════════════

-- | The main canvas surface where paint lives.
-- |
-- | Note: The event handlers here use placeholder coordinates (0.0, 0.0) because
-- | Hydrogen's element event system dispatches fixed messages. Actual coordinate
-- | extraction happens in the DOM runtime via subscription event listeners in
-- | Main.purs (handleMouseDown, handleTouchStart, etc.) which have access to
-- | the raw browser events and extract clientX/clientY.
-- |
-- | ## Accessibility
-- | - role="img" for screen readers (canvas is a complex image)
-- | - ariaLabel describes the canvas content
-- | - tabIndex allows keyboard focus for shortcuts
renderCanvas :: ViewState -> Element Msg
renderCanvas state =
  let particleCount = Paint.particleCount (State.paintSystem state)
      canvasDescription = "Paint canvas with " <> show particleCount <> " particles. Press Tab to focus, then use Ctrl+Z to undo, Ctrl+Shift+Z to redo."
  in div_
    ([ class_ "canvas-surface"
    , id_ "paint-canvas"
    , role "img"
    , ariaLabel canvasDescription
    , tabIndex 0  -- Make canvas focusable for keyboard shortcuts
    -- Event handlers are placeholders - real input comes from subscriptions
    , onMouseDown (CanvasTouched 0.0 0.0)
    , onMouseMove (CanvasMoved 0.0 0.0)
    , onMouseUp CanvasReleased
    , onTouchStart (CanvasTouched 0.0 0.0)
    , onTouchMove (CanvasMoved 0.0 0.0)
    , onTouchEnd CanvasReleased
    ] <> styles
        [ Tuple "flex" "1"
        , Tuple "position" "relative"
        , Tuple "background" "#f5f5dc"  -- Paper color
        , Tuple "overflow" "hidden"
        , Tuple "cursor" "crosshair"
        , Tuple "min-width" "0"  -- Allow flex shrinking
        , Tuple "outline" "none"  -- Remove default focus outline (handled by :focus-visible CSS)
        ])
    [ renderPaintLayers state
    , renderGravityIndicator state
    , renderDebugOverlay state
    ]

-- | Render all paint layers.
-- |
-- | Uses a GPU-accelerated canvas element for particle rendering.
-- | The actual rendering is done by Canvas.Runtime.GPU in the animation loop.
renderPaintLayers :: ViewState -> Element Msg
renderPaintLayers state =
  div_
    ([ class_ "paint-layers" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" "0"
        , Tuple "left" "0"
        , Tuple "width" "100%"
        , Tuple "height" "100%"
        ])
    [ renderGPUCanvas state
    , renderParticlesSVGFallback state  -- SVG fallback (hidden when GPU active)
    ]

-- | GPU-accelerated canvas element for particle rendering.
-- |
-- | This canvas is rendered to by Canvas.Runtime.GPU using WebGL/WebGPU/Canvas2D.
-- | The id "paint-canvas" is used by GPU.initialize to get the rendering context.
renderGPUCanvas :: ViewState -> Element Msg
renderGPUCanvas _state =
  E.canvas_
    ([ id_ "paint-canvas"
    , class_ "gpu-canvas"
    ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" "0"
        , Tuple "left" "0"
        , Tuple "width" "100%"
        , Tuple "height" "100%"
        , Tuple "pointer-events" "none"
        ])

-- | Render SPH particles as SVG circles (fallback).
-- |
-- | This is kept as a fallback in case GPU initialization fails.
-- | It's hidden by default when GPU rendering is active.
renderParticles :: ViewState -> Element Msg
renderParticles state = renderParticlesSVGFallback state

-- | SVG fallback for particle rendering.
-- |
-- | Hidden by default (display: none) when GPU canvas is present.
-- | Useful for debugging or when GPU is unavailable.
renderParticlesSVGFallback :: ViewState -> Element Msg
renderParticlesSVGFallback state =
  let particles = Paint.allParticles (State.paintSystem state)
  in E.svg_
    ([ id_ "paint-svg-fallback"
    , class_ "svg-particles-fallback"
    ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" "0"
        , Tuple "left" "0"
        , Tuple "width" "100%"
        , Tuple "height" "100%"
        , Tuple "pointer-events" "none"
        , Tuple "display" "none"  -- Hidden when GPU is active
        ])
    (map renderSingleParticle particles)

-- | Render a single particle as SVG circle.
renderSingleParticle :: Paint.Particle -> Element Msg
renderSingleParticle p =
  let pos = Paint.particlePosition p
      radius = Paint.particleRadius p
      color = Paint.particleColorHex p
  in E.circle_
    [ E.attr "cx" (show pos.x)
    , E.attr "cy" (show pos.y)
    , E.attr "r" (show radius)
    , E.attr "fill" color
    , E.attr "opacity" "0.8"
    ]

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // gravity indicator
-- ═════════════════════════════════════════════════════════════════════════════

-- | Visual indicator showing current gravity direction.
-- |
-- | Rotates based on device tilt. Arrow points "down" in gravity space.
-- | Uses GravityVector from Hydrogen.Schema.Canvas.Physics for calculations.
-- | Tooltip shows gravity magnitude in g units.
renderGravityIndicator :: ViewState -> Element Msg
renderGravityIndicator state =
  let gravState = State.gravityState state
      gravVector :: GravityVector
      gravVector = Gravity.currentGravity gravState
      grav2d = gravity2D gravVector
      magnitude = gravityMagnitude gravVector
      -- Calculate rotation angle from gravity vector
      angle = gravityAngleFromVector { vx: grav2d.x, vy: grav2d.y }
      isActive = Gravity.isGravityActive gravState
      -- Tooltip showing gravity info
      tooltipText = "Gravity: " <> show magnitude <> "g (" <> 
                    show (gravityX gravVector) <> ", " <> 
                    show (gravityY gravVector) <> ")"
  in div_
    ([ class_ "gravity-indicator"
    , E.title tooltipText
    ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" "16px"
        , Tuple "right" "16px"
        , Tuple "width" "48px"
        , Tuple "height" "48px"
        , Tuple "border-radius" "50%"
        , Tuple "background" (if isActive then "rgba(100,150,255,0.3)" else "rgba(100,100,100,0.2)")
        , Tuple "border" (if isActive then "2px solid #6496ff" else "2px solid #666")
        , Tuple "display" "flex"
        , Tuple "align-items" "center"
        , Tuple "justify-content" "center"
        , Tuple "transform" ("rotate(" <> show angle <> "deg)")
        , Tuple "transition" "transform 0.1s ease-out"
        ])
    [ -- Arrow pointing down (will rotate with container)
      div_
        (styles
            [ Tuple "width" "0"
            , Tuple "height" "0"
            , Tuple "border-left" "8px solid transparent"
            , Tuple "border-right" "8px solid transparent"
            , Tuple "border-top" (if isActive then "16px solid #6496ff" else "16px solid #666")
            ])
        []
    ]

-- | Calculate angle from 2D gravity vector.
-- | Takes Vec2D with vx/vy fields.
gravityAngleFromVector :: { vx :: Number, vy :: Number } -> Number
gravityAngleFromVector g =
  -- atan2 gives radians, convert to degrees
  -- Negate because CSS rotation is clockwise
  negate (atan2Deg g.vx g.vy)

-- | atan2 returning degrees (using pure PureScript from Hydrogen.Math.Core).
atan2Deg :: Number -> Number -> Number
atan2Deg y x = (atan2 y x) * 180.0 / pi

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // debug overlay
-- ═════════════════════════════════════════════════════════════════════════════

-- | Debug overlay showing state information.
-- |
-- | Displays detailed gravity information using GravityVector accessors.
renderDebugOverlay :: ViewState -> Element Msg
renderDebugOverlay state =
  let gravState = State.gravityState state
      gravVector = Gravity.currentGravity gravState
      magnitude = gravityMagnitude gravVector
      gx = gravityX gravVector
      gy = gravityY gravVector
      gz = gravityZ gravVector
      particleCount = Paint.particleCount (State.paintSystem state)
      layerCt = State.layerCount state
      -- Detect if device is upside-down (gravity pushing paint onto glass)
      -- gz > 0 means gravity is pointing out of the screen (upside-down)
      isUpsideDown = gz > 0.3
      paintPressure = if isUpsideDown 
                        then "ONTO GLASS" 
                        else if gz < negate 0.3 
                          then "Into glass" 
                          else "Neutral"
  in div_
    ([ class_ "debug-overlay" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "bottom" "8px"
        , Tuple "left" "8px"
        , Tuple "padding" "8px"
        , Tuple "background" (if isUpsideDown then "rgba(233,69,96,0.8)" else "rgba(0,0,0,0.7)")
        , Tuple "color" (if isUpsideDown then "#fff" else "#0f0")
        , Tuple "font-family" "monospace"
        , Tuple "font-size" "11px"
        , Tuple "border-radius" "4px"
        , Tuple "pointer-events" "none"
        ])
    [ div_ [] [ text ("Particles: " <> show particleCount) ]
    , div_ [] [ text ("Layers: " <> show layerCt) ]
    , div_ [] [ text ("Gravity X: " <> show gx) ]
    , div_ [] [ text ("Gravity Y: " <> show gy) ]
    , div_ [] [ text ("Gravity Z: " <> show gz <> " [" <> paintPressure <> "]") ]
    , div_ [] [ text ("Gravity Mag: " <> show magnitude <> "g") ]
    , div_ [] [ text ("Playing: " <> show (State.isPlaying state)) ]
    , div_ [] [ text ("Tool: " <> show (State.currentTool state)) ]
    ]

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // status bar
-- ═════════════════════════════════════════════════════════════════════════════

-- | Status bar at bottom showing stats.
-- |
-- | The GPU backend indicator has id "gpu-backend" and is updated by the runtime.
-- |
-- | ## Accessibility
-- | - contentinfo landmark for footer
-- | - Live region for status updates
renderStatusBar :: ViewState -> Element Msg
renderStatusBar state =
  let particleCount = Paint.particleCount (State.paintSystem state)
  in div_
    ([ class_ "canvas-statusbar"
    , role "contentinfo"
    , ariaLabel "Canvas status"
    , ariaLive "polite"
    , ariaAtomic "false"
    ] <> styles
        [ Tuple "display" "flex"
        , Tuple "gap" "16px"
        , Tuple "padding" "4px 8px"
        , Tuple "background" "#1a1a2e"
        , Tuple "border-top" "1px solid #333"
        , Tuple "font-size" "11px"
        , Tuple "color" "#888"
        ])
    [ span_ [ ariaLabel ("Particle count: " <> show particleCount) ] 
        [ text ("Particles: " <> show particleCount) ]
    , span_ [ ariaLabel ("Layer count: " <> show (State.layerCount state)) ]
        [ text ("Layers: " <> show (State.layerCount state)) ]
    , span_ 
        ([ id_ "gpu-backend"
        , ariaLabel "GPU rendering backend"
        ] <> styles 
            [ Tuple "color" "#4a9eff"
            , Tuple "font-weight" "bold"
            ])
        [ text "GPU: Detecting..." ]  -- Updated by runtime
    , span_ [] [ text (if State.canUndo state then "Undo available" else "") ]
    ]

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // layer panel
-- ═════════════════════════════════════════════════════════════════════════════

-- | Layer panel showing all layers in the stack.
-- |
-- | Displays layers sorted by Z-index, with the active layer highlighted.
-- | Uses LayerId for selection and Layer type for display.
-- | Includes controls for visibility, reordering, and deletion.
-- |
-- | ## Accessibility
-- | - complementary landmark for sidebar
-- | - List role for layer stack
-- | - Individual layers are selectable with keyboard
renderLayerPanel :: ViewState -> Element Msg
renderLayerPanel state =
  let 
    stack = State.layerStack state
    layers = sortedLayers stack
    activeId = State.activeLayerId state
    layerCount = Array.length layers
  in div_
    ([ class_ "layer-panel"
    , role "complementary"
    , ariaLabel "Layer panel"
    ] <> styles
        [ Tuple "width" "180px"
        , Tuple "padding" "8px"
        , Tuple "background" "#1a1a2e"
        , Tuple "border-left" "1px solid #333"
        , Tuple "font-size" "11px"
        , Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "8px"
        ])
    [ -- Header with add button
      div_
        (styles 
            [ Tuple "display" "flex"
            , Tuple "justify-content" "space-between"
            , Tuple "align-items" "center"
            ])
        [ span_ (styles [ Tuple "color" "#888", Tuple "font-weight" "bold" ]) [ text "Layers" ]
        , button_
            ([ class_ "add-layer-btn"
            , onClick AddLayer
            , E.title "Add new layer"
            , ariaLabel "Add new layer"
            ] <> styles
                [ Tuple "padding" "4px 8px"
                , Tuple "border" "none"
                , Tuple "border-radius" "3px"
                , Tuple "background" "#3a3a5e"
                , Tuple "color" "#ccc"
                , Tuple "cursor" "pointer"
                , Tuple "font-size" "12px"
                ])
            [ text "+" ]
        ]
    -- Layer list
    , div_
        ([ class_ "layer-list"
        , role "list"
        , ariaLabel ("Layer stack with " <> show layerCount <> " layers")
        ] <> styles
            [ Tuple "display" "flex"
            , Tuple "flex-direction" "column"
            , Tuple "gap" "2px"
            , Tuple "flex" "1"
            , Tuple "overflow-y" "auto"
            ])
        (map (renderLayerItem activeId layerCount) layers)
    ]

-- | Render a single layer item in the panel.
-- |
-- | Shows layer name, visibility toggle, and reorder/delete controls.
-- | Active layer is highlighted with a different background.
renderLayerItem :: LayerId -> Int -> Layer -> Element Msg
renderLayerItem activeId totalLayers layer =
  let 
    lid = layerId layer
    isActive = lid == activeId
    isVisible = layerVisible layer
    isBackground = lid == backgroundLayerId  -- Background layer (protected)
    bgColor = if isActive then "#4a4a6a" else "#2a2a4e"
    textColor = if isVisible then "#fff" else "#666"
  in div_
    ([ class_ "layer-item" ] <> styles
        [ Tuple "display" "flex"
        , Tuple "align-items" "center"
        , Tuple "gap" "4px"
        , Tuple "padding" "4px 6px"
        , Tuple "border-radius" "3px"
        , Tuple "background" bgColor
        ])
    [ -- Visibility toggle button
      button_
        ([ class_ "visibility-btn"
        , onClick (LayerVisibilityToggled lid)
        , E.title (if isVisible then "Hide layer" else "Show layer")
        ] <> styles
            [ Tuple "width" "16px"
            , Tuple "height" "16px"
            , Tuple "border" "none"
            , Tuple "border-radius" "3px"
            , Tuple "background" (if isVisible then "#0a0" else "#333")
            , Tuple "cursor" "pointer"
            , Tuple "padding" "0"
            ])
        []
    -- Layer name (clickable to select)
    , button_
        ([ class_ "layer-name"
        , onClick (LayerSelected lid)
        , E.title (layerName layer)
        ] <> styles
            [ Tuple "flex" "1"
            , Tuple "border" "none"
            , Tuple "background" "transparent"
            , Tuple "color" textColor
            , Tuple "cursor" "pointer"
            , Tuple "text-align" "left"
            , Tuple "padding" "2px 4px"
            , Tuple "overflow" "hidden"
            , Tuple "text-overflow" "ellipsis"
            , Tuple "white-space" "nowrap"
            ])
        [ text (layerName layer) ]
    -- Reorder controls (only if multiple layers and not background)
    , if totalLayers > 1 && not isBackground
        then div_
            (styles [ Tuple "display" "flex", Tuple "gap" "2px" ])
            [ -- Move up button
              button_
                ([ class_ "move-up-btn"
                , onClick (MoveLayerUp lid)
                , E.title "Move layer up"
                ] <> styles
                    [ Tuple "width" "16px"
                    , Tuple "height" "16px"
                    , Tuple "border" "none"
                    , Tuple "border-radius" "2px"
                    , Tuple "background" "#3a3a5e"
                    , Tuple "color" "#ccc"
                    , Tuple "cursor" "pointer"
                    , Tuple "font-size" "10px"
                    , Tuple "padding" "0"
                    ])
                [ text "^" ]
            -- Move down button
            , button_
                ([ class_ "move-down-btn"
                , onClick (MoveLayerDown lid)
                , E.title "Move layer down"
                ] <> styles
                    [ Tuple "width" "16px"
                    , Tuple "height" "16px"
                    , Tuple "border" "none"
                    , Tuple "border-radius" "2px"
                    , Tuple "background" "#3a3a5e"
                    , Tuple "color" "#ccc"
                    , Tuple "cursor" "pointer"
                    , Tuple "font-size" "10px"
                    , Tuple "padding" "0"
                    ])
                [ text "v" ]
            -- Delete button
            , button_
                ([ class_ "delete-layer-btn"
                , onClick (DeleteLayer lid)
                , E.title "Delete layer"
                ] <> styles
                    [ Tuple "width" "16px"
                    , Tuple "height" "16px"
                    , Tuple "border" "none"
                    , Tuple "border-radius" "2px"
                    , Tuple "background" "#5a2a2e"
                    , Tuple "color" "#f88"
                    , Tuple "cursor" "pointer"
                    , Tuple "font-size" "10px"
                    , Tuple "padding" "0"
                    ])
                [ text "x" ]
            ]
        else text ""
    ]

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // properties panel
-- ═════════════════════════════════════════════════════════════════════════════

-- | Properties panel showing brush settings.
-- |
-- | Displays and allows editing of:
-- | - Brush size (1-500 pixels)
-- | - Brush opacity (0-100%)
-- | - Media settings (wetness, viscosity, dilution, pigment load)
-- | - Color picker
-- | - Export button
-- |
-- | ## Accessibility
-- | - complementary landmark for sidebar
-- | - Controls have descriptive labels
renderPropertiesPanel :: ViewState -> Element Msg
renderPropertiesPanel state =
  let 
    config = State.brushConfig state
    sizeValue = config.size
    opacityValue = config.opacity
    currentColor = config.color
    -- Media settings
    wetnessValue = config.wetness
    viscosityValue = config.viscosity
    dilutionValue = config.dilution
    pigmentValue = config.pigmentLoad
  in div_
    ([ class_ "properties-panel"
    , role "complementary"
    , ariaLabel "Brush properties panel"
    ] <> styles
        [ Tuple "width" "220px"
        , Tuple "padding" "8px"
        , Tuple "background" "#1a1a2e"
        , Tuple "border-right" "1px solid #333"
        , Tuple "font-size" "11px"
        , Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "10px"
        , Tuple "overflow-y" "auto"
        ])
    [ -- Header
      span_ (styles [ Tuple "color" "#888", Tuple "font-weight" "bold" ]) [ text "Brush" ]
    
    -- Brush Size
    , renderSliderControl "Size" "Brush size in pixels" sizeValue 1.0 500.0 BrushSizeChanged
    
    -- Brush Opacity  
    , renderSliderControl "Opacity" "Brush opacity percentage" (opacityValue * 100.0) 0.0 100.0 
        (\v -> BrushOpacityChanged (v / 100.0))
    
    -- Color Picker
    , renderColorPicker currentColor
    
    -- Media Settings Header
    , span_ (styles [ Tuple "color" "#888", Tuple "font-weight" "bold", Tuple "margin-top" "8px" ]) [ text "Media" ]
    
    -- Wetness: How much water/medium is in the paint
    , renderSliderControl "Wetness" "Paint wetness (more = flows more)" wetnessValue 0.0 100.0 WetnessChanged
    
    -- Viscosity: How thick the paint is
    , renderSliderControl "Viscosity" "Paint thickness (more = resists flow)" viscosityValue 0.0 100.0 ViscosityChanged
    
    -- Dilution: How much it's thinned with water/medium
    , renderSliderControl "Dilution" "Water/medium ratio" dilutionValue 0.0 100.0 DilutionChanged
    
    -- Pigment Load: How saturated the color is
    , renderSliderControl "Pigment" "Pigment concentration" pigmentValue 0.0 100.0 PigmentLoadChanged
    
    -- Export buttons
    , div_
        ([ role "group"
        , ariaLabel "Export options"
        ] <> styles [ Tuple "margin-top" "auto" ])
        [ span_ (styles [ Tuple "color" "#888", Tuple "display" "block", Tuple "margin-bottom" "4px" ]) 
            [ text "Export" ]
        , div_
            (styles [ Tuple "display" "flex", Tuple "gap" "4px" ])
            [ button_
                ([ class_ "export-btn"
                , onClick (ExportCanvas "png")
                , E.title "Export as PNG"
                , ariaLabel "Export canvas as PNG image"
                ] <> styles
                    [ Tuple "flex" "1"
                    , Tuple "padding" "8px"
                    , Tuple "border" "none"
                    , Tuple "border-radius" "4px"
                    , Tuple "background" "#2a4a6e"
                    , Tuple "color" "#fff"
                    , Tuple "cursor" "pointer"
                    ])
                [ text "PNG" ]
            , button_
                ([ class_ "export-btn"
                , onClick (ExportCanvas "svg")
                , E.title "Export as SVG"
                , ariaLabel "Export canvas as SVG vector image"
                ] <> styles
                    [ Tuple "flex" "1"
                    , Tuple "padding" "8px"
                    , Tuple "border" "none"
                    , Tuple "border-radius" "4px"
                    , Tuple "background" "#2a6a4e"
                    , Tuple "color" "#fff"
                    , Tuple "cursor" "pointer"
                    ])
                [ text "SVG" ]
            ]
        ]
    ]

-- | Render a slider control with label and value display.
-- |
-- | Emits messages when slider changes (via onInput).
-- | Shows current value next to label.
-- |
-- | ## Accessibility
-- | - slider role for the control group
-- | - Buttons have descriptive labels
renderSliderControl :: String -> String -> Number -> Number -> Number -> (Number -> Msg) -> Element Msg
renderSliderControl label description currentVal minVal maxVal toMsg =
  div_
    ([ class_ "slider-control"
    , role "group"
    , ariaLabel description
    ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "4px"
        ])
    [ -- Label and value
      div_
        (styles [ Tuple "display" "flex", Tuple "justify-content" "space-between" ])
        [ span_ (styles [ Tuple "color" "#aaa" ]) [ text label ]
        , span_ (styles [ Tuple "color" "#fff" ]) [ text (formatNumber currentVal) ]
        ]
    -- Slider buttons (since HTML range input requires FFI for proper onChange)
    , div_
        (styles [ Tuple "display" "flex", Tuple "gap" "4px", Tuple "align-items" "center" ])
        [ -- Decrease button
          button_
            ([ class_ "slider-btn"
            , onClick (toMsg (clampNumber (currentVal - stepForRange minVal maxVal) minVal maxVal))
            , ariaLabel ("Decrease " <> label)
            ] <> styles
                [ Tuple "width" "24px"
                , Tuple "height" "24px"
                , Tuple "border" "none"
                , Tuple "border-radius" "4px"
                , Tuple "background" "#3a3a5e"
                , Tuple "color" "#fff"
                , Tuple "cursor" "pointer"
                ])
            [ text "-" ]
        -- Progress bar showing current value
        , div_
            ([ role "progressbar"
            , E.attr "aria-valuenow" (show currentVal)
            , E.attr "aria-valuemin" (show minVal)
            , E.attr "aria-valuemax" (show maxVal)
            , ariaLabel (label <> " value: " <> formatNumber currentVal)
            ] <> styles
                [ Tuple "flex" "1"
                , Tuple "height" "8px"
                , Tuple "background" "#2a2a4e"
                , Tuple "border-radius" "4px"
                , Tuple "overflow" "hidden"
                ])
            [ div_
                (styles
                    [ Tuple "width" (show (percentValue currentVal minVal maxVal) <> "%")
                    , Tuple "height" "100%"
                    , Tuple "background" "#6a6aaa"
                    ])
                []
            ]
        -- Increase button
        , button_
            ([ class_ "slider-btn"
            , onClick (toMsg (clampNumber (currentVal + stepForRange minVal maxVal) minVal maxVal))
            , ariaLabel ("Increase " <> label)
            ] <> styles
                [ Tuple "width" "24px"
                , Tuple "height" "24px"
                , Tuple "border" "none"
                , Tuple "border-radius" "4px"
                , Tuple "background" "#3a3a5e"
                , Tuple "color" "#fff"
                , Tuple "cursor" "pointer"
                ])
            [ text "+" ]
        ]
    ]

-- | Calculate step size based on range.
stepForRange :: Number -> Number -> Number
stepForRange minVal maxVal =
  let range = maxVal - minVal
  in if range > 100.0 then 10.0
     else if range > 10.0 then 1.0
     else 0.1

-- | Calculate percentage for progress bar.
percentValue :: Number -> Number -> Number -> Number
percentValue current minVal maxVal =
  ((current - minVal) / (maxVal - minVal)) * 100.0

-- | Clamp a number to a range.
clampNumber :: Number -> Number -> Number -> Number
clampNumber val minVal maxVal =
  if val < minVal then minVal
  else if val > maxVal then maxVal
  else val

-- | Format a number for display (remove excessive decimals).
formatNumber :: Number -> String
formatNumber n =
  let s = show n
  in truncateDecimals s 1

-- | Truncate string to max decimal places.
-- |
-- | TODO: Implement proper decimal truncation.
-- | For now, just returns the original string.
truncateDecimals :: String -> Int -> String
truncateDecimals s _maxDecimals =
  -- Simple approach: just show the number
  -- A proper implementation would parse and format
  s

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // color picker
-- ═════════════════════════════════════════════════════════════════════════════

-- | Color picker showing preset colors, HSV sliders, and current color.
-- |
-- | Features:
-- | - Current color preview
-- | - HSV sliders for precise control (Hue, Saturation, Value)
-- | - Grid of preset colors for quick selection
-- |
-- | ## Accessibility
-- | - Group role for color controls
-- | - Color preview has ariaLabel
-- | - Each preset has color description
renderColorPicker :: Color -> Element Msg
renderColorPicker currentColor =
  let
    -- Convert current color to approximate HSV for slider values
    -- (This is visual approximation - actual HSV is in state)
    hueApprox = colorToHueApprox currentColor
    satApprox = colorToSatApprox currentColor
    valApprox = colorToValApprox currentColor
  in div_
    ([ class_ "color-picker"
    , role "group"
    , ariaLabel "Color picker"
    ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "6px"
        ])
    [ -- Label
      span_ (styles [ Tuple "color" "#888" ]) [ text "Color" ]
    
    -- Current color preview
    , div_
        ([ class_ "current-color"
        , role "img"
        , ariaLabel ("Current color: " <> colorToHex currentColor)
        ] <> styles
            [ Tuple "width" "100%"
            , Tuple "height" "24px"
            , Tuple "border-radius" "4px"
            , Tuple "border" "2px solid #444"
            , Tuple "background" (colorToHex currentColor)
            ])
        []
    
    -- HSV Sliders
    , renderHSVSliders hueApprox satApprox valApprox
    
    -- Color presets grid
    , div_
        ([ class_ "color-presets"
        , role "listbox"
        , ariaLabel "Color presets"
        ] <> styles
            [ Tuple "display" "grid"
            , Tuple "grid-template-columns" "repeat(5, 1fr)"
            , Tuple "gap" "3px"
            ])
        (map (renderColorPresetWithSelection currentColor) colorPresets)
    ]

-- | Render HSV sliders for precise color control.
renderHSVSliders :: Int -> Int -> Int -> Element Msg
renderHSVSliders hue sat val =
  div_
    ([ class_ "hsv-sliders" ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "4px"
        ])
    [ -- Hue slider (0-360)
      renderHSVSlider "H" hue 0 360 (\h -> ColorHSVChanged h sat val)
    -- Saturation slider (0-100)
    , renderHSVSlider "S" sat 0 100 (\s -> ColorHSVChanged hue s val)
    -- Value/Brightness slider (0-100)
    , renderHSVSlider "V" val 0 100 (\v -> ColorHSVChanged hue sat v)
    ]

-- | Render a single HSV slider with +/- buttons.
renderHSVSlider :: String -> Int -> Int -> Int -> (Int -> Msg) -> Element Msg
renderHSVSlider label currentVal minVal maxVal toMsg =
  let 
    step = if maxVal > 100 then 15 else 5
  in div_
    (styles [ Tuple "display" "flex", Tuple "gap" "3px", Tuple "align-items" "center" ])
    [ -- Label
      span_ (styles [ Tuple "width" "14px", Tuple "color" "#888", Tuple "font-size" "10px" ]) 
        [ text label ]
    -- Decrease button
    , button_
        ([ onClick (toMsg (clampIntVal (currentVal - step) minVal maxVal))
        ] <> styles
            [ Tuple "width" "18px"
            , Tuple "height" "18px"
            , Tuple "border" "none"
            , Tuple "border-radius" "3px"
            , Tuple "background" "#3a3a5e"
            , Tuple "color" "#fff"
            , Tuple "cursor" "pointer"
            , Tuple "font-size" "10px"
            , Tuple "padding" "0"
            ])
        [ text "-" ]
    -- Value display
    , span_ (styles [ Tuple "width" "28px", Tuple "text-align" "center", Tuple "color" "#fff", Tuple "font-size" "10px" ]) 
        [ text (show currentVal) ]
    -- Increase button
    , button_
        ([ onClick (toMsg (clampIntVal (currentVal + step) minVal maxVal))
        ] <> styles
            [ Tuple "width" "18px"
            , Tuple "height" "18px"
            , Tuple "border" "none"
            , Tuple "border-radius" "3px"
            , Tuple "background" "#3a3a5e"
            , Tuple "color" "#fff"
            , Tuple "cursor" "pointer"
            , Tuple "font-size" "10px"
            , Tuple "padding" "0"
            ])
        [ text "+" ]
    ]

-- | Clamp Int to range.
clampIntVal :: Int -> Int -> Int -> Int
clampIntVal val minVal maxVal =
  if val < minVal then minVal
  else if val > maxVal then maxVal
  else val

-- | Approximate hue from RGB (0-360).
colorToHueApprox :: Color -> Int
colorToHueApprox c =
  let
    r = c.r
    g = c.g  
    b = c.b
    cmax = max r (max g b)
    cmin = min r (min g b)
    delta = cmax - cmin
    h = if delta < 0.001 then 0.0
        else if cmax == r then 60.0 * modNumber ((g - b) / delta) 6.0
        else if cmax == g then 60.0 * ((b - r) / delta + 2.0)
        else 60.0 * ((r - g) / delta + 4.0)
    hNorm = if h < 0.0 then h + 360.0 else h
  in IntConv.floor hNorm

-- | Approximate saturation from RGB (0-100).
colorToSatApprox :: Color -> Int
colorToSatApprox c =
  let
    cmax = max c.r (max c.g c.b)
    cmin = min c.r (min c.g c.b)
    delta = cmax - cmin
    s = if cmax < 0.001 then 0.0 else delta / cmax
  in IntConv.floor (s * 100.0)

-- | Approximate value from RGB (0-100).
colorToValApprox :: Color -> Int
colorToValApprox c =
  let cmax = max c.r (max c.g c.b)
  in IntConv.floor (cmax * 100.0)

-- | Number modulo for floats.
modNumber :: Number -> Number -> Number
modNumber a b = 
  let d = a / b
      floored = IntConv.floor d
  in a - (IntConv.toNumber floored * b)

-- | Render a single color preset button.
-- |
-- | ## Accessibility
-- | - option role for listbox
-- | - ariaLabel with color hex value
renderColorPreset :: Color -> Element Msg
renderColorPreset color =
  let hexColor = colorToHex color
  in button_
    ([ class_ "color-preset"
    , onClick (ColorChanged color)
    , E.title hexColor
    , role "option"
    , ariaLabel ("Select color " <> hexColor)
    ] <> styles
        [ Tuple "width" "100%"
        , Tuple "aspect-ratio" "1"
        , Tuple "border" "none"
        , Tuple "border-radius" "4px"
        , Tuple "background" hexColor
        , Tuple "cursor" "pointer"
        , Tuple "padding" "0"
        ])
    []

-- | Render a color preset with selection highlighting.
-- |
-- | Highlights if this color matches the current color.
renderColorPresetWithSelection :: Color -> Color -> Element Msg
renderColorPresetWithSelection currentColor presetColor =
  let 
    hexColor = colorToHex presetColor
    isSelected = colorsMatch currentColor presetColor
    borderStyle = if isSelected then "2px solid #fff" else "2px solid transparent"
  in button_
    ([ class_ "color-preset"
    , onClick (ColorChanged presetColor)
    , E.title hexColor
    , role "option"
    , ariaLabel ("Select color " <> hexColor)
    ] <> styles
        [ Tuple "width" "100%"
        , Tuple "aspect-ratio" "1"
        , Tuple "border" borderStyle
        , Tuple "border-radius" "4px"
        , Tuple "background" hexColor
        , Tuple "cursor" "pointer"
        , Tuple "padding" "0"
        , Tuple "box-sizing" "border-box"
        ])
    []

-- | Check if two colors approximately match.
colorsMatch :: Color -> Color -> Boolean
colorsMatch c1 c2 =
  let 
    threshold = 0.05
    rMatch = absNum (c1.r - c2.r) < threshold
    gMatch = absNum (c1.g - c2.g) < threshold
    bMatch = absNum (c1.b - c2.b) < threshold
  in rMatch && gMatch && bMatch

-- | Absolute value for Number.
absNum :: Number -> Number
absNum n = if n < 0.0 then negate n else n

-- | Convert Color record to hex string.
-- |
-- | Color has r, g, b, a as 0-1 values.
colorToHex :: Color -> String
colorToHex c =
  let
    toHexByte :: Number -> String
    toHexByte n = 
      let i = clampInt (n * 255.0) 0 255
      in intToHex i
  in "#" <> toHexByte c.r <> toHexByte c.g <> toHexByte c.b

-- | Convert a 0-255 int to 2-digit hex.
intToHex :: Int -> String
intToHex n =
  let 
    hexChars = "0123456789abcdef"
    high = n / 16
    low = n - (high * 16)
  in charAtIndex high hexChars <> charAtIndex low hexChars

-- | Get character at index as a single-character string.
charAtIndex :: Int -> String -> String
charAtIndex idx str =
  case Str.charAt idx str of
    Nothing -> "0"
    Just c -> Str.singleton c

-- | Clamp and convert Number to Int.
clampInt :: Number -> Int -> Int -> Int
clampInt n minVal maxVal =
  let i = IntConv.floor n
  in if i < minVal then minVal
     else if i > maxVal then maxVal
     else i

-- | Preset colors for quick selection.
-- |
-- | A palette of commonly used colors for painting.
colorPresets :: Array Color
colorPresets =
  [ -- Row 1: Blacks to whites
    { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }      -- Black
  , { r: 0.25, g: 0.25, b: 0.25, a: 1.0 }   -- Dark gray
  , { r: 0.5, g: 0.5, b: 0.5, a: 1.0 }      -- Gray
  , { r: 0.75, g: 0.75, b: 0.75, a: 1.0 }   -- Light gray
  , { r: 1.0, g: 1.0, b: 1.0, a: 1.0 }      -- White
  
  -- Row 2: Primary and secondary
  , { r: 1.0, g: 0.0, b: 0.0, a: 1.0 }      -- Red
  , { r: 1.0, g: 0.5, b: 0.0, a: 1.0 }      -- Orange
  , { r: 1.0, g: 1.0, b: 0.0, a: 1.0 }      -- Yellow
  , { r: 0.0, g: 1.0, b: 0.0, a: 1.0 }      -- Green
  , { r: 0.0, g: 0.0, b: 1.0, a: 1.0 }      -- Blue
  
  -- Row 3: More colors
  , { r: 0.5, g: 0.0, b: 0.5, a: 1.0 }      -- Purple
  , { r: 1.0, g: 0.0, b: 1.0, a: 1.0 }      -- Magenta
  , { r: 0.0, g: 1.0, b: 1.0, a: 1.0 }      -- Cyan
  , { r: 0.6, g: 0.4, b: 0.2, a: 1.0 }      -- Brown
  , { r: 1.0, g: 0.75, b: 0.8, a: 1.0 }     -- Pink
  ]

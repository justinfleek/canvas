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
  
  -- * Msg Type
  , Msg
      ( ToolSelected
      , BrushPresetSelected
      , MediaTypeSelected
      , ColorChanged
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
  , map
  , negate
  , (==)
  )

import Data.Array (length) as Array
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
  )

-- Canvas State
import Canvas.State as State
import Canvas.State (AppState)
import Canvas.Types
  ( Tool(BrushTool, EraserTool, PanTool, EyedropperTool)
  , Color
  , LayerId
  )
import Canvas.Paint.Particle as Paint
import Canvas.Physics.Gravity as Gravity
import Canvas.Layer.Types (Layer, sortedLayers, layerId, layerName, layerVisible)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // msg type
-- ═════════════════════════════════════════════════════════════════════════════

-- | Messages that the view can emit.
-- |
-- | These are handled by the update function in Main.
data Msg
  = ToolSelected Tool
  | BrushPresetSelected String           -- ^ Preset name
  | MediaTypeSelected WetMediaType
  | ColorChanged Color
  | CanvasTouched Number Number          -- ^ x, y in canvas coords
  | CanvasMoved Number Number            -- ^ x, y in canvas coords
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

derive instance eqMsg :: Eq Msg

instance showMsg :: Show Msg where
  show (ToolSelected t) = "ToolSelected(" <> show t <> ")"
  show (BrushPresetSelected p) = "BrushPresetSelected(" <> p <> ")"
  show (MediaTypeSelected m) = "MediaTypeSelected(" <> show m <> ")"
  show (ColorChanged _) = "ColorChanged"
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

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // main view
-- ═════════════════════════════════════════════════════════════════════════════

-- | Main view function: State -> Element
-- |
-- | Pure function that renders the entire application.
view :: AppState -> Element Msg
view state =
  div_
    ([ class_ "canvas-app" ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "width" "100vw"
        , Tuple "height" "100vh"
        , Tuple "overflow" "hidden"
        , Tuple "touch-action" "none"
        , Tuple "user-select" "none"
        ])
    [ renderToolbar state
    , renderCanvas state
    , renderStatusBar state
    ]

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                  // toolbar
-- ═════════════════════════════════════════════════════════════════════════════

-- | Toolbar with tools, brushes, media, and actions.
renderToolbar :: AppState -> Element Msg
renderToolbar state =
  div_
    ([ class_ "canvas-toolbar" ] <> styles
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
renderToolButtons :: AppState -> Element Msg
renderToolButtons state =
  div_
    ([ class_ "tool-buttons" ] <> styles [ Tuple "display" "flex", Tuple "gap" "4px" ])
    [ toolButton BrushTool "Brush" state
    , toolButton EraserTool "Eraser" state
    , toolButton PanTool "Pan" state
    , toolButton EyedropperTool "Pick" state
    ]

-- | Single tool button.
toolButton :: Tool -> String -> AppState -> Element Msg
toolButton tool label state =
  let isActive = State.currentTool state == tool
      activeClass = if isActive then "tool-btn active" else "tool-btn"
  in button_
    ([ class_ activeClass
    , onClick (ToolSelected tool)
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
renderActionButtons :: AppState -> Element Msg
renderActionButtons state =
  div_
    ([ class_ "action-buttons" ] <> styles [ Tuple "display" "flex", Tuple "gap" "4px", Tuple "margin-left" "auto" ])
    [ actionButton Undo "Undo" (State.canUndo state)
    , actionButton Redo "Redo" (State.canRedo state)
    , actionButton ClearCanvas "Clear" true
    , actionButton ToggleGravity "Gravity" true
    , actionButton TogglePlaying (if State.isPlaying state then "Pause" else "Play") true
    ]

-- | Single action button.
actionButton :: Msg -> String -> Boolean -> Element Msg
actionButton msg label enabled =
  button_
    ([ class_ "action-btn"
    , onClick msg
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

-- | Brush preset selector.
-- |
-- | Uses essentialsKit from Presets library for a curated set of brushes.
-- | Each button shows the preset name and description on hover.
renderBrushSelector :: AppState -> Element Msg
renderBrushSelector _state =
  div_
    ([ class_ "brush-selector" ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "2px"
        ])
    [ span_ (styles [ Tuple "font-size" "10px", Tuple "color" "#888" ]) 
        [ text ("Brush (" <> show (Array.length Presets.essentialsKit) <> ")") ]
    , div_
        (styles [ Tuple "display" "flex", Tuple "gap" "2px", Tuple "flex-wrap" "wrap" ])
        (map brushPresetButton Presets.essentialsKit)
    ]

-- | Brush preset button from PresetMeta.
-- |
-- | Uses preset name for display and description for tooltip.
brushPresetButton :: PresetMeta -> Element Msg
brushPresetButton preset =
  button_
    ([ class_ "brush-btn"
    , onClick (BrushPresetSelected preset.name)
    , E.title preset.description
    ] <> styles
        [ Tuple "padding" "4px 8px"
        , Tuple "border" "none"
        , Tuple "border-radius" "3px"
        , Tuple "background" "#3a3a5e"
        , Tuple "color" "#ccc"
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
renderMediaSelector :: AppState -> Element Msg
renderMediaSelector _state =
  div_
    ([ class_ "media-selector" ] <> styles
        [ Tuple "display" "flex"
        , Tuple "flex-direction" "column"
        , Tuple "gap" "2px"
        ])
    [ span_ (styles [ Tuple "font-size" "10px", Tuple "color" "#888" ]) [ text "Media" ]
    , div_
        (styles [ Tuple "display" "flex", Tuple "gap" "2px", Tuple "flex-wrap" "wrap" ])
        (map mediaButton allWetMediaTypes)
    ]

-- | Single media type button with tooltip description.
-- |
-- | Uses wetMediaTypeDescription to show full description on hover.
mediaButton :: WetMediaType -> Element Msg
mediaButton mediaType =
  button_
    ([ class_ "media-btn"
    , onClick (MediaTypeSelected mediaType)
    , E.title (wetMediaTypeDescription mediaType)
    ] <> styles
        [ Tuple "padding" "4px 8px"
        , Tuple "border" "none"
        , Tuple "border-radius" "3px"
        , Tuple "background" "#3a3a5e"
        , Tuple "color" "#ccc"
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
renderCanvas :: AppState -> Element Msg
renderCanvas state =
  div_
    ([ class_ "canvas-surface"
    , id_ "paint-canvas"
    , onMouseDown (CanvasTouched 0.0 0.0)  -- TODO: extract coords via event decoder
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
        ])
    [ renderPaintLayers state
    , renderGravityIndicator state
    , renderDebugOverlay state
    ]

-- | Render all paint layers.
renderPaintLayers :: AppState -> Element Msg
renderPaintLayers state =
  div_
    ([ class_ "paint-layers" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" "0"
        , Tuple "left" "0"
        , Tuple "width" "100%"
        , Tuple "height" "100%"
        ])
    [ renderParticles state ]

-- | Render SPH particles as SVG circles.
renderParticles :: AppState -> Element Msg
renderParticles state =
  let particles = Paint.allParticles (State.paintSystem state)
  in E.svg_
    (styles
        [ Tuple "position" "absolute"
        , Tuple "top" "0"
        , Tuple "left" "0"
        , Tuple "width" "100%"
        , Tuple "height" "100%"
        , Tuple "pointer-events" "none"
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
renderGravityIndicator :: AppState -> Element Msg
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
renderDebugOverlay :: AppState -> Element Msg
renderDebugOverlay state =
  let gravState = State.gravityState state
      gravVector = Gravity.currentGravity gravState
      magnitude = gravityMagnitude gravVector
      gx = gravityX gravVector
      gy = gravityY gravVector
      particleCount = Paint.particleCount (State.paintSystem state)
      layerCt = State.layerCount state
  in div_
    ([ class_ "debug-overlay" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "bottom" "8px"
        , Tuple "left" "8px"
        , Tuple "padding" "8px"
        , Tuple "background" "rgba(0,0,0,0.7)"
        , Tuple "color" "#0f0"
        , Tuple "font-family" "monospace"
        , Tuple "font-size" "11px"
        , Tuple "border-radius" "4px"
        , Tuple "pointer-events" "none"
        ])
    [ div_ [] [ text ("Particles: " <> show particleCount) ]
    , div_ [] [ text ("Layers: " <> show layerCt) ]
    , div_ [] [ text ("Gravity X: " <> show gx) ]
    , div_ [] [ text ("Gravity Y: " <> show gy) ]
    , div_ [] [ text ("Gravity Mag: " <> show magnitude <> "g") ]
    , div_ [] [ text ("Playing: " <> show (State.isPlaying state)) ]
    , div_ [] [ text ("Tool: " <> show (State.currentTool state)) ]
    ]

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // status bar
-- ═════════════════════════════════════════════════════════════════════════════

-- | Status bar at bottom showing stats.
renderStatusBar :: AppState -> Element Msg
renderStatusBar state =
  let particleCount = Paint.particleCount (State.paintSystem state)
  in div_
    ([ class_ "canvas-statusbar" ] <> styles
        [ Tuple "display" "flex"
        , Tuple "gap" "16px"
        , Tuple "padding" "4px 8px"
        , Tuple "background" "#1a1a2e"
        , Tuple "border-top" "1px solid #333"
        , Tuple "font-size" "11px"
        , Tuple "color" "#888"
        ])
    [ span_ [] [ text ("Particles: " <> show particleCount) ]
    , span_ [] [ text ("Layers: " <> show (State.layerCount state)) ]
    , span_ [] [ text (if State.canUndo state then "Undo available" else "") ]
    ]

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // layer panel
-- ═════════════════════════════════════════════════════════════════════════════

-- | Layer panel showing all layers in the stack.
-- |
-- | Displays layers sorted by Z-index, with the active layer highlighted.
-- | Uses LayerId for selection and Layer type for display.
renderLayerPanel :: AppState -> Element Msg
renderLayerPanel state =
  let 
    stack = State.layerStack state
    layers = sortedLayers stack
    activeId = State.activeLayerId state
  in div_
    ([ class_ "layer-panel" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" "60px"
        , Tuple "right" "8px"
        , Tuple "width" "150px"
        , Tuple "padding" "8px"
        , Tuple "background" "rgba(26,26,46,0.95)"
        , Tuple "border" "1px solid #333"
        , Tuple "border-radius" "4px"
        , Tuple "font-size" "11px"
        ])
    [ div_
        (styles [ Tuple "display" "flex", Tuple "justify-content" "space-between", Tuple "margin-bottom" "8px" ])
        [ span_ (styles [ Tuple "color" "#888" ]) [ text "Layers" ]
        , button_
            ([ class_ "add-layer-btn"
            , onClick AddLayer
            ] <> styles
                [ Tuple "padding" "2px 6px"
                , Tuple "border" "none"
                , Tuple "border-radius" "3px"
                , Tuple "background" "#3a3a5e"
                , Tuple "color" "#ccc"
                , Tuple "cursor" "pointer"
                ])
            [ text "+" ]
        ]
    , div_
        ([ class_ "layer-list" ] <> styles
            [ Tuple "display" "flex"
            , Tuple "flex-direction" "column"
            , Tuple "gap" "2px"
            ])
        (map (renderLayerItem activeId) layers)
    ]

-- | Render a single layer item in the panel.
-- |
-- | Shows layer name and visibility indicator.
-- | Active layer is highlighted with a different background.
renderLayerItem :: LayerId -> Layer -> Element Msg
renderLayerItem activeId layer =
  let 
    lid = layerId layer
    isActive = lid == activeId
    isVisible = layerVisible layer
    bgColor = if isActive then "#4a4a6a" else "#2a2a4e"
    textColor = if isVisible then "#fff" else "#666"
  in button_
    ([ class_ "layer-item"
    , onClick (LayerSelected lid)
    , E.title (layerName layer)
    ] <> styles
        [ Tuple "display" "flex"
        , Tuple "align-items" "center"
        , Tuple "gap" "4px"
        , Tuple "padding" "4px 6px"
        , Tuple "border" "none"
        , Tuple "border-radius" "3px"
        , Tuple "background" bgColor
        , Tuple "color" textColor
        , Tuple "cursor" "pointer"
        , Tuple "text-align" "left"
        , Tuple "width" "100%"
        ])
    [ -- Visibility indicator
      span_ 
        (styles 
            [ Tuple "width" "8px"
            , Tuple "height" "8px"
            , Tuple "border-radius" "50%"
            , Tuple "background" (if isVisible then "#0f0" else "#333")
            ])
        []
    , span_ (styles [ Tuple "flex" "1", Tuple "overflow" "hidden", Tuple "text-overflow" "ellipsis" ]) 
        [ text (layerName layer) ]
    ]

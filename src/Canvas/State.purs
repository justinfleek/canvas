-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                          // canvas // state
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas State — Complete application state for the paint app.
-- |
-- | ## Design Philosophy
-- |
-- | The state combines:
-- | - **Hydrogen CanvasState**: Viewport, gestures, tools, selection, history
-- | - **PaintSystem**: SPH particle simulation
-- | - **GravityState**: Device orientation → gravity
-- | - **LayerStack**: Paint layers with Z-ordering
-- | - **BrushConfig**: Current brush settings
-- |
-- | ## Elm Architecture
-- |
-- | State × Msg → State × [Cmd]
-- |
-- | All state transitions are pure. Effects (sensor reads, GPU renders)
-- | are tracked via the graded monad system.
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Hydrogen.Element.Compound.Canvas.State
-- | - Canvas.Types
-- | - Canvas.Layer.Types
-- | - Canvas.Paint.Particle
-- | - Canvas.Physics.Gravity

module Canvas.State
  ( -- * Application State
    AppState
  , HistoryEntry
  , mkAppState
  , initialAppState
  
  -- * State Accessors
  , viewport
  , currentTool
  , paintSystem
  , gravityState
  , layerStack
  , brushConfig
  , activeLayerId
  , isPlaying
  
  -- * Brush Configuration
  , BrushConfig
  , mkBrushConfig
  , defaultBrushConfig
  , brushSize
  , brushOpacity
  , brushColor
  , brushPreset
  
  -- * State Updates (pure)
  , setTool
  , setBrushSize
  , setBrushOpacity
  , setBrushColor
  , setBrushPreset
  , setActiveLayer
  , togglePlaying
  
  -- * Paint Operations
  , addPaintParticle
  , clearActiveLayer
  , simulatePaint
  
  -- * Gravity Operations
  , updateGravity
  , setGravityEnabled
  
  -- * Layer Operations
  , addLayer
  , removeLayer
  , setLayerVisibility
  , layerCount
  
  -- * History
  , canUndo
  , canRedo
  , undo
  , redo
  , pushHistory
  
  -- * Display
  , displayAppState
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( class Eq
  , class Show
  , show
  , (==)
  , (&&)
  , (||)
  , (+)
  , (-)
  , (>)
  , (<>)
  , map
  , max
  , min
  , not
  )

import Data.Array (length, snoc, unsnoc) as Array
import Data.Maybe (Maybe(Just, Nothing))

-- Canvas modules
import Canvas.Types
  ( Tool(BrushTool)
  , LayerId
  , mkLayerId
  , unwrapLayerId
  , defaultLayerId
  , backgroundLayerId
  , Bounds
  , mkBounds
  , Color
  , mkColor
  , colorBlack
  , ZIndex
  , mkZIndex
  )

import Canvas.Layer.Types
  ( Layer
  , LayerStack
  , mkLayerStack
  , emptyLayerStack
  , mkLayer
  , addLayer
  , removeLayer
  , getActiveLayer
  , setActiveLayer
  , updateLayer
  , setLayerVisible
  , layerCount
  , stackActiveLayerId
  ) as Layer

import Canvas.Paint.Particle
  ( PaintSystem
  , PaintPreset(Watercolor)
  , mkPaintSystem
  , emptyPaintSystem
  , addParticle
  , clearParticles
  , simulateStep
  , applyGravity
  , particleCount
  , presetName
  ) as Paint

import Canvas.Physics.Gravity
  ( GravityState
  , initialGravityState
  , updateFromOrientation
  , setGravityEnabled
  , getGravity2D
  , isGravityActive
  ) as Gravity

-- ═════════════════════════════════════════════════════════════════════════════
--                                                             // brush config
-- ═════════════════════════════════════════════════════════════════════════════

-- | Brush configuration for painting.
type BrushConfig =
  { size :: Number           -- ^ Brush diameter in pixels (1-500)
  , opacity :: Number        -- ^ Brush opacity (0-1)
  , color :: Color           -- ^ Current paint color
  , preset :: Paint.PaintPreset  -- ^ Paint type (watercolor, oil, etc.)
  , spacing :: Number        -- ^ Spacing between dabs (0.1-2.0)
  , hardness :: Number       -- ^ Edge hardness (0-1)
  }

-- | Create brush config with validation.
mkBrushConfig :: Number -> Number -> Color -> Paint.PaintPreset -> BrushConfig
mkBrushConfig sz op col pre =
  { size: max 1.0 (min 500.0 sz)
  , opacity: max 0.0 (min 1.0 op)
  , color: col
  , preset: pre
  , spacing: 0.25             -- Default: 25% spacing
  , hardness: 0.8             -- Default: fairly hard edge
  }

-- | Default brush (20px black watercolor).
defaultBrushConfig :: BrushConfig
defaultBrushConfig = mkBrushConfig 20.0 1.0 colorBlack Paint.Watercolor

-- | Get brush size.
brushSize :: BrushConfig -> Number
brushSize b = b.size

-- | Get brush opacity.
brushOpacity :: BrushConfig -> Number
brushOpacity b = b.opacity

-- | Get brush color.
brushColor :: BrushConfig -> Color
brushColor b = b.color

-- | Get brush preset.
brushPreset :: BrushConfig -> Paint.PaintPreset
brushPreset b = b.preset

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // history entry
-- ═════════════════════════════════════════════════════════════════════════════

-- | History entry for undo/redo.
type HistoryEntry =
  { layerStack :: Layer.LayerStack
  , label :: String           -- Human-readable description
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // app state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Complete application state for Canvas paint app.
type AppState =
  { -- Canvas bounds
    canvasBounds :: Bounds
    
  -- Current tool
  , tool :: Tool
  
  -- Brush configuration
  , brush :: BrushConfig
  
  -- Layer system
  , layers :: Layer.LayerStack
  
  -- Paint particle system (per active layer)
  , paint :: Paint.PaintSystem
  
  -- Device gravity
  , gravity :: Gravity.GravityState
  
  -- Animation state
  , playing :: Boolean        -- ^ Is simulation running?
  , frameCount :: Int         -- ^ Total frames rendered
  , lastFrameTime :: Number   -- ^ Timestamp of last frame (ms)
  
  -- History
  , undoStack :: Array HistoryEntry
  , redoStack :: Array HistoryEntry
  , maxHistorySize :: Int
  
  -- Debug
  , showDebugOverlay :: Boolean
  }

-- | Create app state with specified bounds.
mkAppState :: Number -> Number -> AppState
mkAppState width height =
  let
    bounds = mkBounds 0.0 0.0 width height
    defaultLayer = Layer.mkLayer defaultLayerId "Layer 1" (mkZIndex 1) bounds
    bgLayer = Layer.mkLayer backgroundLayerId "Background" (mkZIndex 0) bounds
  in
    { canvasBounds: bounds
    , tool: BrushTool
    , brush: defaultBrushConfig
    , layers: Layer.mkLayerStack [bgLayer, defaultLayer] defaultLayerId
    , paint: Paint.mkPaintSystem bounds Paint.Watercolor
    , gravity: Gravity.initialGravityState
    , playing: false
    , frameCount: 0
    , lastFrameTime: 0.0
    , undoStack: []
    , redoStack: []
    , maxHistorySize: 50
    , showDebugOverlay: false
    }

-- | Initial app state (1920x1080 canvas).
initialAppState :: AppState
initialAppState = mkAppState 1920.0 1080.0

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // state accessors
-- ═════════════════════════════════════════════════════════════════════════════

-- | Get canvas viewport bounds.
viewport :: AppState -> Bounds
viewport s = s.canvasBounds

-- | Get current tool.
currentTool :: AppState -> Tool
currentTool s = s.tool

-- | Get paint system.
paintSystem :: AppState -> Paint.PaintSystem
paintSystem s = s.paint

-- | Get gravity state.
gravityState :: AppState -> Gravity.GravityState
gravityState s = s.gravity

-- | Get layer stack.
layerStack :: AppState -> Layer.LayerStack
layerStack s = s.layers

-- | Get brush config.
brushConfig :: AppState -> BrushConfig
brushConfig s = s.brush

-- | Get active layer ID.
activeLayerId :: AppState -> LayerId
activeLayerId s = Layer.stackActiveLayerId s.layers

-- | Check if simulation is playing.
isPlaying :: AppState -> Boolean
isPlaying s = s.playing

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // state updates
-- ═════════════════════════════════════════════════════════════════════════════

-- | Set current tool.
setTool :: Tool -> AppState -> AppState
setTool t s = s { tool = t }

-- | Set brush size.
setBrushSize :: Number -> AppState -> AppState
setBrushSize sz s = 
  s { brush = s.brush { size = max 1.0 (min 500.0 sz) } }

-- | Set brush opacity.
setBrushOpacity :: Number -> AppState -> AppState
setBrushOpacity op s = 
  s { brush = s.brush { opacity = max 0.0 (min 1.0 op) } }

-- | Set brush color.
setBrushColor :: Color -> AppState -> AppState
setBrushColor c s = s { brush = s.brush { color = c } }

-- | Set brush preset (paint type).
setBrushPreset :: Paint.PaintPreset -> AppState -> AppState
setBrushPreset p s = 
  s { brush = s.brush { preset = p }
    , paint = s.paint { preset = p }
    }

-- | Set active layer.
setActiveLayer :: LayerId -> AppState -> AppState
setActiveLayer lid s = 
  s { layers = Layer.setActiveLayer lid s.layers }

-- | Toggle simulation playing state.
togglePlaying :: AppState -> AppState
togglePlaying s = s { playing = not s.playing }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // paint operations
-- ═════════════════════════════════════════════════════════════════════════════

-- | Add a paint particle at position.
addPaintParticle :: Number -> Number -> AppState -> AppState
addPaintParticle px py s =
  s { paint = Paint.addParticle s.paint px py s.brush.color }

-- | Clear all particles from active layer.
clearActiveLayer :: AppState -> AppState
clearActiveLayer s = s { paint = Paint.clearParticles s.paint }

-- | Run one simulation step.
simulatePaint :: Number -> AppState -> AppState
simulatePaint dt s =
  if s.playing
    then
      let
        -- Get gravity from device orientation
        g2d = Gravity.getGravity2D s.gravity
        -- Apply gravity to paint system
        withGravity = Paint.applyGravity s.paint g2d.vx g2d.vy
        -- Run simulation step
        simulated = Paint.simulateStep withGravity dt
      in
        s { paint = simulated
          , frameCount = s.frameCount + 1
          }
    else s

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // gravity operations
-- ═════════════════════════════════════════════════════════════════════════════

-- | Update gravity from device orientation.
updateGravity :: Number -> Number -> Number -> AppState -> AppState
updateGravity alpha beta gamma s =
  s { gravity = Gravity.updateFromOrientation alpha beta gamma s.gravity }

-- | Enable or disable gravity.
setGravityEnabled :: Boolean -> AppState -> AppState
setGravityEnabled en s =
  s { gravity = Gravity.setGravityEnabled en s.gravity }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // layer operations
-- ═════════════════════════════════════════════════════════════════════════════

-- | Add a new paint layer.
addLayer :: String -> AppState -> AppState
addLayer name s =
  let
    newId = mkLayerId (Layer.layerCount s.layers + 1)
    newZ = mkZIndex (Layer.layerCount s.layers + 1)
    newLayer = Layer.mkLayer newId name newZ s.canvasBounds
  in
    s { layers = Layer.addLayer newLayer s.layers }

-- | Remove a layer by ID.
removeLayer :: LayerId -> AppState -> AppState
removeLayer lid s =
  -- Don't allow removing background layer
  if unwrapLayerId lid == 0
    then s
    else s { layers = Layer.removeLayer lid s.layers }

-- | Set layer visibility.
setLayerVisibility :: LayerId -> Boolean -> AppState -> AppState
setLayerVisibility lid vis s =
  s { layers = Layer.updateLayer lid (Layer.setLayerVisible vis) s.layers }

-- | Get total layer count.
layerCount :: AppState -> Int
layerCount s = Layer.layerCount s.layers

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // history
-- ═════════════════════════════════════════════════════════════════════════════

-- | Check if undo is available.
canUndo :: AppState -> Boolean
canUndo s = Array.length s.undoStack > 0

-- | Check if redo is available.
canRedo :: AppState -> Boolean
canRedo s = Array.length s.redoStack > 0

-- | Push current state to history.
pushHistory :: String -> AppState -> AppState
pushHistory label s =
  let
    entry = { layerStack: s.layers, label: label }
    newUndo = Array.snoc s.undoStack entry
    -- Trim history if too large
    trimmedUndo = 
      if Array.length newUndo > s.maxHistorySize
        then case Array.unsnoc newUndo of
          Just { init } -> init
          Nothing -> newUndo
        else newUndo
  in
    s { undoStack = trimmedUndo
      , redoStack = []  -- Clear redo on new action
      }

-- | Undo last action.
undo :: AppState -> AppState
undo s =
  case Array.unsnoc s.undoStack of
    Nothing -> s  -- Nothing to undo
    Just { init: remaining, last: entry } ->
      let
        -- Push current state to redo
        currentEntry = { layerStack: s.layers, label: "undo" }
      in
        s { layers = entry.layerStack
          , undoStack = remaining
          , redoStack = Array.snoc s.redoStack currentEntry
          }

-- | Redo last undone action.
redo :: AppState -> AppState
redo s =
  case Array.unsnoc s.redoStack of
    Nothing -> s  -- Nothing to redo
    Just { init: remaining, last: entry } ->
      let
        -- Push current state to undo
        currentEntry = { layerStack: s.layers, label: "redo" }
      in
        s { layers = entry.layerStack
          , redoStack = remaining
          , undoStack = Array.snoc s.undoStack currentEntry
          }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

-- | Display app state summary.
displayAppState :: AppState -> String
displayAppState s =
  "Canvas { " <>
  "tool=" <> show s.tool <> ", " <>
  "brush=" <> show s.brush.size <> "px " <> Paint.presetName s.brush.preset <> ", " <>
  "layers=" <> show (Layer.layerCount s.layers) <> ", " <>
  "particles=" <> show (Paint.particleCount s.paint) <> ", " <>
  "playing=" <> show s.playing <> ", " <>
  "frames=" <> show s.frameCount <> " }"

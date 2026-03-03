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
  
  -- * Viewport State
  , ViewportState
  , initialViewport
  , viewportState
  , viewportScale
  , viewportPanX
  , viewportPanY
  , viewportRotation
  
  -- * State Accessors
  , viewport
  , currentTool
  , paintSystem
  , gravityState
  , layerStack
  , brushConfig
  , activeLayerId
  , isPlaying
  , easterEggState
  
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
  , addPaintParticleWithDynamics
  , clearActiveLayer
  , simulatePaint
  
  -- * Drag Physics (finger painting)
  , applyBrushDragFromPointer
  , setPointerDown
  , setPointerUp
  
  -- * Gravity Operations
  , updateGravity
  , setGravityEnabled
  
  -- * Layer Operations
  , addLayer
  , removeLayer
  , setLayerVisibility
  , toggleLayerVisibility
  , moveLayerUp
  , moveLayerDown
  , layerCount
  
  -- * Viewport Operations
  , panViewport
  , zoomViewport
  , zoomViewportAt
  , rotateViewport
  , resetViewport
  
  -- * Gesture Tracking
  , GestureTrackingState
  , gestureTracking
  , processTwoFingerGesture
  , endTwoFingerGesture
  
  -- * History
  , canUndo
  , canRedo
  , undo
  , redo
  , pushHistory
  
  -- * Easter Eggs
  , processEasterEggKey
  , processEasterEggMotion
  , updateEasterEggConfetti
  , triggerEasterEggConfetti
  , resetEasterEggs
  
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
  , (*)
  , (/)
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
  , getLayer
  , moveLayerUp
  , moveLayerDown
  , layerVisible
  ) as Layer

import Canvas.Paint.Particle
  ( PaintSystem
  , PaintPreset(Watercolor)
  , BrushDrag
  , mkPaintSystem
  , emptyPaintSystem
  , addParticle
  , clearParticles
  , simulateStep
  , applyGravity
  , applyBrushDrag
  , mkBrushDrag
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

import Canvas.Easter as Easter
import Canvas.Easter (EasterEggState)

-- Hydrogen gesture pure functions
import Hydrogen.Motion.Gesture as Gesture
import Hydrogen.Motion.Gesture 
  ( Point
  , TwoFingerData
  , computeTwoFingerData
  , normalizeAngle
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // viewport state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Viewport state for canvas navigation (pan, zoom, rotate).
-- |
-- | The viewport transform is applied in order: translate → scale → rotate
-- | This allows panning the view, then zooming at the current center,
-- | then rotating the canvas.
type ViewportState =
  { panX :: Number            -- ^ Horizontal pan offset (pixels)
  , panY :: Number            -- ^ Vertical pan offset (pixels)
  , scale :: Number           -- ^ Zoom scale (1.0 = 100%, 2.0 = 200%)
  , rotation :: Number        -- ^ Rotation angle (radians)
  , minScale :: Number        -- ^ Minimum zoom level
  , maxScale :: Number        -- ^ Maximum zoom level
  }

-- | Initial viewport (no pan, 100% zoom, no rotation).
initialViewport :: ViewportState
initialViewport =
  { panX: 0.0
  , panY: 0.0
  , scale: 1.0
  , rotation: 0.0
  , minScale: 0.1
  , maxScale: 10.0
  }

-- | Get viewport scale.
viewportScale :: ViewportState -> Number
viewportScale v = v.scale

-- | Get viewport pan X.
viewportPanX :: ViewportState -> Number
viewportPanX v = v.panX

-- | Get viewport pan Y.
viewportPanY :: ViewportState -> Number
viewportPanY v = v.panY

-- | Get viewport rotation.
viewportRotation :: ViewportState -> Number
viewportRotation v = v.rotation

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // gesture tracking
-- ═════════════════════════════════════════════════════════════════════════════

-- | Gesture tracking state for two-finger gestures.
-- |
-- | Tracks the previous state of a multi-touch gesture so we can compute
-- | deltas for pan, pinch scale, and rotation.
type GestureTrackingState =
  { active :: Boolean            -- ^ Is a two-finger gesture active?
  , touchCount :: Int            -- ^ Number of active touches
  , initialDistance :: Number    -- ^ Distance between fingers at gesture start
  , initialAngle :: Number       -- ^ Angle between fingers at gesture start (degrees)
  , lastCenter :: { x :: Number, y :: Number }  -- ^ Last center point
  , lastDistance :: Number       -- ^ Last distance between fingers
  , lastAngle :: Number          -- ^ Last angle between fingers
  }

-- | Initial gesture tracking state (no active gesture).
initialGestureTracking :: GestureTrackingState
initialGestureTracking =
  { active: false
  , touchCount: 0
  , initialDistance: 0.0
  , initialAngle: 0.0
  , lastCenter: { x: 0.0, y: 0.0 }
  , lastDistance: 0.0
  , lastAngle: 0.0
  }

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
    
  -- Viewport (pan, zoom, rotate)
  , viewportState :: ViewportState
    
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
  
  -- Easter eggs (Konami code, shake detection, confetti)
  , easterEggs :: EasterEggState
  
  -- Gesture tracking (for two-finger pan/pinch/rotate)
  , gesture :: GestureTrackingState
  
  -- Pointer tracking (for drag physics)
  , lastPointerX :: Number      -- ^ Previous pointer X for drag velocity
  , lastPointerY :: Number      -- ^ Previous pointer Y for drag velocity
  , pointerDown :: Boolean      -- ^ Is pointer currently down?
  
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
    , viewportState: initialViewport
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
    , easterEggs: Easter.initialState
    , gesture: initialGestureTracking
    , lastPointerX: 0.0
    , lastPointerY: 0.0
    , pointerDown: false
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

-- | Get easter egg state.
easterEggState :: AppState -> EasterEggState
easterEggState s = s.easterEggs

-- | Get viewport state.
viewportState :: AppState -> ViewportState
viewportState s = s.viewportState

-- | Get gesture tracking state.
gestureTracking :: AppState -> GestureTrackingState
gestureTracking s = s.gesture

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

-- | Add a paint particle at position (default pressure).
addPaintParticle :: Number -> Number -> AppState -> AppState
addPaintParticle px py s =
  s { paint = Paint.addParticle s.paint px py s.brush.color }

-- | Add a paint particle with full stylus dynamics.
-- |
-- | Uses pressure and tilt from stylus to affect:
-- | - Size: pressure scales brush size (0.2x to 1.0x)
-- | - Opacity: pressure scales opacity
-- | - Flow direction: tilt affects initial particle velocity
-- |
-- | This is the professional art tool path for realistic paint simulation.
addPaintParticleWithDynamics 
  :: Number          -- ^ X position
  -> Number          -- ^ Y position
  -> Number          -- ^ Pressure (0.0-1.0)
  -> Number          -- ^ Tilt X (-90 to 90)
  -> Number          -- ^ Tilt Y (-90 to 90)
  -> AppState 
  -> AppState
addPaintParticleWithDynamics px py pressure tiltX tiltY s =
  let
    -- Apply pressure to brush size (20% to 100% based on pressure)
    sizeMultiplier = 0.2 + (pressure * 0.8)
    effectiveSize = s.brush.size * sizeMultiplier
    
    -- Apply pressure to opacity
    effectiveOpacity = s.brush.opacity * pressure
    
    -- Compute position offset from tilt
    -- Tilt angles (-90 to 90) mapped to offset (-5 to 5 pixels)
    -- This simulates brush angle affecting paint placement
    tiltOffsetX = tiltX / 18.0
    tiltOffsetY = tiltY / 18.0
    
    -- Apply tilt offset to create angled brush effect
    effectiveX = px + tiltOffsetX
    effectiveY = py + tiltOffsetY
    
    -- Add particle with dynamics
    -- Use the effective size/opacity through brush config
    withSizedBrush = s { brush = s.brush { size = effectiveSize, opacity = effectiveOpacity } }
    withParticle = withSizedBrush { paint = Paint.addParticle withSizedBrush.paint effectiveX effectiveY s.brush.color }
    
    -- Restore original brush settings for next stroke
    restored = withParticle { brush = s.brush }
  in
    restored

-- | Clear all particles from active layer.
clearActiveLayer :: AppState -> AppState
clearActiveLayer s = s { paint = Paint.clearParticles s.paint }

-- | Apply brush drag when pointer moves.
-- |
-- | This is the "finger painting" effect - when the user drags their
-- | finger/stylus across wet paint, it smears and moves.
-- |
-- | Should be called on pointer move events when pointer is down.
applyBrushDragFromPointer 
  :: Number          -- ^ Current X
  -> Number          -- ^ Current Y
  -> Number          -- ^ Pressure (0-1)
  -> AppState 
  -> AppState
applyBrushDragFromPointer cx cy pressure s =
  if s.pointerDown
    then
      let
        -- Create brush drag from movement
        brushDrag = Paint.mkBrushDrag 
          cx cy 
          s.lastPointerX s.lastPointerY
          (s.brush.size * 1.5)  -- Influence radius slightly larger than brush
          pressure
        
        -- Apply drag to paint system
        withDrag = Paint.applyBrushDrag brushDrag s.paint
      in
        s { paint = withDrag
          , lastPointerX = cx
          , lastPointerY = cy
          }
    else
      s { lastPointerX = cx, lastPointerY = cy }

-- | Set pointer down state and initial position.
setPointerDown :: Number -> Number -> AppState -> AppState
setPointerDown x y s = 
  s { pointerDown = true
    , lastPointerX = x
    , lastPointerY = y
    }

-- | Set pointer up state.
setPointerUp :: AppState -> AppState
setPointerUp s = s { pointerDown = false }

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

-- | Toggle layer visibility.
toggleLayerVisibility :: LayerId -> AppState -> AppState
toggleLayerVisibility lid s =
  case Layer.getLayer lid s.layers of
    Nothing -> s
    Just layer -> 
      let currentVis = Layer.layerVisible layer
      in setLayerVisibility lid (not currentVis) s

-- | Move a layer up in the stack (higher Z-index).
moveLayerUp :: LayerId -> AppState -> AppState
moveLayerUp lid s =
  s { layers = Layer.moveLayerUp lid s.layers }

-- | Move a layer down in the stack (lower Z-index).
moveLayerDown :: LayerId -> AppState -> AppState
moveLayerDown lid s =
  s { layers = Layer.moveLayerDown lid s.layers }

-- | Get total layer count.
layerCount :: AppState -> Int
layerCount s = Layer.layerCount s.layers

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // viewport operations
-- ═════════════════════════════════════════════════════════════════════════════

-- | Pan the viewport by delta.
-- |
-- | Used for two-finger pan gestures or click-and-drag navigation.
panViewport :: Number -> Number -> AppState -> AppState
panViewport dx dy s =
  let vp = s.viewportState
  in s { viewportState = vp { panX = vp.panX + dx, panY = vp.panY + dy } }

-- | Zoom the viewport by scale factor.
-- |
-- | Scale is multiplicative: 2.0 doubles the zoom, 0.5 halves it.
-- | Clamped to minScale..maxScale range.
zoomViewport :: Number -> AppState -> AppState
zoomViewport scaleDelta s =
  let 
    vp = s.viewportState
    newScale = max vp.minScale (min vp.maxScale (vp.scale * scaleDelta))
  in s { viewportState = vp { scale = newScale } }

-- | Zoom the viewport centered on a point.
-- |
-- | Used for pinch-to-zoom where the center of the pinch should stay fixed.
-- | This adjusts pan to keep the focal point stationary.
zoomViewportAt :: Number -> Number -> Number -> AppState -> AppState
zoomViewportAt centerX centerY scaleDelta s =
  let 
    vp = s.viewportState
    oldScale = vp.scale
    newScale = max vp.minScale (min vp.maxScale (oldScale * scaleDelta))
    
    -- To keep the center point fixed, we need to adjust pan
    -- The point (centerX, centerY) in screen space maps to:
    --   world = (screen - pan) / scale
    -- After scaling, we want the same world point at same screen position
    -- So: (center - newPan) / newScale = (center - oldPan) / oldScale
    -- Solving: newPan = center - (center - oldPan) * (newScale / oldScale)
    scaleRatio = newScale / oldScale
    newPanX = centerX - (centerX - vp.panX) * scaleRatio
    newPanY = centerY - (centerY - vp.panY) * scaleRatio
  in 
    s { viewportState = vp 
        { scale = newScale
        , panX = newPanX
        , panY = newPanY 
        } 
      }

-- | Rotate the viewport by angle (in radians).
-- |
-- | Used for two-finger rotate gestures.
rotateViewport :: Number -> AppState -> AppState
rotateViewport deltaRotation s =
  let vp = s.viewportState
  in s { viewportState = vp { rotation = vp.rotation + deltaRotation } }

-- | Reset viewport to initial state.
-- |
-- | Double-tap or reset button brings view back to 100%, centered, no rotation.
resetViewport :: AppState -> AppState
resetViewport s = s { viewportState = initialViewport }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                       // gesture processing
-- ═════════════════════════════════════════════════════════════════════════════

-- | Process a two-finger gesture from touch data.
-- |
-- | Takes two touch points and computes pan, pinch (zoom), and rotate deltas.
-- | Updates both the gesture tracking state and the viewport in one step.
-- |
-- | This is a pure function that processes touch coordinates:
-- | - First call with two fingers starts the gesture (stores initial state)
-- | - Subsequent calls compute deltas from previous state
-- | - Returns updated state with new viewport transform
processTwoFingerGesture 
  :: { x :: Number, y :: Number }  -- ^ First touch point
  -> { x :: Number, y :: Number }  -- ^ Second touch point
  -> AppState 
  -> AppState
processTwoFingerGesture p1 p2 s =
  let
    -- Convert to Point type for Hydrogen gesture functions
    point1 :: Point
    point1 = { x: p1.x, y: p1.y }
    
    point2 :: Point
    point2 = { x: p2.x, y: p2.y }
    
    -- Compute current two-finger data
    current :: TwoFingerData
    current = computeTwoFingerData point1 point2
    
    g = s.gesture
    vp = s.viewportState
  in
    if g.active then
      -- Gesture is active, compute deltas
      let
        -- Pan delta
        dx = current.center.x - g.lastCenter.x
        dy = current.center.y - g.lastCenter.y
        
        -- Scale delta (ratio of current distance to last distance)
        scaleDelta = if g.lastDistance > 0.001 
                     then current.distance / g.lastDistance 
                     else 1.0
        
        -- Rotation delta (in degrees, then convert to radians)
        angleDeltaDegrees = normalizeAngle (current.angle - g.lastAngle)
        angleDeltaRadians = angleDeltaDegrees * 3.14159 / 180.0
        
        -- Update viewport with all deltas
        newScale = max vp.minScale (min vp.maxScale (vp.scale * scaleDelta))
        
        -- Update gesture tracking
        newGesture = g
          { lastCenter = current.center
          , lastDistance = current.distance
          , lastAngle = current.angle
          }
      in
        s { gesture = newGesture
          , viewportState = vp
              { panX = vp.panX + dx
              , panY = vp.panY + dy
              , scale = newScale
              , rotation = vp.rotation + angleDeltaRadians
              }
          }
    else
      -- Gesture just started, initialize tracking
      let
        newGesture = 
          { active: true
          , touchCount: 2
          , initialDistance: current.distance
          , initialAngle: current.angle
          , lastCenter: current.center
          , lastDistance: current.distance
          , lastAngle: current.angle
          }
      in
        s { gesture = newGesture }

-- | End a two-finger gesture.
-- |
-- | Called when touch ends or goes to single touch.
-- | Resets gesture tracking state.
endTwoFingerGesture :: AppState -> AppState
endTwoFingerGesture s = s { gesture = initialGestureTracking }

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
--                                                         // easter egg operations
-- ═════════════════════════════════════════════════════════════════════════════

-- | Process a key press for easter egg detection (Konami code).
processEasterEggKey :: String -> AppState -> AppState
processEasterEggKey key s =
  s { easterEggs = Easter.processKey key s.easterEggs }

-- | Process device motion for easter egg detection (shake).
processEasterEggMotion 
  :: { accelerationX :: Number
     , accelerationY :: Number
     , accelerationZ :: Number
     , timestamp :: Number
     }
  -> AppState 
  -> AppState
processEasterEggMotion motion s =
  s { easterEggs = Easter.processMotion motion s.easterEggs }

-- | Update confetti animation each frame.
updateEasterEggConfetti :: Number -> AppState -> AppState
updateEasterEggConfetti dt s =
  s { easterEggs = Easter.updateConfetti dt s.easterEggs }

-- | Trigger confetti explosion at position (for Konami code reward).
triggerEasterEggConfetti :: Number -> Number -> AppState -> AppState
triggerEasterEggConfetti x y s =
  s { easterEggs = Easter.triggerConfetti x y s.easterEggs }

-- | Reset easter egg detection states after handling triggers.
resetEasterEggs :: AppState -> AppState
resetEasterEggs s =
  s { easterEggs = Easter.reset s.easterEggs }

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

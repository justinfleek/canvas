-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                            // canvas // main
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas Main — Entry point for the physics-based paint application.
-- |
-- | ## Architecture
-- |
-- | Uses Hydrogen's Runtime.App for the Elm-style architecture:
-- |
-- | ```
-- | State × Msg → State × Cmd
-- | view :: State → Element Msg
-- | subscriptions :: State → Array (Sub Msg)
-- | ```
-- |
-- | ## Device Integration
-- |
-- | Subscriptions wire up:
-- | - **OnAnimationFrame**: Physics simulation tick
-- | - **OnDeviceOrientation**: Device tilt → gravity
-- | - **OnTouchStart/Move/End**: Paint input
-- | - **OnMouseDown/Move/Up**: Desktop paint input
-- |
-- | ## SPH Fluid Simulation
-- |
-- | When you tilt your phone, paint particles flow using:
-- |   F_total = F_pressure + F_viscosity + F_gravity
-- |
-- | This is the proof of concept that PureScript Hydrogen works
-- | with straylight-web using graded monads for effect tracking.
-- |
-- | ## Dependencies
-- | - Hydrogen.Runtime.App (Elm architecture)
-- | - Hydrogen.Runtime.Cmd (commands)
-- | - Hydrogen.Render.Element (pure elements)
-- | - Canvas.State (application state)
-- | - Canvas.View (pure view function)

module Main
  ( -- * Entry Point
    main
    
  -- * Application
  , canvasApp
  
  -- * Configuration Constants
  , frameTimeMs
  , physicsTimestep
  , gravityScale
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( Unit
  , discard
  , pure
  , show
  , unit
  , (+)
  , (/)
  , (<>)
  , (==)
  , not
  )

import Effect (Effect)
import Effect.Console (log)

import Data.Array (head) as Array
import Data.Maybe (Maybe(Just, Nothing))

-- Hydrogen Runtime
import Hydrogen.Runtime.App
  ( App
  , Sub
      ( OnAnimationFrame
      , OnMouseDown
      , OnMouseMove
      , OnMouseUp
      , OnTouchStart
      , OnTouchMove
      , OnTouchEnd
      , OnDeviceOrientation
      )
  , MousePos
  , MouseEvent
  , TouchEvent
  , DeviceOrientationEvent
  )

import Hydrogen.Runtime.Cmd
  ( Transition
  , noCmd
  )

-- Hydrogen Elements
import Hydrogen.Render.Element (Element)

-- Canvas modules
import Canvas.State as State
import Canvas.State (AppState)
import Canvas.View as View
import Canvas.View (Msg)
import Canvas.Types (Tool(BrushTool))
import Canvas.Physics.Gravity as Gravity
import Canvas.Runtime.DOM as DOM

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // app config
-- ═════════════════════════════════════════════════════════════════════════════

-- | Frame rate target (60 FPS = 16.67ms per frame)
frameTimeMs :: Number
frameTimeMs = 16.67

-- | Physics timestep (fixed at 60Hz for stability)
physicsTimestep :: Number
physicsTimestep = 0.016

-- | Gravity scale from device sensors
gravityScale :: Number
gravityScale = 9.81

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                // canvas app
-- ═════════════════════════════════════════════════════════════════════════════

-- | The Canvas application definition.
-- |
-- | This is a complete Hydrogen App with:
-- | - init: Initial state and startup commands
-- | - update: Message handler (state transitions)
-- | - view: Pure view function
-- | - subscriptions: Active event subscriptions
-- | - triggers: Interactive trigger definitions
canvasApp :: App AppState Msg (Element Msg)
canvasApp =
  { init: initCanvas
  , update: updateCanvas
  , view: View.view
  , subscriptions: subscriptionsCanvas
  , triggers: []
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                      // init
-- ═════════════════════════════════════════════════════════════════════════════

-- | Initialize the canvas application.
-- |
-- | Creates the initial state with:
-- | - 1920x1080 canvas (will resize to viewport)
-- | - Watercolor brush preset
-- | - Gravity enabled
-- | - Playing enabled (simulation active)
initCanvas :: Transition AppState Msg
initCanvas =
  let
    initialState = State.initialAppState
    -- Start with simulation playing
    withPlaying = State.togglePlaying initialState
    -- Enable gravity by default
    withGravity = State.setGravityEnabled true withPlaying
  in
    noCmd withGravity

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // update
-- ═════════════════════════════════════════════════════════════════════════════

-- | Handle all application messages.
-- |
-- | This is the core state machine. Every interaction flows through here:
-- | - Tool selection
-- | - Paint input (touch/mouse)
-- | - Device orientation (gravity)
-- | - Animation frames (physics simulation)
-- | - History operations (undo/redo)
updateCanvas :: Msg -> AppState -> Transition AppState Msg
updateCanvas msg state = case msg of
  
  -- Tool selection
  View.ToolSelected tool ->
    noCmd (State.setTool tool state)
  
  -- Brush preset selection
  View.BrushPresetSelected _presetName ->
    -- TODO: Map preset name to actual preset
    noCmd state
  
  -- Media type selection (watercolor, oil, etc)
  View.MediaTypeSelected _mediaType ->
    -- TODO: Map media type to paint preset
    noCmd state
  
  -- Color change
  View.ColorChanged color ->
    noCmd (State.setBrushColor color state)
  
  -- Canvas touch/click start (add paint particle)
  View.CanvasTouched x y ->
    let
      -- Add a paint particle at touch position
      withParticle = State.addPaintParticle x y state
      -- Push history for undo
      withHistory = State.pushHistory "Paint stroke" withParticle
    in
      noCmd withHistory
  
  -- Canvas move (paint while dragging)
  View.CanvasMoved x y ->
    -- Only add particles if this is a painting tool
    if isPaintingActive state
      then noCmd (State.addPaintParticle x y state)
      else noCmd state
  
  -- Canvas release
  View.CanvasReleased ->
    noCmd state
  
  -- Device orientation change (update gravity)
  View.OrientationChanged orientation ->
    let
      updated = State.updateGravity 
        orientation.alpha 
        orientation.beta 
        orientation.gamma 
        state
    in
      noCmd updated
  
  -- Toggle gravity on/off
  View.ToggleGravity ->
    let
      currentGrav = State.gravityState state
      isEnabled = Gravity.gravityEnabled currentGrav
      updated = State.setGravityEnabled (not isEnabled) state
    in
      noCmd updated
  
  -- Toggle simulation playing
  View.TogglePlaying ->
    noCmd (State.togglePlaying state)
  
  -- Clear canvas
  View.ClearCanvas ->
    let
      cleared = State.clearActiveLayer state
      withHistory = State.pushHistory "Clear canvas" cleared
    in
      noCmd withHistory
  
  -- Undo
  View.Undo ->
    noCmd (State.undo state)
  
  -- Redo
  View.Redo ->
    noCmd (State.redo state)
  
  -- Animation frame tick (run physics simulation)
  View.Tick dt ->
    -- dt is delta time in milliseconds, convert to seconds
    let
      dtSeconds = dt / 1000.0
      -- Run physics simulation step
      simulated = State.simulatePaint dtSeconds state
    in
      noCmd simulated
  
  -- Layer selected
  View.LayerSelected lid ->
    noCmd (State.setActiveLayer lid state)
  
  -- Add new layer
  View.AddLayer ->
    let
      newLayerName = "Layer " <> show (State.layerCount state + 1)
      withLayer = State.addLayer newLayerName state
      withHistory = State.pushHistory "Add layer" withLayer
    in
      noCmd withHistory

-- | Check if painting is currently active (brush tool selected).
isPaintingActive :: AppState -> Boolean
isPaintingActive state =
  let tool = State.currentTool state
  in tool == BrushTool

-- ═════════════════════════════════════════════════════════════════════════════
--                                                             // subscriptions
-- ═════════════════════════════════════════════════════════════════════════════

-- | Active subscriptions based on current state.
-- |
-- | ## Always Active
-- | - Animation frame (physics simulation runs continuously when playing)
-- | - Device orientation (gravity responds to device tilt)
-- |
-- | ## Conditionally Active
-- | - Touch events (only when painting tool selected)
-- | - Mouse events (only when painting tool selected)
subscriptionsCanvas :: AppState -> Array (Sub Msg)
subscriptionsCanvas state =
  let
    -- Animation frame for physics simulation
    animationSub = 
      if State.isPlaying state
        then [ OnAnimationFrame handleAnimationFrame ]
        else []
    
    -- Device orientation for gravity
    orientationSub = 
      if Gravity.gravityEnabled (State.gravityState state)
        then [ OnDeviceOrientation handleDeviceOrientation ]
        else []
    
    -- Touch events for painting
    touchSubs = 
      [ OnTouchStart handleTouchStart
      , OnTouchMove handleTouchMove
      , OnTouchEnd handleTouchEnd
      ]
    
    -- Mouse events for painting (desktop)
    mouseSubs =
      [ OnMouseDown handleMouseDown
      , OnMouseMove handleMouseMove
      , OnMouseUp handleMouseUp
      ]
  in
    animationSub <> orientationSub <> touchSubs <> mouseSubs

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // event handlers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Handle animation frame (physics tick).
handleAnimationFrame :: Number -> Msg
handleAnimationFrame deltaTime = View.Tick deltaTime

-- | Handle device orientation change.
-- |
-- | Converts Runtime's DeviceOrientationEvent (with absolute flag)
-- | to Schema's DeviceOrientation (alpha, beta, gamma only).
handleDeviceOrientation :: DeviceOrientationEvent -> Msg
handleDeviceOrientation event = 
  let
    -- Extract just the euler angles, discarding the absolute flag
    orientation = 
      { alpha: event.alpha
      , beta: event.beta
      , gamma: event.gamma
      }
  in
    View.OrientationChanged orientation

-- | Handle touch start (begin painting).
handleTouchStart :: TouchEvent -> Msg
handleTouchStart event =
  case Array.head event.changedTouches of
    Just touch -> View.CanvasTouched touch.x touch.y
    Nothing -> View.CanvasReleased

-- | Handle touch move (continue painting).
handleTouchMove :: TouchEvent -> Msg
handleTouchMove event =
  case Array.head event.changedTouches of
    Just touch -> View.CanvasMoved touch.x touch.y
    Nothing -> View.CanvasReleased

-- | Handle touch end (stop painting).
handleTouchEnd :: TouchEvent -> Msg
handleTouchEnd _event = View.CanvasReleased

-- | Handle mouse down (begin painting on desktop).
handleMouseDown :: MouseEvent -> Msg
handleMouseDown event = View.CanvasTouched event.x event.y

-- | Handle mouse move (continue painting on desktop).
-- |
-- | OnMouseMove receives just position (MousePos), not full event.
handleMouseMove :: MousePos -> Msg
handleMouseMove pos = View.CanvasMoved pos.x pos.y

-- | Handle mouse up (stop painting on desktop).
handleMouseUp :: MouseEvent -> Msg
handleMouseUp _event = View.CanvasReleased

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                      // main
-- ═════════════════════════════════════════════════════════════════════════════

-- | Main entry point.
-- |
-- | Mounts the Canvas application to the #app DOM element.
-- | Returns Effect Unit after initialization completes.
main :: Effect Unit
main = do
  log "Canvas Builder initializing..."
  log "  - SPH fluid simulation: enabled"
  log "  - Device orientation: listening"
  log "  - Touch input: ready"
  log "  - Physics timestep: 16.67ms (60 FPS)"
  log ""
  
  -- Mount the application to #app
  -- This starts the animation loop and returns immediately
  DOM.mount "#app" canvasApp updateCanvas View.view initCanvas
  
  -- Log completion and return unit
  log "Canvas Builder ready!"
  pure unit



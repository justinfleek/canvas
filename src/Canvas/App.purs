-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                            // canvas // app
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas App — Entry point for the physics-based paint application.
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

module Canvas.App
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
  , (<)
  , (<>)
  , (==)
  , (||)
  , (&&)
  , not
  )

import Effect (Effect)
import Effect.Console (log)

import Data.Array (head, index, length) as Array
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
      , OnDeviceMotion
      , OnKeyDown
      , OnPointerDown
      , OnPointerMove
      , OnPointerUp
      )
  , MousePos
  , MouseEvent
  , TouchEvent
  , DeviceOrientationEvent
  , DeviceMotionEvent
  , PointerEvent
  )

import Hydrogen.Runtime.Cmd
  ( Transition
  , Cmd(Log)
  , transition
  , noCmd
  )

-- Hydrogen Elements
import Hydrogen.Render.Element (Element)

-- Canvas modules
import Canvas.State as State
import Canvas.State (AppState)
import Canvas.View as View
import Canvas.View (Msg, StylusInput)
import Canvas.Types (Tool(BrushTool))
import Canvas.Physics.Gravity as Gravity
import Canvas.Runtime.DOM as DOM

import Canvas.Paint.Particle as Paint
import Canvas.Paint.Particle (PaintPreset(Watercolor, OilPaint, Acrylic, Gouache, Ink, Honey))
import Hydrogen.Schema.Brush.WetMedia (WetMediaType(Watercolor, OilPaint, Acrylic, Gouache, Ink, WetIntoWet)) as WetMedia

-- Easter eggs
import Canvas.Easter as Easter

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                  // app state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Specialized AppState for this application's Msg type.
type CanvasState = AppState Msg

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
canvasApp :: App CanvasState Msg (Element Msg)
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
initCanvas :: Transition CanvasState Msg
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
updateCanvas :: Msg -> CanvasState -> Transition CanvasState Msg
updateCanvas msg state = case msg of
  
  -- Tool selection
  View.ToolSelected tool ->
    noCmd (State.setTool tool state)
  
  -- Brush preset selection (by name string from UI)
  View.BrushPresetSelected presetName ->
    let
      preset = presetFromName presetName
    in
      noCmd (State.setBrushPreset preset state)
  
  -- Media type selection (watercolor, oil, etc from Hydrogen WetMedia)
  View.MediaTypeSelected mediaType ->
    let
      preset = presetFromWetMedia mediaType
    in
      noCmd (State.setBrushPreset preset state)
  
  -- Color change
  View.ColorChanged color ->
    noCmd (State.setBrushColor color state)
  
  -- Brush size change
  View.BrushSizeChanged size ->
    noCmd (State.setBrushSize size state)
  
  -- Brush opacity change
  View.BrushOpacityChanged opacity ->
    noCmd (State.setBrushOpacity opacity state)
  
  -- Pointer down with full stylus data (pressure, tilt)
  View.PointerDown input ->
    let
      -- Track pointer down for drag physics
      withPointer = State.setPointerDown input.x input.y state
      -- Add a paint particle with full dynamics
      withParticle = State.addPaintParticleWithDynamics 
        input.x 
        input.y 
        input.pressure 
        input.tiltX 
        input.tiltY 
        withPointer
      -- Push history for undo
      withHistory = State.pushHistory "Paint stroke" withParticle
    in
      noCmd withHistory
  
  -- Pointer move with full stylus data
  -- This both adds new paint AND drags existing wet paint (finger painting)
  View.PointerMoved input ->
    if isPaintingActive state
      then 
        let
          -- First apply drag physics to existing wet paint
          withDrag = State.applyBrushDragFromPointer 
            input.x 
            input.y 
            input.pressure 
            state
          -- Then add new paint particle
          withParticle = State.addPaintParticleWithDynamics 
            input.x 
            input.y 
            input.pressure 
            input.tiltX 
            input.tiltY 
            withDrag
        in
          noCmd withParticle
      else noCmd state
  
  -- Pointer up (stylus/touch lifted)
  View.PointerUp ->
    noCmd (State.setPointerUp state)
  
  -- Legacy: Canvas touch/click start (no pressure/tilt, for fallback)
  View.CanvasTouched x y ->
    let
      -- Track pointer down for drag physics
      withPointer = State.setPointerDown x y state
      -- Add a paint particle at touch position with default pressure
      withParticle = State.addPaintParticle x y withPointer
      -- Push history for undo
      withHistory = State.pushHistory "Paint stroke" withParticle
    in
      noCmd withHistory
  
  -- Legacy: Canvas move (paint while dragging, no pressure/tilt)
  -- Also applies drag physics for finger painting effect
  View.CanvasMoved x y ->
    -- Only add particles if this is a painting tool
    if isPaintingActive state
      then 
        let
          -- Apply drag physics first (default pressure 0.5)
          withDrag = State.applyBrushDragFromPointer x y 0.5 state
          -- Then add new paint
          withParticle = State.addPaintParticle x y withDrag
        in
          noCmd withParticle
      else noCmd state
  
  -- Canvas release
  View.CanvasReleased ->
    noCmd (State.setPointerUp state)
  
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
  
  -- Animation frame tick (run physics simulation + confetti)
  View.Tick dt ->
    -- dt is delta time in milliseconds, convert to seconds
    let
      dtSeconds = dt / 1000.0
      -- Run physics simulation step
      simulated = State.simulatePaint dtSeconds state
      -- Update confetti animation
      withConfetti = State.updateEasterEggConfetti dtSeconds simulated
    in
      noCmd withConfetti
  
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
  
  -- Toggle layer visibility
  View.LayerVisibilityToggled lid ->
    noCmd (State.toggleLayerVisibility lid state)
  
  -- Delete layer
  View.DeleteLayer lid ->
    let
      withRemoved = State.removeLayer lid state
      withHistory = State.pushHistory "Delete layer" withRemoved
    in
      noCmd withHistory
  
  -- Move layer up in stack
  View.MoveLayerUp lid ->
    let
      withMoved = State.moveLayerUp lid state
      withHistory = State.pushHistory "Move layer up" withMoved
    in
      noCmd withHistory
  
  -- Move layer down in stack
  View.MoveLayerDown lid ->
    let
      withMoved = State.moveLayerDown lid state
      withHistory = State.pushHistory "Move layer down" withMoved
    in
      noCmd withHistory
  
  -- Easter egg: Key press (for Konami code detection)
  View.KeyDown key ->
    let
      -- Process the key through easter egg detection
      withKey = State.processEasterEggKey key state
      -- Check if Konami code was triggered
      eeState = State.easterEggState withKey
    in
      if Easter.konamiTriggered eeState
        then 
          -- KONAMI CODE TRIGGERED! Explode confetti from center!
          let
            centerX = 960.0  -- Canvas center X
            centerY = 540.0  -- Canvas center Y
            withConfetti = State.triggerEasterEggConfetti centerX centerY withKey
            -- Reset the konami detection so it can trigger again
            withReset = State.resetEasterEggs withConfetti
          in
            noCmd withReset
        else
          noCmd withKey
  
  -- Keyboard shortcuts with modifiers (Ctrl+Z, Ctrl+Shift+Z, etc.)
  View.KeyboardShortcut shortcut ->
    -- Handle standard keyboard shortcuts
    if shortcut.ctrlKey && not shortcut.shiftKey && (shortcut.key == "z")
      then
        -- Ctrl+Z = Undo
        noCmd (State.undo state)
    else if shortcut.ctrlKey && shortcut.shiftKey && (shortcut.key == "z" || shortcut.key == "Z")
      then
        -- Ctrl+Shift+Z = Redo
        noCmd (State.redo state)
    else if shortcut.ctrlKey && not shortcut.shiftKey && (shortcut.key == "y")
      then
        -- Ctrl+Y = Redo (Windows convention)
        noCmd (State.redo state)
    else if shortcut.ctrlKey && (shortcut.key == "s" || shortcut.key == "S")
      then
        -- Ctrl+S = Export PNG
        transition state (Log "EXPORT:png")
    else if shortcut.ctrlKey && shortcut.shiftKey && (shortcut.key == "e" || shortcut.key == "E")
      then
        -- Ctrl+Shift+E = Export SVG
        transition state (Log "EXPORT:svg")
    else if shortcut.key == "Escape"
      then
        -- Escape = Reset viewport
        noCmd (State.resetViewport state)
    else if shortcut.key == " "
      then
        -- Space = Toggle pan tool (temporarily)
        noCmd state
    else
      -- Pass unhandled shortcuts to easter egg detector
      noCmd (State.processEasterEggKey shortcut.key state)
  
  -- Easter egg: Device motion (for shake detection)
  View.DeviceMotion motion ->
    let
      -- Process the motion through shake detector
      withMotion = State.processEasterEggMotion motion state
      -- Check if shake was triggered
      eeState = State.easterEggState withMotion
    in
      if Easter.shakeTriggered eeState
        then
          -- SHAKE DETECTED! Clear canvas etch-a-sketch style!
          let
            cleared = State.clearActiveLayer withMotion
            withHistory = State.pushHistory "Shake clear" cleared
            -- Reset shake detection so it can trigger again
            withReset = State.resetEasterEggs withHistory
          in
            noCmd withReset
        else
          noCmd withMotion
  
  -- Viewport gesture: Pan
  View.ViewportPan dx dy ->
    noCmd (State.panViewport dx dy state)
  
  -- Viewport gesture: Zoom
  View.ViewportZoom scaleFactor ->
    noCmd (State.zoomViewport scaleFactor state)
  
  -- Viewport gesture: Zoom at point (pinch center stays fixed)
  View.ViewportZoomAt x y scaleFactor ->
    noCmd (State.zoomViewportAt x y scaleFactor state)
  
  -- Viewport gesture: Rotate
  View.ViewportRotate deltaRotation ->
    noCmd (State.rotateViewport deltaRotation state)
  
  -- Viewport: Reset to initial state
  View.ViewportReset ->
    noCmd (State.resetViewport state)
  
  -- Two-finger gesture: Process touch points for pan/pinch/rotate
  View.TwoFingerTouch touch ->
    let
      p1 = { x: touch.x1, y: touch.y1 }
      p2 = { x: touch.x2, y: touch.y2 }
    in
      noCmd (State.processTwoFingerGesture p1 p2 state)
  
  -- Two-finger gesture ended
  View.TwoFingerEnd ->
    noCmd (State.endTwoFingerGesture state)
  
  -- Export canvas (PNG or SVG)
  -- Triggers export via command that will be executed by the runtime.
  -- The Log command with special prefix "EXPORT:" is interpreted by the runtime.
  View.ExportCanvas format ->
    transition state (Log ("EXPORT:" <> format))

-- | Check if painting is currently active (brush tool selected).
isPaintingActive :: CanvasState -> Boolean
isPaintingActive state =
  let tool = State.currentTool state
  in tool == BrushTool

-- | Map preset name string to PaintPreset.
-- |
-- | Handles case-insensitive matching for UI flexibility.
presetFromName :: String -> PaintPreset
presetFromName name = case name of
  "watercolor" -> Watercolor
  "Watercolor" -> Watercolor
  "oil" -> OilPaint
  "Oil" -> OilPaint
  "Oil Paint" -> OilPaint
  "acrylic" -> Acrylic
  "Acrylic" -> Acrylic
  "gouache" -> Gouache
  "Gouache" -> Gouache
  "ink" -> Ink
  "Ink" -> Ink
  "honey" -> Honey
  "Honey" -> Honey
  _ -> Watercolor  -- Default fallback

-- | Map WetMediaType to PaintPreset.
-- |
-- | Converts from Hydrogen's brush schema to Canvas paint presets.
presetFromWetMedia :: WetMedia.WetMediaType -> PaintPreset
presetFromWetMedia mediaType = case mediaType of
  WetMedia.Watercolor -> Watercolor
  WetMedia.OilPaint -> OilPaint
  WetMedia.Acrylic -> Acrylic
  WetMedia.Gouache -> Gouache
  WetMedia.Ink -> Ink
  WetMedia.WetIntoWet -> Watercolor  -- WetIntoWet is a watercolor technique

-- ═════════════════════════════════════════════════════════════════════════════
--                                                             // subscriptions
-- ═════════════════════════════════════════════════════════════════════════════

-- | Active subscriptions based on current state.
-- |
-- | ## Always Active
-- | - Animation frame (physics simulation runs continuously when playing)
-- | - Device orientation (gravity responds to device tilt)
-- |
-- | ## Pointer Events (Preferred)
-- | - PointerEvents provide unified stylus/touch/mouse with pressure/tilt
-- |
-- | ## Legacy Events (Fallback)
-- | - Touch events for older browsers
-- | - Mouse events for desktop fallback
subscriptionsCanvas :: CanvasState -> Array (Sub Msg)
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
    
    -- Pointer events (preferred - includes stylus pressure/tilt)
    pointerSubs =
      [ OnPointerDown handlePointerDown
      , OnPointerMove handlePointerMove
      , OnPointerUp handlePointerUp
      ]
    
    -- Legacy touch events for painting (fallback)
    touchSubs = 
      [ OnTouchStart handleTouchStart
      , OnTouchMove handleTouchMove
      , OnTouchEnd handleTouchEnd
      ]
    
    -- Legacy mouse events for painting (desktop fallback)
    mouseSubs =
      [ OnMouseDown handleMouseDown
      , OnMouseMove handleMouseMove
      , OnMouseUp handleMouseUp
      ]
    
    -- Easter egg subscriptions (always active)
    -- Keyboard for Konami code detection
    keyboardSub = [ OnKeyDown handleKeyDown ]
    
    -- Device motion for shake detection
    motionSub = [ OnDeviceMotion handleDeviceMotion ]
  in
    -- Use pointer events as primary, keep legacy for compatibility
    -- Add easter egg subs (keyboard, device motion)
    animationSub <> orientationSub <> pointerSubs <> touchSubs <> mouseSubs <> keyboardSub <> motionSub

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

-- ═════════════════════════════════════════════════════════════════════════════
--                                                  // easter egg event handlers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Handle key press (for Konami code detection).
-- |
-- | Listens for arrow keys and letter keys to detect the Konami code:
-- | ↑↑↓↓←→←→BA
handleKeyDown :: String -> Msg
handleKeyDown key = View.KeyDown key

-- | Handle device motion (for shake detection).
-- |
-- | Converts DeviceMotionEvent to our simpler motion record.
-- | Uses acceleration WITHOUT gravity for shake detection
-- | (we want to detect rapid movement, not the phone's orientation).
handleDeviceMotion :: DeviceMotionEvent -> Msg
handleDeviceMotion event =
  View.DeviceMotion
    { accelerationX: event.accelerationX
    , accelerationY: event.accelerationY
    , accelerationZ: event.accelerationZ
    , timestamp: event.interval  -- Use interval as rough timestamp
    }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                   // pointer event handlers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Handle pointer down (stylus/touch/mouse with full data).
-- |
-- | Converts PointerEvent to StylusInput with:
-- | - Position (x, y)
-- | - Pressure (0.0-1.0)
-- | - Tilt X/Y (-90 to 90 degrees)
-- | - Pointer type ("pen", "touch", "mouse")
handlePointerDown :: PointerEvent -> Msg
handlePointerDown event =
  View.PointerDown (pointerToStylus event)

-- | Handle pointer move (stylus/touch/mouse move with full data).
handlePointerMove :: PointerEvent -> Msg
handlePointerMove event =
  View.PointerMoved (pointerToStylus event)

-- | Handle pointer up (stylus/touch/mouse lifted).
handlePointerUp :: PointerEvent -> Msg
handlePointerUp _event = View.PointerUp

-- | Convert PointerEvent to StylusInput.
-- |
-- | Extracts all relevant stylus data from the browser event:
-- | - For stylus: full pressure (0.0-1.0) and tilt data
-- | - For touch: pressure from force, no tilt
-- | - For mouse: pressure defaults to 0.5, no tilt
pointerToStylus :: PointerEvent -> StylusInput
pointerToStylus event =
  { x: event.x
  , y: event.y
  , pressure: event.pressure
  , tiltX: event.tiltX
  , tiltY: event.tiltY
  , pointerType: event.pointerType
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                   // legacy event handlers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Handle touch start (begin painting or two-finger gesture).
-- |
-- | Detects multi-touch and routes appropriately:
-- | - Single touch: Paint
-- | - Two fingers: Pan/Pinch/Rotate viewport
handleTouchStart :: TouchEvent -> Msg
handleTouchStart event =
  case touchCount event of
    2 -> handleTwoFingerTouch event
    _ -> case Array.head event.changedTouches of
           Just touch -> View.CanvasTouched touch.x touch.y
           Nothing -> View.CanvasReleased

-- | Handle touch move (continue painting or two-finger gesture).
handleTouchMove :: TouchEvent -> Msg
handleTouchMove event =
  case touchCount event of
    2 -> handleTwoFingerTouch event
    _ -> case Array.head event.changedTouches of
           Just touch -> View.CanvasMoved touch.x touch.y
           Nothing -> View.CanvasReleased

-- | Handle touch end (stop painting or end gesture).
handleTouchEnd :: TouchEvent -> Msg
handleTouchEnd event =
  -- If we had two fingers and now have fewer, end the gesture
  if touchCount event < 2
    then View.TwoFingerEnd
    else View.CanvasReleased

-- | Count current touches.
touchCount :: TouchEvent -> Int
touchCount event = Array.length event.touches

-- | Handle two-finger touch for pan/pinch/rotate.
handleTwoFingerTouch :: TouchEvent -> Msg
handleTwoFingerTouch event =
  case Array.head event.touches of
    Nothing -> View.CanvasReleased
    Just t1 -> case Array.index event.touches 1 of
      Nothing -> View.CanvasReleased
      Just t2 -> View.TwoFingerTouch
        { x1: t1.x, y1: t1.y
        , x2: t2.x, y2: t2.y
        }

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
  -- Pass particle extraction function for GPU rendering
  -- Pass View.Tick constructor for proper message creation (no unsafe coercion)
  -- Pass KeyboardShortcut constructor for keyboard shortcuts with modifiers
  let getParticlesFromState = \state -> Paint.allParticles (State.paintSystem state)
  let toKbShortcutMsg = \ks -> View.KeyboardShortcut
        { key: ks.key
        , ctrlKey: ks.ctrlKey
        , shiftKey: ks.shiftKey
        , altKey: ks.altKey
        }
  DOM.mount "#app" canvasApp updateCanvas View.view initCanvas getParticlesFromState View.Tick toKbShortcutMsg
  
  -- Log completion and return unit
  log "Canvas Builder ready!"
  pure unit

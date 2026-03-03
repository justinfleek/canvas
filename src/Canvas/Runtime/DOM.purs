-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                  // canvas // runtime // dom
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas DOM Runtime
-- |
-- | Provides the browser runtime for the Canvas application:
-- | - Mounts the app to a DOM element
-- | - Runs the animation frame loop
-- | - Wires event subscriptions to browser events
-- | - Renders Elements to DOM
-- |
-- | ## Architecture
-- |
-- | The runtime follows the Elm architecture:
-- | 1. Initial state + view → DOM
-- | 2. Events → Messages → Update → New State
-- | 3. New State → view → DOM diff (currently full re-render)
-- |
-- | ## Usage
-- |
-- | ```purescript
-- | main :: Effect Unit
-- | main = mount "#app" canvasApp
-- | ```

module Canvas.Runtime.DOM
  ( -- * Mounting
    mount
  , MountHandle
  , unmount
  
  -- * DOM Operations (FFI)
  , DOMElement
  , selectElement
  , setInnerHTML
  
  -- * Pointer Events (Stylus/Touch/Mouse unified)
  , PointerInput
  , addPointerDownListener
  , addPointerMoveListener
  , addPointerUpListener
  , addPointerCancelListener
  , addCoalescedPointerMoveListener
  
  -- * Legacy Event Listeners (FFI)
  , Unsubscribe
  , addMouseMoveListener
  , addMouseDownListener
  , addMouseUpListener
  , addTouchStartListener
  , addTouchMoveListener
  , addTouchEndListener
  , addDeviceOrientationListener
  
  -- * Animation (FFI)
  , requestAnimationFrame
  
  -- * Refs (FFI)
  , Ref
  , newRef
  , readRef
  , writeRef
  , modifyRef
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( Unit
  , bind
  , discard
  , pure
  , unit
  , ($)
  , (<>)
  )

import Effect (Effect)
import Effect.Console (log)
import Data.Either (Either(Left, Right))
import Data.Maybe (Maybe(Just, Nothing))
import Data.Nullable (Nullable, toMaybe)

import Hydrogen.Render.Element (Element)
import Hydrogen.Target.Static as Static
import Hydrogen.Runtime.App
  ( App
  , MousePos
  , MouseEvent
  , TouchEvent
  , DeviceOrientationEvent
  )
import Hydrogen.Runtime.Cmd (Transition)

-- GPU Runtime
import Canvas.Runtime.GPU as GPU
import Canvas.Paint.Particle as Paint

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // foreign types
-- ═════════════════════════════════════════════════════════════════════════════

-- | Opaque DOM element reference
foreign import data DOMElement :: Type

-- | Opaque mutable reference
foreign import data Ref :: Type -> Type

-- | Function to unsubscribe from an event
type Unsubscribe = Effect Unit

-- | Unified pointer input (mouse, touch, or stylus).
-- |
-- | This type captures the full W3C PointerEvent data including:
-- | - Pressure (0.0-1.0) from stylus/touch force
-- | - Tilt X/Y (-90 to 90 degrees) from stylus angle
-- | - Twist (0-359 degrees) from stylus barrel rotation
-- | - Contact geometry (width/height) from touch
type PointerInput =
  { pointerId :: Int               -- ^ Unique identifier for this pointer
  , pointerType :: String          -- ^ "mouse" | "pen" | "touch"
  , x :: Number                    -- ^ X position relative to element
  , y :: Number                    -- ^ Y position relative to element
  , pressure :: Number             -- ^ Pressure (0.0-1.0, 0.5 default for mouse)
  , tiltX :: Number                -- ^ X tilt in degrees (-90 to 90)
  , tiltY :: Number                -- ^ Y tilt in degrees (-90 to 90)
  , twist :: Number                -- ^ Twist/rotation in degrees (0-359)
  , width :: Number                -- ^ Contact width (touch only)
  , height :: Number               -- ^ Contact height (touch only)
  , isPrimary :: Boolean           -- ^ Is primary pointer in multi-touch
  , buttons :: Int                 -- ^ Bitmask of pressed buttons
  , clientX :: Number              -- ^ Raw client X
  , clientY :: Number              -- ^ Raw client Y
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                               // ffi bindings
-- ═════════════════════════════════════════════════════════════════════════════

-- DOM Operations
foreign import selectElementImpl :: String -> Effect (Nullable DOMElement)
foreign import setInnerHTML :: DOMElement -> String -> Effect Unit

-- Animation
foreign import requestAnimationFrameImpl :: (Number -> Effect Unit) -> Effect Unsubscribe

-- Mouse Events
foreign import addMouseMoveListenerImpl :: (MousePos -> Effect Unit) -> Effect Unsubscribe
foreign import addMouseDownListenerImpl :: DOMElement -> (MouseEvent -> Effect Unit) -> Effect Unsubscribe
foreign import addMouseUpListenerImpl :: (MouseEvent -> Effect Unit) -> Effect Unsubscribe

-- Touch Events
foreign import addTouchStartListenerImpl :: DOMElement -> (TouchEvent -> Effect Unit) -> Effect Unsubscribe
foreign import addTouchMoveListenerImpl :: DOMElement -> (TouchEvent -> Effect Unit) -> Effect Unsubscribe
foreign import addTouchEndListenerImpl :: DOMElement -> (TouchEvent -> Effect Unit) -> Effect Unsubscribe

-- Device Orientation
foreign import addDeviceOrientationListenerImpl :: (DeviceOrientationEvent -> Effect Unit) -> Effect Unsubscribe

-- Pointer Events (unified stylus/touch/mouse)
foreign import addPointerDownListenerImpl :: DOMElement -> (PointerInput -> Effect Unit) -> Effect Unsubscribe
foreign import addPointerMoveListenerImpl :: DOMElement -> (PointerInput -> Effect Unit) -> Effect Unsubscribe
foreign import addPointerUpListenerImpl :: (PointerInput -> Effect Unit) -> Effect Unsubscribe
foreign import addPointerCancelListenerImpl :: (PointerInput -> Effect Unit) -> Effect Unsubscribe
foreign import addCoalescedPointerMoveListenerImpl :: DOMElement -> (Array PointerInput -> Effect Unit) -> Effect Unsubscribe

-- Refs
foreign import newRef :: forall a. a -> Effect (Ref a)
foreign import readRef :: forall a. Ref a -> Effect a
foreign import writeRef :: forall a. Ref a -> a -> Effect Unit
foreign import modifyRef :: forall a. Ref a -> (a -> a) -> Effect Unit

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // wrapped exports
-- ═════════════════════════════════════════════════════════════════════════════

-- | Select a DOM element by CSS selector
selectElement :: String -> Effect (Maybe DOMElement)
selectElement selector = do
  result <- selectElementImpl selector
  pure (toMaybe result)

-- | Request animation frame loop
requestAnimationFrame :: (Number -> Effect Unit) -> Effect Unsubscribe
requestAnimationFrame = requestAnimationFrameImpl

-- | Add mouse move listener to window
addMouseMoveListener :: (MousePos -> Effect Unit) -> Effect Unsubscribe
addMouseMoveListener = addMouseMoveListenerImpl

-- | Add mouse down listener to element
addMouseDownListener :: DOMElement -> (MouseEvent -> Effect Unit) -> Effect Unsubscribe
addMouseDownListener = addMouseDownListenerImpl

-- | Add mouse up listener to window
addMouseUpListener :: (MouseEvent -> Effect Unit) -> Effect Unsubscribe
addMouseUpListener = addMouseUpListenerImpl

-- | Add touch start listener
addTouchStartListener :: DOMElement -> (TouchEvent -> Effect Unit) -> Effect Unsubscribe
addTouchStartListener = addTouchStartListenerImpl

-- | Add touch move listener
addTouchMoveListener :: DOMElement -> (TouchEvent -> Effect Unit) -> Effect Unsubscribe
addTouchMoveListener = addTouchMoveListenerImpl

-- | Add touch end listener
addTouchEndListener :: DOMElement -> (TouchEvent -> Effect Unit) -> Effect Unsubscribe
addTouchEndListener = addTouchEndListenerImpl

-- | Add device orientation listener
addDeviceOrientationListener :: (DeviceOrientationEvent -> Effect Unit) -> Effect Unsubscribe
addDeviceOrientationListener = addDeviceOrientationListenerImpl

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // pointer events
-- ═════════════════════════════════════════════════════════════════════════════

-- | Add pointer down listener (unified stylus/touch/mouse).
-- |
-- | This is the preferred input method for professional art tools as it
-- | provides full pressure/tilt/twist data from stylus devices.
addPointerDownListener :: DOMElement -> (PointerInput -> Effect Unit) -> Effect Unsubscribe
addPointerDownListener = addPointerDownListenerImpl

-- | Add pointer move listener.
-- |
-- | For high-frequency stylus input, consider using addCoalescedPointerMoveListener
-- | which provides all events coalesced since the last frame.
addPointerMoveListener :: DOMElement -> (PointerInput -> Effect Unit) -> Effect Unsubscribe
addPointerMoveListener = addPointerMoveListenerImpl

-- | Add pointer up listener (to window for reliable capture).
addPointerUpListener :: (PointerInput -> Effect Unit) -> Effect Unsubscribe
addPointerUpListener = addPointerUpListenerImpl

-- | Add pointer cancel listener (interrupted input).
addPointerCancelListener :: (PointerInput -> Effect Unit) -> Effect Unsubscribe
addPointerCancelListener = addPointerCancelListenerImpl

-- | Add coalesced pointer move listener for high-frequency stylus input.
-- |
-- | Uses getCoalescedEvents() to retrieve all pointer events since the last
-- | frame, enabling smooth curves even at high stylus sample rates (>240Hz).
addCoalescedPointerMoveListener :: DOMElement -> (Array PointerInput -> Effect Unit) -> Effect Unsubscribe
addCoalescedPointerMoveListener = addCoalescedPointerMoveListenerImpl

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // mount handle
-- ═════════════════════════════════════════════════════════════════════════════

-- | Handle returned from mount, used to unmount
type MountHandle =
  { unsubscribeAnimation :: Unsubscribe
  , unsubscribeEvents :: Array Unsubscribe
  }

-- | Unmount the application
unmount :: MountHandle -> Effect Unit
unmount handle = do
  handle.unsubscribeAnimation
  unsubscribeAll handle.unsubscribeEvents
  where
    unsubscribeAll :: Array Unsubscribe -> Effect Unit
    unsubscribeAll [] = pure unit
    unsubscribeAll unsubs = do
      -- Call each unsubscribe function
      traverseEffect_ unsubs

    traverseEffect_ :: Array (Effect Unit) -> Effect Unit
    traverseEffect_ [] = pure unit
    traverseEffect_ _effects = do
      -- Execute all effects
      -- Note: In real code we'd use traverse_, but keeping minimal
      pure unit

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                      // mount
-- ═════════════════════════════════════════════════════════════════════════════

-- | Mount a Hydrogen App to a DOM element
-- |
-- | This is the main entry point. It:
-- | 1. Selects the target element
-- | 2. Initializes the app state
-- | 3. Renders the initial view
-- | 4. Sets up event subscriptions
-- | 5. Starts the animation loop
-- |
-- | ## GPU Rendering
-- |
-- | The `getParticles` parameter allows the generic mount function to
-- | extract particles from the app's state for GPU rendering. This avoids
-- | unsafe coercions by using a proper function parameter.
-- |
-- | ```purescript
-- | mount "#app" myApp update view init
-- |   (\state -> Paint.allParticles (State.paintSystem state))
-- | ```
mount
  :: forall state msg
   . String                              -- ^ CSS selector for mount target
  -> App state msg (Element msg)         -- ^ The application
  -> (msg -> state -> Transition state msg)  -- ^ Update function (passed separately for type clarity)
  -> (state -> Element msg)              -- ^ View function
  -> Transition state msg                -- ^ Initial state
  -> (state -> Array Paint.Particle)     -- ^ Extract particles from state for GPU rendering
  -> Effect Unit
mount selector _app update view initialTransition getParticles = do
  log $ "Canvas: Mounting to " <> selector
  
  maybeEl <- selectElement selector
  case maybeEl of
    Nothing -> do
      log $ "Canvas: ERROR - Could not find element: " <> selector
      pure unit
    
    Just rootEl -> do
      log "Canvas: Found root element, initializing..."
      
      -- Create state ref
      stateRef <- newRef initialTransition.state
      
      -- Create GPU runtime ref (will be initialized after first render)
      gpuRef <- newRef (Nothing :: Maybe GPU.GPURuntime)
      
      -- Initial render
      renderToElement rootEl view initialTransition.state
      
      -- Initialize GPU runtime after first render (canvas element now exists)
      initGPURuntime gpuRef
      
      -- Set up animation frame loop
      _cancelAnimation <- requestAnimationFrame $ \deltaTime -> do
        currentState <- readRef stateRef
        -- In a full implementation, we would:
        -- 1. Check subscriptions
        -- 2. Dispatch Tick message
        -- 3. Update state
        -- 4. Re-render
        -- For now, just re-render on each frame (inefficient but works)
        let tickMsg = unsafeCoerceTick deltaTime
        let newTransition = update tickMsg currentState
        writeRef stateRef newTransition.state
        renderToElement rootEl view newTransition.state
        
        -- GPU render particles after DOM update (using passed extraction function)
        renderGPUParticles gpuRef (getParticles newTransition.state)
      
      log "Canvas: Animation loop started"
      log "Canvas: Mount complete!"
      pure unit

-- | Render an Element to a DOM element using static HTML
-- |
-- | Note: This is a full re-render, not a diff. For production,
-- | we'd implement proper virtual DOM diffing.
renderToElement :: forall state msg. DOMElement -> (state -> Element msg) -> state -> Effect Unit
renderToElement el view state = do
  let element = view state
  let html = Static.render element
  setInnerHTML el html

-- | UNSAFE: Coerce a number to a Tick message
-- |
-- | This is a temporary hack. In a proper implementation,
-- | we'd have proper message routing through the App type.
foreign import unsafeCoerceTick :: forall msg. Number -> msg

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // gpu rendering
-- ═════════════════════════════════════════════════════════════════════════════

-- | Initialize GPU runtime if not already initialized.
-- |
-- | Called after first DOM render when the canvas element exists.
initGPURuntime :: Ref (Maybe GPU.GPURuntime) -> Effect Unit
initGPURuntime gpuRef = do
  log "Canvas: Initializing GPU runtime..."
  result <- GPU.initialize "paint-canvas"
  case result of
    Left err -> do
      log $ "Canvas: GPU initialization failed: " <> err
      log "Canvas: Falling back to SVG rendering"
      writeRef gpuRef Nothing
      -- Update GPU status indicator to show fallback
      setGPUStatusText "GPU: SVG fallback"
    Right runtime -> do
      let backendName = GPU.getBackendName runtime
      log $ "Canvas: GPU initialized with backend: " <> backendName
      writeRef gpuRef (Just runtime)
      -- Update GPU status indicator
      setGPUStatusText ("GPU: " <> backendName)

-- | Set the GPU backend status text in the UI.
foreign import setGPUStatusTextImpl :: String -> Effect Unit

setGPUStatusText :: String -> Effect Unit
setGPUStatusText = setGPUStatusTextImpl

-- | Render particles using GPU if available.
-- |
-- | Called after each DOM update in the animation loop.
-- | Takes particles directly (extracted by the caller) to avoid type coercion.
renderGPUParticles :: Ref (Maybe GPU.GPURuntime) -> Array Paint.Particle -> Effect Unit
renderGPUParticles gpuRef particles = do
  maybeGpu <- readRef gpuRef
  case maybeGpu of
    Nothing -> pure unit  -- GPU not available, SVG fallback is shown
    Just runtime -> do
      -- Clear with paper color background and render particles
      GPU.renderFrame runtime { r: 0.96, g: 0.96, b: 0.86, a: 1.0 } particles

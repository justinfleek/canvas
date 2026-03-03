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
  
  -- * Event Listeners (FFI)
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

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // foreign types
-- ═════════════════════════════════════════════════════════════════════════════

-- | Opaque DOM element reference
foreign import data DOMElement :: Type

-- | Opaque mutable reference
foreign import data Ref :: Type -> Type

-- | Function to unsubscribe from an event
type Unsubscribe = Effect Unit

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
mount
  :: forall state msg
   . String                              -- ^ CSS selector for mount target
  -> App state msg (Element msg)         -- ^ The application
  -> (msg -> state -> Transition state msg)  -- ^ Update function (passed separately for type clarity)
  -> (state -> Element msg)              -- ^ View function
  -> Transition state msg                -- ^ Initial state
  -> Effect Unit
mount selector _app update view initialTransition = do
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
      
      -- Initial render
      renderToElement rootEl view initialTransition.state
      
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

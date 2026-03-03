-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                // canvas // runtime // input
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas Input Runtime — Touch, stylus, and haptic feedback for painting.
-- |
-- | ## Professional Input Support
-- |
-- | This module provides complete input handling for:
-- | - **Touch**: Multi-touch with pressure (Force Touch on iOS)
-- | - **Stylus/Pen**: Pressure, tilt, twist (Wacom, Apple Pencil, Surface Pen)
-- | - **Mouse**: Standard mouse with simulated pressure
-- | - **Haptics**: Vibration feedback for paint events
-- |
-- | ## Pointer Events API (W3C)
-- |
-- | Uses PointerEvent for unified input:
-- | - pressure: 0.0-1.0 (pen force, touch force)
-- | - tiltX/tiltY: -90 to 90 degrees (pen angle)
-- | - twist: 0-359 degrees (pen rotation)
-- | - pointerType: "mouse" | "pen" | "touch"
-- |
-- | ## Dependencies
-- | - Effect
-- | - Hydrogen.Schema.Gestural.Pointer
-- | - Hydrogen.Schema.Haptic.Feedback

module Canvas.Runtime.Input
  ( -- * Pointer Events
    PointerInput
  , PointerInputType(MouseInput, PenInput, TouchInput)
  , onPointerDown
  , onPointerMove
  , onPointerUp
  , onPointerCancel
  
  -- * Stylus/Pen Specifics
  , PenState
  , penState
  , penPressure
  , penTiltX
  , penTiltY
  , penTwist
  , hasPenPressure
  , hasPenTilt
  
  -- * Touch Specifics
  , TouchState
  , touchState
  , touchPressure
  , touchRadius
  , touchForce
  
  -- * Haptic Feedback
  , HapticType
      ( LightTap
      , MediumTap
      , HeavyTap
      , PaintDab
      , PaintStrokeStart
      , PaintStrokeEnd
      , PaintSlide
      , CanvasTexture
      , Warning
      , ErrorBuzz
      )
  , triggerHaptic
  , triggerPaintHaptic
  , vibrate
  , supportsHaptics
  
  -- * Input Configuration
  , InputConfig
  , defaultInputConfig
  , setPressureCurve
  , setHapticsEnabled
  , setSimulatePressure
  
  -- * Pressure Curves
  , PressureCurve(Linear, Soft, Firm, SCurve)
  , applyPressureCurve
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( class Eq
  , class Ord
  , class Show
  , Unit
  , bind
  , discard
  , map
  , pure
  , show
  , unit
  , ($)
  , (*)
  , (+)
  , (-)
  , (/)
  , (<)
  , (<=)
  , (<>)
  , (==)
  , (>)
  , (>=)
  , max
  , min
  )

import Effect (Effect)
import Data.Maybe (Maybe(Just, Nothing))
import Data.Int (round)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // pointer input
-- ═════════════════════════════════════════════════════════════════════════════

-- | Unified pointer input (mouse, pen, or touch).
-- |
-- | Normalized representation of any pointing device.
type PointerInput =
  { pointerId :: Int               -- ^ Unique identifier for this pointer
  , pointerType :: PointerInputType -- ^ Device type
  , x :: Number                    -- ^ X position relative to element
  , y :: Number                    -- ^ Y position relative to element
  , pressure :: Number             -- ^ Pressure (0.0-1.0)
  , tiltX :: Number                -- ^ X tilt in degrees (-90 to 90)
  , tiltY :: Number                -- ^ Y tilt in degrees (-90 to 90)
  , twist :: Number                -- ^ Twist/rotation in degrees (0-359)
  , width :: Number                -- ^ Contact width (touch only)
  , height :: Number               -- ^ Contact height (touch only)
  , isPrimary :: Boolean           -- ^ Is primary pointer in multi-touch
  , buttons :: Int                 -- ^ Bitmask of pressed buttons
  }

-- | Type of pointing device.
data PointerInputType
  = MouseInput     -- ^ Mouse or trackpad
  | PenInput       -- ^ Stylus, pen, Apple Pencil
  | TouchInput     -- ^ Finger touch

derive instance eqPointerInputType :: Eq PointerInputType
derive instance ordPointerInputType :: Ord PointerInputType

instance showPointerInputType :: Show PointerInputType where
  show MouseInput = "mouse"
  show PenInput = "pen"
  show TouchInput = "touch"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // pen state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Complete pen/stylus state.
-- |
-- | Captures all pen-specific attributes for professional drawing.
type PenState =
  { pressure :: Number     -- ^ 0.0-1.0 force applied
  , tiltX :: Number        -- ^ X axis tilt (-90 to 90 degrees)
  , tiltY :: Number        -- ^ Y axis tilt (-90 to 90 degrees)
  , twist :: Number        -- ^ Barrel rotation (0-359 degrees)
  , hasPressure :: Boolean -- ^ Device supports pressure
  , hasTilt :: Boolean     -- ^ Device supports tilt
  , hasTwist :: Boolean    -- ^ Device supports twist
  }

-- | Create pen state from pointer input.
penState :: PointerInput -> PenState
penState input =
  { pressure: input.pressure
  , tiltX: input.tiltX
  , tiltY: input.tiltY
  , twist: input.twist
  , hasPressure: input.pressure > 0.0 && input.pressure < 1.0
  , hasTilt: input.tiltX /= 0.0 || input.tiltY /= 0.0
  , hasTwist: input.twist /= 0.0
  }

-- | Get pen pressure (0.0-1.0).
penPressure :: PenState -> Number
penPressure ps = ps.pressure

-- | Get pen X tilt.
penTiltX :: PenState -> Number
penTiltX ps = ps.tiltX

-- | Get pen Y tilt.
penTiltY :: PenState -> Number
penTiltY ps = ps.tiltY

-- | Get pen twist/rotation.
penTwist :: PenState -> Number
penTwist ps = ps.twist

-- | Check if pen supports pressure.
hasPenPressure :: PenState -> Boolean
hasPenPressure ps = ps.hasPressure

-- | Check if pen supports tilt.
hasPenTilt :: PenState -> Boolean
hasPenTilt ps = ps.hasTilt

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // touch state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Touch-specific state.
type TouchState =
  { pressure :: Number     -- ^ Touch force (0.0-1.0), if supported
  , radiusX :: Number      -- ^ Contact ellipse X radius (pixels)
  , radiusY :: Number      -- ^ Contact ellipse Y radius (pixels)
  , force :: Number        -- ^ Force Touch / 3D Touch value
  }

-- | Create touch state from pointer input.
touchState :: PointerInput -> TouchState
touchState input =
  { pressure: input.pressure
  , radiusX: input.width / 2.0
  , radiusY: input.height / 2.0
  , force: input.pressure
  }

-- | Get touch pressure.
touchPressure :: TouchState -> Number
touchPressure ts = ts.pressure

-- | Get average touch radius.
touchRadius :: TouchState -> Number
touchRadius ts = (ts.radiusX + ts.radiusY) / 2.0

-- | Get force touch value.
touchForce :: TouchState -> Number
touchForce ts = ts.force

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // haptic feedback
-- ═════════════════════════════════════════════════════════════════════════════

-- | Types of haptic feedback for painting.
data HapticType
  = LightTap          -- ^ Subtle tap for UI interaction
  | MediumTap         -- ^ Standard button press
  | HeavyTap          -- ^ Strong confirmation
  | PaintDab          -- ^ Single paint dab
  | PaintStrokeStart  -- ^ Beginning a paint stroke
  | PaintStrokeEnd    -- ^ Lifting pen/finger
  | PaintSlide        -- ^ Paint sliding/flowing (continuous)
  | CanvasTexture     -- ^ Textured surface feel
  | Warning           -- ^ Attention needed
  | ErrorBuzz         -- ^ Something went wrong

derive instance eqHapticType :: Eq HapticType

instance showHapticType :: Show HapticType where
  show LightTap = "LightTap"
  show MediumTap = "MediumTap"
  show HeavyTap = "HeavyTap"
  show PaintDab = "PaintDab"
  show PaintStrokeStart = "PaintStrokeStart"
  show PaintStrokeEnd = "PaintStrokeEnd"
  show PaintSlide = "PaintSlide"
  show CanvasTexture = "CanvasTexture"
  show Warning = "Warning"
  show ErrorBuzz = "ErrorBuzz"

-- | Trigger haptic feedback.
-- |
-- | Uses navigator.vibrate on supported devices.
-- | Falls back gracefully if unsupported.
triggerHaptic :: HapticType -> Effect Unit
triggerHaptic hapticType = do
  let pattern = hapticPattern hapticType
  vibratePattern pattern

-- | Trigger paint-specific haptic based on pressure.
-- |
-- | Pressure affects the intensity of the haptic feedback.
-- | High pressure = stronger vibration.
triggerPaintHaptic :: Number -> HapticType -> Effect Unit
triggerPaintHaptic pressure hapticType = do
  let basePattern = hapticPattern hapticType
  let scaledPattern = scalePattern pressure basePattern
  vibratePattern scaledPattern

-- | Get vibration pattern for haptic type.
-- |
-- | Pattern is array of [vibrate, pause, vibrate, pause, ...] in milliseconds.
hapticPattern :: HapticType -> Array Int
hapticPattern LightTap = [10]
hapticPattern MediumTap = [20]
hapticPattern HeavyTap = [35]
hapticPattern PaintDab = [15]
hapticPattern PaintStrokeStart = [25]
hapticPattern PaintStrokeEnd = [10]
hapticPattern PaintSlide = [5, 10, 5, 10, 5]  -- Subtle repeating
hapticPattern CanvasTexture = [3, 5, 3, 5, 3, 5]  -- Fine texture
hapticPattern Warning = [50, 30, 50]  -- Double pulse
hapticPattern ErrorBuzz = [100, 50, 100, 50, 100]  -- Triple buzz

-- | Scale vibration pattern by pressure.
-- |
-- | Pressure 0.0-1.0 maps to 0.5-1.5x duration.
scalePattern :: Number -> Array Int -> Array Int
scalePattern pressure pattern =
  let scale = 0.5 + pressure  -- 0.5x to 1.5x
  in map (\ms -> round (scale * toNumber ms)) pattern
  where
    toNumber :: Int -> Number
    toNumber n = fromIntImpl n

-- | Simple vibration (single pulse).
vibrate :: Int -> Effect Unit
vibrate ms = vibratePattern [ms]

-- | Check if device supports haptic feedback.
supportsHaptics :: Effect Boolean
supportsHaptics = supportsHapticsImpl

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // input configuration
-- ═════════════════════════════════════════════════════════════════════════════

-- | Input handling configuration.
type InputConfig =
  { pressureCurve :: PressureCurve  -- ^ Pressure response curve
  , hapticsEnabled :: Boolean       -- ^ Enable haptic feedback
  , simulatePressure :: Boolean     -- ^ Simulate pressure from velocity (for mouse)
  , pressureMin :: Number           -- ^ Minimum effective pressure (0.0-1.0)
  , pressureMax :: Number           -- ^ Maximum effective pressure (0.0-1.0)
  }

-- | Default input configuration.
defaultInputConfig :: InputConfig
defaultInputConfig =
  { pressureCurve: Linear
  , hapticsEnabled: true
  , simulatePressure: true
  , pressureMin: 0.0
  , pressureMax: 1.0
  }

-- | Set pressure curve.
setPressureCurve :: PressureCurve -> InputConfig -> InputConfig
setPressureCurve curve cfg = cfg { pressureCurve = curve }

-- | Enable/disable haptics.
setHapticsEnabled :: Boolean -> InputConfig -> InputConfig
setHapticsEnabled enabled cfg = cfg { hapticsEnabled = enabled }

-- | Enable/disable pressure simulation for mouse.
setSimulatePressure :: Boolean -> InputConfig -> InputConfig
setSimulatePressure enabled cfg = cfg { simulatePressure = enabled }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // pressure curves
-- ═════════════════════════════════════════════════════════════════════════════

-- | Pressure response curves for different drawing styles.
data PressureCurve
  = Linear    -- ^ Direct 1:1 mapping
  | Soft      -- ^ Light touch responsive
  | Firm      -- ^ Requires more pressure
  | SCurve    -- ^ Natural feel (most popular)

derive instance eqPressureCurve :: Eq PressureCurve

instance showPressureCurve :: Show PressureCurve where
  show Linear = "Linear"
  show Soft = "Soft"
  show Firm = "Firm"
  show SCurve = "S-Curve"

-- | Apply pressure curve to input pressure.
-- |
-- | Maps raw 0.0-1.0 pressure through the selected curve.
applyPressureCurve :: PressureCurve -> Number -> Number
applyPressureCurve Linear p = p
applyPressureCurve Soft p = 
  -- Square root curve: light touches register more
  clamp (sqrt p)
applyPressureCurve Firm p = 
  -- Square curve: requires more pressure
  clamp (p * p)
applyPressureCurve SCurve p =
  -- Sigmoid-like: natural feel
  -- Approximation: 3p² - 2p³ (smoothstep)
  let p2 = p * p
      p3 = p2 * p
  in clamp (3.0 * p2 - 2.0 * p3)

-- | Clamp to 0.0-1.0 range.
clamp :: Number -> Number
clamp n = max 0.0 (min 1.0 n)

-- | Square root approximation (Newton's method, 3 iterations).
sqrt :: Number -> Number
sqrt n
  | n <= 0.0 = 0.0
  | otherwise = 
      let x0 = n / 2.0
          x1 = (x0 + n / x0) / 2.0
          x2 = (x1 + n / x1) / 2.0
          x3 = (x2 + n / x2) / 2.0
      in x3

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // event handlers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Add pointer down listener to element.
onPointerDown 
  :: String                           -- ^ Element selector
  -> (PointerInput -> Effect Unit)    -- ^ Handler
  -> Effect (Effect Unit)             -- ^ Returns unsubscribe function
onPointerDown selector handler = onPointerDownImpl selector handler

-- | Add pointer move listener to element.
onPointerMove
  :: String
  -> (PointerInput -> Effect Unit)
  -> Effect (Effect Unit)
onPointerMove selector handler = onPointerMoveImpl selector handler

-- | Add pointer up listener to window.
onPointerUp
  :: (PointerInput -> Effect Unit)
  -> Effect (Effect Unit)
onPointerUp handler = onPointerUpImpl handler

-- | Add pointer cancel listener to window.
onPointerCancel
  :: (PointerInput -> Effect Unit)
  -> Effect (Effect Unit)
onPointerCancel handler = onPointerCancelImpl handler

-- ═════════════════════════════════════════════════════════════════════════════
--                                                               // ffi imports
-- ═════════════════════════════════════════════════════════════════════════════

foreign import vibratePattern :: Array Int -> Effect Unit
foreign import supportsHapticsImpl :: Effect Boolean
foreign import fromIntImpl :: Int -> Number

foreign import onPointerDownImpl 
  :: String -> (PointerInput -> Effect Unit) -> Effect (Effect Unit)
foreign import onPointerMoveImpl 
  :: String -> (PointerInput -> Effect Unit) -> Effect (Effect Unit)
foreign import onPointerUpImpl 
  :: (PointerInput -> Effect Unit) -> Effect (Effect Unit)
foreign import onPointerCancelImpl 
  :: (PointerInput -> Effect Unit) -> Effect (Effect Unit)

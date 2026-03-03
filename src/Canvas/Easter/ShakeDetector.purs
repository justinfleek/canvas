-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                          // canvas // easter // shake-detector
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Shake Detection for Etch-A-Sketch Effect
-- |
-- | Detects device shaking using the accelerometer to trigger
-- | an etch-a-sketch style canvas clear animation.
-- |
-- | ## Usage
-- |
-- | ```purescript
-- | import Canvas.Easter.ShakeDetector as Shake
-- |
-- | -- In your update function:
-- | OnDeviceMotion motion ->
-- |   let shakeState = Shake.processMotion motion state.shakeState
-- |   in if Shake.isTriggered shakeState
-- |      then triggerEtchASketch state { shakeState = Shake.reset shakeState }
-- |      else noCmd state { shakeState = shakeState }
-- | ```
-- |
-- | ## How It Works
-- |
-- | 1. Track acceleration magnitude over time
-- | 2. Count "shake events" (acceleration spikes above threshold)
-- | 3. Trigger when enough shakes happen within time window

module Canvas.Easter.ShakeDetector
  ( -- * Config
    ShakeConfig
  , defaultConfig
  , setThreshold
  , setRequiredShakes
  , setTimeWindow
  
  -- * State
  , ShakeState
  , ShakeEvent
  , initialState
  , reset
  
  -- * Processing
  , processMotion
  , processAcceleration
  
  -- * Queries
  , isTriggered
  , shakeCount
  , lastMagnitude
  , isShaking
  ) where

import Prelude
  ( (+)
  , (-)
  , (*)
  , (/)
  , (>)
  , (>=)
  , (<)
  , (&&)
  , max
  , min
  )

import Data.Array (length, snoc, filter)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // shake // config
-- ═════════════════════════════════════════════════════════════════════════════

-- | Configuration for shake detection
type ShakeConfig =
  { threshold :: Number       -- ^ Acceleration threshold (m/s²) to count as shake
  , requiredShakes :: Int     -- ^ Number of shakes needed to trigger
  , timeWindow :: Number      -- ^ Time window for shakes (seconds)
  , cooldown :: Number        -- ^ Minimum time between triggers (seconds)
  , debounce :: Number        -- ^ Minimum time between shake counts (seconds)
  }

-- | Default shake detection config
-- |
-- | Requires 3 strong shakes within 1 second to trigger.
-- | Typical smartphone shake is 15-25 m/s² acceleration.
defaultConfig :: ShakeConfig
defaultConfig =
  { threshold: 15.0      -- 15 m/s² (moderate shake)
  , requiredShakes: 3    -- Need 3 shakes
  , timeWindow: 1.0      -- Within 1 second
  , cooldown: 2.0        -- Can't retrigger for 2 seconds
  , debounce: 0.1        -- 100ms between shake counts
  }

-- | Set acceleration threshold
setThreshold :: Number -> ShakeConfig -> ShakeConfig
setThreshold t cfg = cfg { threshold = max 5.0 (min 50.0 t) }

-- | Set required shake count
setRequiredShakes :: Int -> ShakeConfig -> ShakeConfig
setRequiredShakes n cfg = cfg { requiredShakes = max 1 (min 10 n) }

-- | Set time window
setTimeWindow :: Number -> ShakeConfig -> ShakeConfig
setTimeWindow t cfg = cfg { timeWindow = max 0.5 (min 5.0 t) }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // shake // state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Shake event with timestamp
type ShakeEvent =
  { timestamp :: Number    -- ^ When the shake occurred
  , magnitude :: Number    -- ^ Acceleration magnitude
  }

-- | State for tracking shakes
type ShakeState =
  { config :: ShakeConfig
  , shakes :: Array ShakeEvent    -- ^ Recent shake events
  , triggered :: Boolean          -- ^ Has shake been triggered?
  , lastTriggerTime :: Number     -- ^ Timestamp of last trigger
  , lastShakeTime :: Number       -- ^ Timestamp of last counted shake
  , currentTime :: Number         -- ^ Current timestamp
  , lastMagnitude :: Number       -- ^ Last acceleration magnitude
  }

-- | Initial state
initialState :: ShakeState
initialState = initialStateWith defaultConfig

-- | Initial state with custom config
initialStateWith :: ShakeConfig -> ShakeState
initialStateWith cfg =
  { config: cfg
  , shakes: []
  , triggered: false
  , lastTriggerTime: 0.0
  , lastShakeTime: 0.0
  , currentTime: 0.0
  , lastMagnitude: 0.0
  }

-- | Reset after triggering
reset :: ShakeState -> ShakeState
reset state =
  state
    { shakes = []
    , triggered = false
    , lastTriggerTime = state.currentTime
    }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // shake // processing
-- ═════════════════════════════════════════════════════════════════════════════

-- | Process device motion event
-- |
-- | Extracts acceleration and computes magnitude.
processMotion 
  :: { accelerationX :: Number
     , accelerationY :: Number
     , accelerationZ :: Number
     , timestamp :: Number
     }
  -> ShakeState 
  -> ShakeState
processMotion motion state =
  processAcceleration 
    motion.accelerationX 
    motion.accelerationY 
    motion.accelerationZ 
    motion.timestamp 
    state

-- | Process raw acceleration values
processAcceleration 
  :: Number  -- ^ X acceleration
  -> Number  -- ^ Y acceleration
  -> Number  -- ^ Z acceleration
  -> Number  -- ^ Timestamp
  -> ShakeState 
  -> ShakeState
processAcceleration ax ay az timestamp state =
  let
    -- Compute acceleration magnitude (ignoring gravity direction)
    magnitude = sqrt (ax * ax + ay * ay + az * az)
    
    -- Update current time
    withTime = state { currentTime = timestamp, lastMagnitude = magnitude }
    
    -- Check if in cooldown
    inCooldown = timestamp - state.lastTriggerTime < state.config.cooldown
    
    -- Check debounce (don't count shakes too close together)
    inDebounce = timestamp - state.lastShakeTime < state.config.debounce
  in
    if state.triggered then
      -- Already triggered, stay triggered until reset
      withTime
    else if inCooldown then
      -- In cooldown, don't process
      withTime
    else if magnitude > state.config.threshold && (timestamp - state.lastShakeTime >= state.config.debounce) then
      -- This is a shake! Add it
      addShake magnitude timestamp withTime
    else
      -- Not a shake, but clean up old events
      cleanupOldShakes withTime

-- | Add a shake event and check for trigger
addShake :: Number -> Number -> ShakeState -> ShakeState
addShake magnitude timestamp state =
  let
    -- Create new shake event
    newShake = { timestamp: timestamp, magnitude: magnitude }
    
    -- Add to array
    withShake = state 
      { shakes = snoc state.shakes newShake
      , lastShakeTime = timestamp
      }
    
    -- Clean up old shakes
    cleaned = cleanupOldShakes withShake
    
    -- Check if we have enough shakes to trigger
    currentShakes = length cleaned.shakes
    triggered = currentShakes >= state.config.requiredShakes
  in
    cleaned { triggered = triggered }

-- | Remove shake events outside the time window
cleanupOldShakes :: ShakeState -> ShakeState
cleanupOldShakes state =
  let
    cutoff = state.currentTime - state.config.timeWindow
    validShakes = filter (\s -> s.timestamp >= cutoff) state.shakes
  in
    state { shakes = validShakes }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // shake // queries
-- ═════════════════════════════════════════════════════════════════════════════

-- | Has shake been triggered?
isTriggered :: ShakeState -> Boolean
isTriggered state = state.triggered

-- | How many valid shakes do we have?
shakeCount :: ShakeState -> Int
shakeCount state = length state.shakes

-- | Get last acceleration magnitude
lastMagnitude :: ShakeState -> Number
lastMagnitude state = state.lastMagnitude

-- | Is device currently being shaken (above threshold)?
isShaking :: ShakeState -> Boolean
isShaking state = state.lastMagnitude > state.config.threshold

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // math // helpers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Square root approximation using Newton's method
sqrt :: Number -> Number
sqrt n
  | n < 0.0 = 0.0
  | n < 0.00001 = 0.0
  | true = 
      let x0 = n / 2.0
          x1 = (x0 + n / x0) / 2.0
          x2 = (x1 + n / x1) / 2.0
          x3 = (x2 + n / x2) / 2.0
      in x3

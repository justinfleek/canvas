-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                 // canvas // physics // gravity
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Physics Gravity — Device orientation mapped to paint flow.
-- |
-- | ## Design Philosophy
-- |
-- | When you tilt your phone, paint should flow in that direction.
-- | This module bridges the device orientation APIs to the physics system:
-- |
-- |   DeviceOrientation → GravityVector → ParticleSystem.gravity
-- |
-- | ## Device Coordinate System
-- |
-- | The device orientation is reported as Euler angles:
-- | - **alpha**: Rotation around Z (compass heading, 0-360)
-- | - **beta**: Front-back tilt (-180 to 180)
-- |   - 0 = flat on table
-- |   - 90 = upright portrait
-- |   - -90 = upside down
-- | - **gamma**: Left-right tilt (-90 to 90)
-- |   - Positive = tilted right
-- |   - Negative = tilted left
-- |
-- | ## Canvas Gravity
-- |
-- | Gravity in canvas space is a 2D vector:
-- | - Positive X = paint flows right
-- | - Positive Y = paint flows down
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Hydrogen.Schema.Canvas.Physics
-- | - Hydrogen.Schema.Brush.WetMedia.Dynamics
-- | - Canvas.Types

module Canvas.Physics.Gravity
  ( -- * Gravity State
    GravityState
  , mkGravityState
  , initialGravityState
  , gravityEnabled
  , gravityScale
  , currentGravity
  , currentOrientation
  
  -- * State Updates
  , updateFromOrientation
  , updateFromAccelerometer
  , setGravityEnabled
  , setGravityScale
  
  -- * Gravity Queries
  , getGravity2D
  , getGravityMagnitude
  , getGravityAngle
  , isGravityActive
  , isDeviceFlat
  
  -- * Paint Flow
  , calculatePaintFlow
  , getPaintFlowDirection
  , shouldPaintFlow
  
  -- * Presets
  , gravityStatePortrait
  , gravityStateLandscapeLeft
  , gravityStateLandscapeRight
  , gravityStateFlat
  
  -- * Display
  , displayGravityState
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( class Eq
  , class Ord
  , class Show
  , show
  , (==)
  , (&&)
  , (||)
  , (>=)
  , (<=)
  , (<)
  , (>)
  , (+)
  , (-)
  , (*)
  , (/)
  , (<>)
  , max
  , min
  , not
  , negate
  )

import Data.Number (sqrt, atan2, pi, abs) as Num

import Hydrogen.Schema.Canvas.Physics
  ( DeviceOrientation
  , GravityVector
  , CanvasPhysics
  , mkDeviceOrientation
  , mkGravityVector
  , mkCanvasPhysics
  , orientationToGravity
  , updateOrientation
  , updateAccelerometer
  , getGravity2D
  , gravityMagnitude
  , gravityAngle
  , isGravitySignificant
  , orientationPortrait
  , orientationFlat
  , orientationLandscapeLeft
  , orientationLandscapeRight
  , AccelerometerData
  , mkAccelerometerData
  ) as HP

import Hydrogen.Schema.Brush.WetMedia.Dynamics
  ( GravityDirection
  , FlowVelocity
  , tiltToGravity
  , calculateFlowVelocity
  , flowVelocityMagnitude
  , canFlow
  ) as WM

import Hydrogen.Schema.Brush.WetMedia.Atoms
  ( Wetness
  , Viscosity
  , mkWetness
  , mkViscosity
  ) as WMA

import Canvas.Types
  ( Vec2D
  , mkVec2D
  , vecMagnitude
  , vecNormalize
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // gravity state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Complete gravity state for the canvas.
-- |
-- | Wraps Hydrogen's CanvasPhysics with additional canvas-specific settings.
type GravityState =
  { physics :: HP.CanvasPhysics
  , enabled :: Boolean           -- ^ Is gravity simulation enabled?
  , scale :: Number              -- ^ Gravity strength multiplier (0-2)
  , flowScale :: Number          -- ^ Paint flow velocity multiplier
  , flatThreshold :: Number      -- ^ Threshold for "device is flat" detection
  }

-- | Create gravity state with specified scale.
mkGravityState :: Number -> GravityState
mkGravityState gravScale =
  { physics: HP.mkCanvasPhysics gravScale
  , enabled: true
  , scale: clamp01 gravScale
  , flowScale: 100.0            -- Default: 100 pixels per unit gravity
  , flatThreshold: 0.1          -- Default: 10% tilt threshold
  }

-- | Initial gravity state (portrait mode, gravity enabled).
initialGravityState :: GravityState
initialGravityState = mkGravityState 1.0

-- | Check if gravity is enabled.
gravityEnabled :: GravityState -> Boolean
gravityEnabled gs = gs.enabled

-- | Get gravity scale multiplier.
gravityScale :: GravityState -> Number
gravityScale gs = gs.scale

-- | Get current gravity vector.
currentGravity :: GravityState -> HP.GravityVector
currentGravity gs = gs.physics.gravity

-- | Get current device orientation.
currentOrientation :: GravityState -> HP.DeviceOrientation
currentOrientation gs = gs.physics.orientation

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // state updates
-- ═════════════════════════════════════════════════════════════════════════════

-- | Update gravity from device orientation event.
-- |
-- | Call this when receiving DeviceOrientationEvent from browser.
updateFromOrientation 
  :: Number         -- ^ alpha (compass heading)
  -> Number         -- ^ beta (front-back tilt)
  -> Number         -- ^ gamma (left-right tilt)
  -> GravityState 
  -> GravityState
updateFromOrientation alpha beta gamma gs =
  let
    newOrientation = HP.mkDeviceOrientation alpha beta gamma
    newPhysics = HP.updateOrientation newOrientation gs.physics
  in
    gs { physics = newPhysics }

-- | Update gravity from accelerometer data.
-- |
-- | Call this when using DeviceMotion API's acceleration.
updateFromAccelerometer
  :: Number         -- ^ X acceleration (m/s^2)
  -> Number         -- ^ Y acceleration (m/s^2)
  -> Number         -- ^ Z acceleration (m/s^2)
  -> GravityState
  -> GravityState
updateFromAccelerometer ax ay az gs =
  let
    accel = HP.mkAccelerometerData ax ay az
    newPhysics = HP.updateAccelerometer accel gs.physics
  in
    gs { physics = newPhysics }

-- | Enable or disable gravity simulation.
setGravityEnabled :: Boolean -> GravityState -> GravityState
setGravityEnabled en gs = gs { enabled = en }

-- | Set gravity scale (clamped to 0-2).
setGravityScale :: Number -> GravityState -> GravityState
setGravityScale s gs = 
  let
    clampedScale = max 0.0 (min 2.0 s)
    newPhysics = gs.physics { gravityScale = clampedScale }
  in
    gs { scale = clampedScale, physics = newPhysics }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // gravity queries
-- ═════════════════════════════════════════════════════════════════════════════

-- | Get 2D gravity for canvas (ignoring Z component).
getGravity2D :: GravityState -> Vec2D
getGravity2D gs =
  if gs.enabled
    then 
      let g2d = HP.getGravity2D gs.physics
      in mkVec2D g2d.x g2d.y
    else mkVec2D 0.0 0.0

-- | Get magnitude of 2D gravity.
getGravityMagnitude :: GravityState -> Number
getGravityMagnitude gs =
  let v = getGravity2D gs
  in vecMagnitude v

-- | Get angle of gravity (radians, 0 = down, pi/2 = right).
getGravityAngle :: GravityState -> Number
getGravityAngle gs =
  let g = currentGravity gs
  in HP.gravityAngle g

-- | Check if gravity is active and significant.
isGravityActive :: GravityState -> Boolean
isGravityActive gs =
  gs.enabled && HP.isGravitySignificant (currentGravity gs) gs.flatThreshold

-- | Check if device is approximately flat.
isDeviceFlat :: GravityState -> Boolean
isDeviceFlat gs =
  not (HP.isGravitySignificant (currentGravity gs) gs.flatThreshold)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // paint flow
-- ═════════════════════════════════════════════════════════════════════════════

-- | Calculate paint flow velocity based on current gravity and paint properties.
-- |
-- | Uses Hydrogen's wet media dynamics to compute realistic flow.
calculatePaintFlow 
  :: GravityState 
  -> Number         -- ^ Wetness (0-100)
  -> Number         -- ^ Viscosity (0-100)
  -> Vec2D
calculatePaintFlow gs wetnessVal viscosityVal =
  if not gs.enabled
    then mkVec2D 0.0 0.0
    else
      let
        wetness = WMA.mkWetness wetnessVal
        viscosity = WMA.mkViscosity viscosityVal
        
        -- Get tilt angles from orientation
        orientation = currentOrientation gs
        tiltX = orientation.gamma  -- left-right tilt
        tiltY = orientation.beta   -- front-back tilt (relative to 90 = portrait)
        
        -- Adjust beta: 90 degrees = portrait = no forward tilt
        adjustedTiltY = tiltY - 90.0
        
        -- Calculate flow using Hydrogen's dynamics
        gravDir = WM.tiltToGravity tiltX adjustedTiltY
        flowVel = WM.calculateFlowVelocity wetness viscosity gravDir gs.flowScale
      in
        mkVec2D flowVel.vx flowVel.vy

-- | Get normalized paint flow direction.
getPaintFlowDirection :: GravityState -> Vec2D
getPaintFlowDirection gs =
  vecNormalize (getGravity2D gs)

-- | Check if paint should flow given current wetness and viscosity.
shouldPaintFlow :: GravityState -> Number -> Number -> Boolean
shouldPaintFlow gs wetnessVal viscosityVal =
  gs.enabled &&
  isGravityActive gs &&
  WM.canFlow (WMA.mkWetness wetnessVal) (WMA.mkViscosity viscosityVal)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // presets
-- ═════════════════════════════════════════════════════════════════════════════

-- | Gravity state for portrait mode (device upright).
gravityStatePortrait :: GravityState
gravityStatePortrait =
  let gs = initialGravityState
  in updateFromOrientation 0.0 90.0 0.0 gs

-- | Gravity state for landscape left (rotated counter-clockwise).
gravityStateLandscapeLeft :: GravityState
gravityStateLandscapeLeft =
  let gs = initialGravityState
  in updateFromOrientation 0.0 90.0 (-90.0) gs

-- | Gravity state for landscape right (rotated clockwise).
gravityStateLandscapeRight :: GravityState
gravityStateLandscapeRight =
  let gs = initialGravityState
  in updateFromOrientation 0.0 90.0 90.0 gs

-- | Gravity state for flat device (no tilt).
gravityStateFlat :: GravityState
gravityStateFlat =
  let gs = initialGravityState
  in updateFromOrientation 0.0 0.0 0.0 gs

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

-- | Display gravity state summary.
displayGravityState :: GravityState -> String
displayGravityState gs =
  let
    g2d = getGravity2D gs
    mag = getGravityMagnitude gs
    active = if isGravityActive gs then "active" else "inactive"
  in
    "GravityState { " <>
    (if gs.enabled then "enabled" else "disabled") <> ", " <>
    active <> ", " <>
    "scale=" <> show gs.scale <> ", " <>
    "gravity=(" <> show g2d.vx <> ", " <> show g2d.vy <> "), " <>
    "magnitude=" <> show mag <> " }"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // utilities
-- ═════════════════════════════════════════════════════════════════════════════

-- | Clamp to 0-1 range.
clamp01 :: Number -> Number
clamp01 n = max 0.0 (min 1.0 n)

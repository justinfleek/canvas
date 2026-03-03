-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                  // canvas // effect // graded
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas Graded Effects — Effect tracking for paint application.
-- |
-- | ## Design Philosophy
-- |
-- | Canvas operations that interact with the outside world are graded:
-- |
-- | - **Sensor**: Device orientation, accelerometer, gyroscope
-- | - **GPU**: WebGL/WebGPU rendering operations
-- | - **Timer**: Animation frames, requestAnimationFrame
-- | - **Haptic**: Vibration feedback
-- |
-- | Pure Schema operations (Types, Layer, Physics math) need no grading.
-- |
-- | ## Integration
-- |
-- | Extends Hydrogen.Effect.Graded with Canvas-specific labels.
-- | Uses the same graded monad pattern from effect-monad-912.
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Hydrogen.Effect.Graded
-- | - Hydrogen.Effect.Grade

module Canvas.Effect.Graded
  ( -- * Canvas Effect Labels (type-level)
    Sensor
  , GPU
  , Timer
  , Haptic
  
  -- * Canvas Grades (convenience aliases)
  , CanvasPure
  , SensorOnly
  , GPUOnly
  , RenderGrade
  , FullCanvas
  
  -- * Canvas CoEffect (value-level resource tracking)
  , CanvasCoEffect
  , emptyCanvasCoEffect
  , SensorAccess
  , GPUAccess
  , HapticAccess
  
  -- * Re-exports from Hydrogen
  , module Hydrogen.Effect.Graded
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude

import Hydrogen.Effect.Graded
  ( HydrogenM
  , HydrogenResult
  , HydrogenGrade
  , HydrogenCoEffect
  , HydrogenProvenance
  , emptyGrade
  , emptyCoEffect
  , emptyProvenance
  , runHydrogenM
  , runHydrogenMPure
  )

import Hydrogen.Effect.Grade (Grade, GradeLabel)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                      // canvas effect labels
-- ═════════════════════════════════════════════════════════════════════════════

-- | Sensor access — device orientation, accelerometer, gyroscope.
-- | Required for tilt-to-gravity paint flow.
foreign import data Sensor :: GradeLabel

-- | GPU access — WebGL/WebGPU rendering operations.
-- | Required for particle rendering, layer compositing.
foreign import data GPU :: GradeLabel

-- | Timer access — requestAnimationFrame, performance.now.
-- | Required for animation loop, physics timestep.
foreign import data Timer :: GradeLabel

-- | Haptic access — vibration feedback.
-- | Required for tactile brush feedback, easter eggs.
foreign import data Haptic :: GradeLabel

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // canvas grades
-- ═════════════════════════════════════════════════════════════════════════════

-- | Pure canvas computation — no effects permitted.
-- | Used for Schema operations: types, physics math, layer logic.
foreign import data CanvasPure :: Grade

-- | Sensor-only — device orientation tracking.
-- | Used for gravity updates from accelerometer.
foreign import data SensorOnly :: Grade

-- | GPU-only — rendering without sensors.
-- | Used for static canvas rendering.
foreign import data GPUOnly :: Grade

-- | Render grade — Timer + GPU for animation loop.
-- | The common case for frame rendering.
foreign import data RenderGrade :: Grade

-- | Full canvas — all canvas effects permitted.
-- | Sensor + GPU + Timer + Haptic.
foreign import data FullCanvas :: Grade

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // canvas coeffects
-- ═════════════════════════════════════════════════════════════════════════════

-- | Record of sensor access — what orientation data was read.
type SensorAccess =
  { sensorType :: String       -- ^ "orientation" | "accelerometer" | "gyroscope"
  , timestamp :: Number        -- ^ When the reading occurred
  , alpha :: Number            -- ^ Compass heading (if orientation)
  , beta :: Number             -- ^ Front-back tilt
  , gamma :: Number            -- ^ Left-right tilt
  }

-- | Record of GPU access — what rendering operations occurred.
type GPUAccess =
  { operation :: String        -- ^ "render" | "composite" | "clear"
  , particleCount :: Int       -- ^ Number of particles rendered
  , layerCount :: Int          -- ^ Number of layers composited
  , drawCalls :: Int           -- ^ WebGL draw calls
  }

-- | Record of haptic access — what vibrations were triggered.
type HapticAccess =
  { pattern :: String          -- ^ "short" | "long" | "custom"
  , intensity :: Number        -- ^ 0-1 intensity
  , durationMs :: Int          -- ^ Duration in milliseconds
  }

-- | Value-level coeffect tracking for Canvas operations.
-- |
-- | Mirrors the type-level grade at runtime — records what actually happened.
-- | Used for:
-- | - Performance profiling (how many draw calls?)
-- | - Debug overlay (current sensor readings)
-- | - Discharge proofs (prove the operation was authorized)
type CanvasCoEffect =
  { sensorAccesses :: Array SensorAccess
  , gpuAccesses :: Array GPUAccess
  , hapticAccesses :: Array HapticAccess
  , frameCount :: Int          -- ^ Animation frames processed
  , physicsSteps :: Int        -- ^ Physics simulation steps
  }

-- | Empty coeffect — no resources accessed.
emptyCanvasCoEffect :: CanvasCoEffect
emptyCanvasCoEffect =
  { sensorAccesses: []
  , gpuAccesses: []
  , hapticAccesses: []
  , frameCount: 0
  , physicsSteps: 0
  }

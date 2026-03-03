-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                  // canvas // paint // drying
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Paint Drying — Simulation of paint drying over time.
-- |
-- | ## Design Philosophy
-- |
-- | Paint particles start wet and dry over time. Wetness affects:
-- | - **Flow**: Wet paint responds to gravity, dry paint is fixed
-- | - **Blending**: Wet-into-wet creates color mixing
-- | - **Texture**: Drying paint develops granulation, hard edges
-- |
-- | ## Drying Model
-- |
-- | Wetness decreases exponentially:
-- |   wetness(t) = wetness(0) * e^(-dryingRate * t)
-- |
-- | Factors affecting drying rate:
-- | - Paint type (ink dries fast, oil dries slow)
-- | - Ambient humidity (simulated)
-- | - Paint thickness (more paint = slower drying)
-- | - Air flow (simulated via device motion)
-- |
-- | ## Thresholds
-- |
-- | - wetness > 80%: Fully wet, flows freely
-- | - wetness 20-80%: Tacky, limited flow, can blend
-- | - wetness < 20%: Touch-dry, no flow
-- | - wetness < 1%: Fully cured, permanent
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Hydrogen.Schema.Brush.WetMedia.Atoms
-- | - Hydrogen.Schema.Brush.WetMedia.Dynamics
-- | - Canvas.Paint.Particle

module Canvas.Paint.Drying
  ( -- * Drying State
    DryingState
      ( FullyWet
      , Tacky
      , TouchDry
      , FullyCured
      )
  , getDryingState
  , dryingStateName
  
  -- * Drying Configuration
  , DryingConfig
  , mkDryingConfig
  , defaultDryingConfig
  , fastDryingConfig
  , slowDryingConfig
  
  -- * Drying Simulation
  , simulateDrying
  , applyEnvironment
  , computeNewWetness
  , timeToDry
  
  -- * Environment Effects
  , EnvironmentFactors
  , mkEnvironmentFactors
  , defaultEnvironment
  , humidEnvironment
  , dryEnvironment
  
  -- * Particle Drying
  , dryParticle
  , dryParticles
  , partitionByDryness
  , isParticleDried
  , isParticleWet
  , isParticleTacky
  
  -- * Color Changes During Drying
  , applyDryingColorShift
  , computeGranulation
  , computeEdgeHardening
  
  -- * Display
  , displayDryingState
  , displayDryingConfig
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
  , (/=)
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
  , map
  , max
  , min
  , negate
  )

import Data.Array (filter, partition) as Array
import Data.Number (exp, log) as Num

import Hydrogen.Schema.Brush.WetMedia.Atoms
  ( Wetness
  , DryingRate
  , mkWetness
  , mkDryingRate
  , unwrapWetness
  , unwrapDryingRate
  )

import Canvas.Types
  ( Color
  , mkColor
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                               // drying state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Discrete drying states based on wetness thresholds.
data DryingState
  = FullyWet     -- ^ > 80% wetness, flows freely
  | Tacky        -- ^ 20-80% wetness, limited flow
  | TouchDry     -- ^ 1-20% wetness, no flow but not permanent
  | FullyCured   -- ^ < 1% wetness, permanent

derive instance eqDryingState :: Eq DryingState
derive instance ordDryingState :: Ord DryingState

instance showDryingState :: Show DryingState where
  show FullyWet = "fully-wet"
  show Tacky = "tacky"
  show TouchDry = "touch-dry"
  show FullyCured = "fully-cured"

-- | Get drying state from wetness value.
getDryingState :: Wetness -> DryingState
getDryingState w =
  let wet = unwrapWetness w
  in
    if wet > 80.0 then FullyWet
    else if wet > 20.0 then Tacky
    else if wet > 1.0 then TouchDry
    else FullyCured

-- | Human-readable state name.
dryingStateName :: DryingState -> String
dryingStateName FullyWet = "Fully Wet"
dryingStateName Tacky = "Tacky"
dryingStateName TouchDry = "Touch Dry"
dryingStateName FullyCured = "Fully Cured"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // drying configuration
-- ═════════════════════════════════════════════════════════════════════════════

-- | Configuration for drying simulation.
type DryingConfig =
  { baseRate :: DryingRate       -- ^ Base drying rate (0-100)
  , humidityModifier :: Number   -- ^ Multiplier from humidity (0.5-2.0)
  , thicknessModifier :: Number  -- ^ Multiplier from paint thickness
  , airflowModifier :: Number    -- ^ Multiplier from air movement
  , granulationOnset :: Number   -- ^ Wetness % when granulation starts
  , edgeHardeningOnset :: Number -- ^ Wetness % when edges harden
  }

-- | Create drying config.
mkDryingConfig :: Number -> Number -> DryingConfig
mkDryingConfig rate humidity =
  { baseRate: mkDryingRate (max 0.0 (min 100.0 rate))
  , humidityModifier: max 0.5 (min 2.0 humidity)
  , thicknessModifier: 1.0
  , airflowModifier: 1.0
  , granulationOnset: 60.0       -- Granulation starts at 60% wetness
  , edgeHardeningOnset: 40.0     -- Edges harden at 40% wetness
  }

-- | Default drying config (moderate rate, normal humidity).
defaultDryingConfig :: DryingConfig
defaultDryingConfig = mkDryingConfig 25.0 1.0

-- | Fast drying config (for acrylics, inks).
fastDryingConfig :: DryingConfig
fastDryingConfig = mkDryingConfig 60.0 0.8

-- | Slow drying config (for oils).
slowDryingConfig :: DryingConfig
slowDryingConfig = mkDryingConfig 5.0 1.2

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // drying simulation
-- ═════════════════════════════════════════════════════════════════════════════

-- | Simulate drying for a wetness value over time.
-- |
-- | Uses exponential decay: wetness(t) = wetness(0) * e^(-rate * t)
simulateDrying :: DryingConfig -> Wetness -> Number -> Wetness
simulateDrying config wet dt =
  let
    currentWet = unwrapWetness wet
    effectiveRate = computeEffectiveRate config
    -- Exponential decay
    newWet = currentWet * Num.exp (negate effectiveRate * dt)
  in
    mkWetness (max 0.0 newWet)

-- | Compute effective drying rate with all modifiers.
computeEffectiveRate :: DryingConfig -> Number
computeEffectiveRate config =
  let
    baseR = unwrapDryingRate config.baseRate / 100.0  -- Normalize to 0-1
  in
    baseR * config.humidityModifier * config.thicknessModifier * config.airflowModifier

-- | Apply environment factors to drying config.
applyEnvironment :: EnvironmentFactors -> DryingConfig -> DryingConfig
applyEnvironment env config =
  config
    { humidityModifier = env.humidityEffect
    , airflowModifier = env.airflowEffect
    }

-- | Compute new wetness after time delta.
computeNewWetness :: Wetness -> DryingRate -> Number -> Wetness
computeNewWetness wet rate dt =
  let
    currentWet = unwrapWetness wet
    r = unwrapDryingRate rate / 100.0
    newWet = currentWet * Num.exp (negate r * dt)
  in
    mkWetness (max 0.0 newWet)

-- | Estimate time to reach target wetness.
-- |
-- | Solving: target = current * e^(-rate * t)
-- | => t = -ln(target/current) / rate
timeToDry :: Wetness -> Wetness -> DryingRate -> Number
timeToDry currentWet targetWet rate =
  let
    current = unwrapWetness currentWet
    target = unwrapWetness targetWet
    r = unwrapDryingRate rate / 100.0
  in
    if current <= target || r <= 0.0
      then 0.0
      else negate (Num.log (target / current)) / r

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // environment effects
-- ═════════════════════════════════════════════════════════════════════════════

-- | Environmental factors affecting drying.
type EnvironmentFactors =
  { humidity :: Number         -- ^ Relative humidity (0-100%)
  , temperature :: Number      -- ^ Temperature (Celsius)
  , airflow :: Number          -- ^ Air movement (0-1)
  , humidityEffect :: Number   -- ^ Computed modifier from humidity
  , airflowEffect :: Number    -- ^ Computed modifier from airflow
  }

-- | Create environment factors.
mkEnvironmentFactors :: Number -> Number -> Number -> EnvironmentFactors
mkEnvironmentFactors hum temp air =
  let
    -- High humidity = slower drying
    humEffect = 2.0 - (hum / 100.0)  -- 100% humidity = 1.0x, 0% = 2.0x
    -- Air movement = faster drying
    airEffect = 1.0 + (air * 0.5)    -- 0 airflow = 1.0x, full = 1.5x
  in
    { humidity: max 0.0 (min 100.0 hum)
    , temperature: temp
    , airflow: max 0.0 (min 1.0 air)
    , humidityEffect: humEffect
    , airflowEffect: airEffect
    }

-- | Default environment (50% humidity, 20C, no airflow).
defaultEnvironment :: EnvironmentFactors
defaultEnvironment = mkEnvironmentFactors 50.0 20.0 0.0

-- | Humid environment (slows drying).
humidEnvironment :: EnvironmentFactors
humidEnvironment = mkEnvironmentFactors 80.0 25.0 0.0

-- | Dry environment (speeds drying).
dryEnvironment :: EnvironmentFactors
dryEnvironment = mkEnvironmentFactors 20.0 25.0 0.3

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // particle drying
-- ═════════════════════════════════════════════════════════════════════════════

-- | Simplified particle type for drying operations.
type DryableParticle =
  { wetness :: Wetness
  , dryingRate :: DryingRate
  , age :: Number
  }

-- | Apply drying to a single particle.
dryParticle :: DryingConfig -> Number -> DryableParticle -> DryableParticle
dryParticle config dt p =
  p { wetness = simulateDrying config p.wetness dt }

-- | Apply drying to multiple particles.
dryParticles :: DryingConfig -> Number -> Array DryableParticle -> Array DryableParticle
dryParticles config dt = map (dryParticle config dt)

-- | Partition particles into wet and dried.
partitionByDryness :: Number -> Array DryableParticle -> { wet :: Array DryableParticle, dried :: Array DryableParticle }
partitionByDryness threshold particles =
  let
    isWet p = unwrapWetness p.wetness >= threshold
    result = Array.partition isWet particles
  in
    { wet: result.yes, dried: result.no }

-- | Check if particle is fully dried (< 1% wetness).
isParticleDried :: DryableParticle -> Boolean
isParticleDried p = unwrapWetness p.wetness < 1.0

-- | Check if particle is fully wet (> 80% wetness).
isParticleWet :: DryableParticle -> Boolean
isParticleWet p = unwrapWetness p.wetness > 80.0

-- | Check if particle is tacky (20-80% wetness).
isParticleTacky :: DryableParticle -> Boolean
isParticleTacky p =
  let w = unwrapWetness p.wetness
  in w >= 20.0 && w <= 80.0

-- ═════════════════════════════════════════════════════════════════════════════
--                                                  // color changes during drying
-- ═════════════════════════════════════════════════════════════════════════════

-- | Apply color shift as paint dries.
-- |
-- | Watercolors get slightly darker, oils get slightly warmer.
applyDryingColorShift :: Color -> Wetness -> Number -> Color
applyDryingColorShift col wet _granulation =
  let
    w = unwrapWetness wet
    -- Colors darken as they dry (simplified model)
    darkenFactor = 1.0 - ((100.0 - w) / 100.0 * 0.1)  -- Max 10% darker
  in
    mkColor 
      (col.r * darkenFactor)
      (col.g * darkenFactor)
      (col.b * darkenFactor)
      col.a

-- | Compute granulation effect (pigment settling).
-- |
-- | Returns granulation intensity (0-1) based on wetness and config.
computeGranulation :: DryingConfig -> Wetness -> Number -> Number
computeGranulation config wet baseGranulation =
  let
    w = unwrapWetness wet
  in
    if w > config.granulationOnset
      then 0.0  -- Too wet for granulation
      else
        let
          -- Granulation increases as paint dries
          dryProgress = (config.granulationOnset - w) / config.granulationOnset
        in
          baseGranulation * dryProgress

-- | Compute edge hardening effect.
-- |
-- | Returns edge hardness (0-1) based on wetness and config.
computeEdgeHardening :: DryingConfig -> Wetness -> Number
computeEdgeHardening config wet =
  let
    w = unwrapWetness wet
  in
    if w > config.edgeHardeningOnset
      then 0.0  -- Too wet for hard edges
      else
        (config.edgeHardeningOnset - w) / config.edgeHardeningOnset

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

displayDryingState :: DryingState -> String
displayDryingState = dryingStateName

displayDryingConfig :: DryingConfig -> String
displayDryingConfig c =
  "DryingConfig { rate=" <> show (unwrapDryingRate c.baseRate) <> "%, " <>
  "humidity=" <> show c.humidityModifier <> "x }"

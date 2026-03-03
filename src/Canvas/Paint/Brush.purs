-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                   // canvas // paint // brush
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Brush Configuration — Brush settings and dynamics.
-- |
-- | ## Design Philosophy
-- |
-- | A brush combines:
-- | - **Shape**: Tip geometry (round, flat, fan, etc.)
-- | - **Dynamics**: How pressure/tilt affect size/opacity/flow
-- | - **Material**: Paint properties (from WetMedia)
-- | - **Texture**: Optional texture applied to stroke
-- |
-- | ## Dynamics Curves
-- |
-- | Each dynamic property can be controlled by:
-- | - Constant value
-- | - Pressure curve
-- | - Tilt curve
-- | - Speed curve
-- | - Random jitter
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Canvas.Types
-- | - Canvas.Paint.Particle (PaintPreset)

module Canvas.Paint.Brush
  ( -- * Brush Shape
    BrushShape
      ( RoundBrush
      , FlatBrush
      , FanBrush
      , KnifeBrush
      , AirBrush
      )
  , allBrushShapes
  , shapeName
  
  -- * Brush Dynamics
  , DynamicSource
      ( ConstantSource
      , PressureSource
      , TiltXSource
      , TiltYSource
      , SpeedSource
      , RandomSource
      )
  , DynamicCurve
  , mkDynamicCurve
  , constantCurve
  , linearPressureCurve
  , evaluateDynamic
  
  -- * Brush Configuration
  , BrushConfig
  , mkBrushConfig
  , defaultBrush
  , watercolorBrush
  , oilBrush
  , inkBrush
  , airbrush
  
  -- * Config Accessors
  , brushShape
  , brushBaseSize
  , brushSizeDynamic
  , brushBaseOpacity
  , brushOpacityDynamic
  , brushFlow
  , brushSpacing
  , brushHardness
  , brushRotation
  , brushColor
  
  -- * Config Mutations
  , setBrushShape
  , setBrushSize
  , setBrushOpacity
  , setBrushFlow
  , setBrushSpacing
  , setBrushHardness
  , setBrushColor
  
  -- * Dynamic Evaluation
  , computeSize
  , computeOpacity
  , computeFlow
  , computeRotation
  
  -- * Display
  , displayBrush
  , displayShape
  , displayDynamic
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
  , max
  , min
  )

import Data.Number (pow) as Num

import Canvas.Types
  ( Color
  , colorBlack
  )

import Canvas.Paint.Particle (PaintPreset(Watercolor, OilPaint, Ink))

-- ═════════════════════════════════════════════════════════════════════════════
--                                                               // brush shape
-- ═════════════════════════════════════════════════════════════════════════════

-- | Brush tip shape.
data BrushShape
  = RoundBrush       -- ^ Circular tip (most common)
  | FlatBrush        -- ^ Rectangular tip (for broad strokes)
  | FanBrush         -- ^ Fan-shaped (for blending, foliage)
  | KnifeBrush       -- ^ Knife edge (for scraping, sharp lines)
  | AirBrush         -- ^ Soft gradient falloff (for smooth shading)

derive instance eqBrushShape :: Eq BrushShape
derive instance ordBrushShape :: Ord BrushShape

instance showBrushShape :: Show BrushShape where
  show RoundBrush = "round"
  show FlatBrush = "flat"
  show FanBrush = "fan"
  show KnifeBrush = "knife"
  show AirBrush = "airbrush"

-- | All brush shapes.
allBrushShapes :: Array BrushShape
allBrushShapes = [RoundBrush, FlatBrush, FanBrush, KnifeBrush, AirBrush]

-- | Human-readable shape name.
shapeName :: BrushShape -> String
shapeName RoundBrush = "Round"
shapeName FlatBrush = "Flat"
shapeName FanBrush = "Fan"
shapeName KnifeBrush = "Palette Knife"
shapeName AirBrush = "Airbrush"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // brush dynamics
-- ═════════════════════════════════════════════════════════════════════════════

-- | Source for dynamic brush property.
data DynamicSource
  = ConstantSource   -- ^ Fixed value
  | PressureSource   -- ^ Controlled by pen pressure
  | TiltXSource      -- ^ Controlled by pen tilt X
  | TiltYSource      -- ^ Controlled by pen tilt Y
  | SpeedSource      -- ^ Controlled by stroke speed
  | RandomSource     -- ^ Random variation

derive instance eqDynamicSource :: Eq DynamicSource
derive instance ordDynamicSource :: Ord DynamicSource

instance showDynamicSource :: Show DynamicSource where
  show ConstantSource = "constant"
  show PressureSource = "pressure"
  show TiltXSource = "tiltX"
  show TiltYSource = "tiltY"
  show SpeedSource = "speed"
  show RandomSource = "random"

-- | Dynamic curve configuration.
-- |
-- | Maps input (0-1) to output using power curve:
-- |   output = minVal + (maxVal - minVal) * input^gamma
type DynamicCurve =
  { source :: DynamicSource
  , minVal :: Number       -- ^ Minimum output value
  , maxVal :: Number       -- ^ Maximum output value
  , gamma :: Number        -- ^ Curve shape (1 = linear, <1 = ease-in, >1 = ease-out)
  , jitter :: Number       -- ^ Random variation amount (0-1)
  }

-- | Create a dynamic curve.
mkDynamicCurve :: DynamicSource -> Number -> Number -> Number -> DynamicCurve
mkDynamicCurve src minV maxV gam =
  { source: src
  , minVal: minV
  , maxVal: maxV
  , gamma: max 0.01 gam  -- Prevent divide by zero
  , jitter: 0.0
  }

-- | Constant value (no dynamics).
constantCurve :: Number -> DynamicCurve
constantCurve val = mkDynamicCurve ConstantSource val val 1.0

-- | Linear pressure curve (0 pressure = min, full pressure = max).
linearPressureCurve :: Number -> Number -> DynamicCurve
linearPressureCurve minV maxV = mkDynamicCurve PressureSource minV maxV 1.0

-- | Evaluate a dynamic curve given input value (0-1).
evaluateDynamic :: DynamicCurve -> Number -> Number
evaluateDynamic curve input =
  let
    clampedInput = max 0.0 (min 1.0 input)
    curved = Num.pow clampedInput curve.gamma
    baseValue = curve.minVal + (curve.maxVal - curve.minVal) * curved
  in
    baseValue  -- Jitter would be applied here if needed

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // brush configuration
-- ═════════════════════════════════════════════════════════════════════════════

-- | Complete brush configuration.
type BrushConfig =
  { shape :: BrushShape
  , preset :: PaintPreset    -- ^ Paint type (watercolor, oil, etc.)
  , color :: Color
  
  -- Size
  , baseSize :: Number       -- ^ Base brush diameter (px)
  , sizeDynamic :: DynamicCurve
  
  -- Opacity
  , baseOpacity :: Number    -- ^ Base opacity (0-1)
  , opacityDynamic :: DynamicCurve
  
  -- Flow
  , flow :: Number           -- ^ Paint flow rate (0-1)
  , flowDynamic :: DynamicCurve
  
  -- Shape properties
  , spacing :: Number        -- ^ Spacing between dabs (fraction of size)
  , hardness :: Number       -- ^ Edge hardness (0 = soft, 1 = hard)
  , roundness :: Number      -- ^ Tip roundness (0 = flat, 1 = round)
  , rotation :: Number       -- ^ Tip rotation (degrees)
  , rotationDynamic :: DynamicCurve
  }

-- | Create a brush config with defaults.
mkBrushConfig :: BrushShape -> PaintPreset -> Number -> Color -> BrushConfig
mkBrushConfig sh pre sz col =
  { shape: sh
  , preset: pre
  , color: col
  , baseSize: max 1.0 (min 500.0 sz)
  , sizeDynamic: linearPressureCurve 0.2 1.0  -- 20%-100% based on pressure
  , baseOpacity: 1.0
  , opacityDynamic: constantCurve 1.0
  , flow: 1.0
  , flowDynamic: linearPressureCurve 0.3 1.0
  , spacing: 0.25
  , hardness: 0.8
  , roundness: 1.0
  , rotation: 0.0
  , rotationDynamic: constantCurve 0.0
  }

-- | Default round brush (20px black watercolor).
defaultBrush :: BrushConfig
defaultBrush = mkBrushConfig RoundBrush Watercolor 20.0 colorBlack

-- | Watercolor brush preset.
watercolorBrush :: Number -> Color -> BrushConfig
watercolorBrush sz col =
  let brush = mkBrushConfig RoundBrush Watercolor sz col
  in brush
    { hardness = 0.4      -- Soft edges
    , spacing = 0.15      -- Tight spacing for smooth strokes
    , opacityDynamic = linearPressureCurve 0.1 0.7  -- Light pressure = transparent
    }

-- | Oil paint brush preset.
oilBrush :: Number -> Color -> BrushConfig
oilBrush sz col =
  let brush = mkBrushConfig FlatBrush OilPaint sz col
  in brush
    { hardness = 0.9      -- Hard edges (impasto)
    , spacing = 0.3
    , flow = 0.8
    , roundness = 0.5     -- Elliptical tip
    }

-- | Ink brush preset.
inkBrush :: Number -> Color -> BrushConfig
inkBrush sz col =
  let brush = mkBrushConfig RoundBrush Ink sz col
  in brush
    { hardness = 1.0           -- Sharp edges
    , spacing = 0.1            -- Very tight for smooth lines
    , sizeDynamic = linearPressureCurve 0.1 1.0  -- Dramatic pressure response
    , opacityDynamic = constantCurve 1.0         -- Full opacity
    }

-- | Airbrush preset.
airbrush :: Number -> Color -> BrushConfig
airbrush sz col =
  let brush = mkBrushConfig AirBrush Watercolor sz col
  in brush
    { hardness = 0.0           -- Very soft
    , spacing = 0.05           -- Very tight
    , opacityDynamic = linearPressureCurve 0.05 0.3  -- Light spray
    , flowDynamic = linearPressureCurve 0.1 0.5
    }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // config accessors
-- ═════════════════════════════════════════════════════════════════════════════

brushShape :: BrushConfig -> BrushShape
brushShape b = b.shape

brushBaseSize :: BrushConfig -> Number
brushBaseSize b = b.baseSize

brushSizeDynamic :: BrushConfig -> DynamicCurve
brushSizeDynamic b = b.sizeDynamic

brushBaseOpacity :: BrushConfig -> Number
brushBaseOpacity b = b.baseOpacity

brushOpacityDynamic :: BrushConfig -> DynamicCurve
brushOpacityDynamic b = b.opacityDynamic

brushFlow :: BrushConfig -> Number
brushFlow b = b.flow

brushSpacing :: BrushConfig -> Number
brushSpacing b = b.spacing

brushHardness :: BrushConfig -> Number
brushHardness b = b.hardness

brushRotation :: BrushConfig -> Number
brushRotation b = b.rotation

brushColor :: BrushConfig -> Color
brushColor b = b.color

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // config mutations
-- ═════════════════════════════════════════════════════════════════════════════

setBrushShape :: BrushShape -> BrushConfig -> BrushConfig
setBrushShape sh b = b { shape = sh }

setBrushSize :: Number -> BrushConfig -> BrushConfig
setBrushSize sz b = b { baseSize = max 1.0 (min 500.0 sz) }

setBrushOpacity :: Number -> BrushConfig -> BrushConfig
setBrushOpacity op b = b { baseOpacity = max 0.0 (min 1.0 op) }

setBrushFlow :: Number -> BrushConfig -> BrushConfig
setBrushFlow fl b = b { flow = max 0.0 (min 1.0 fl) }

setBrushSpacing :: Number -> BrushConfig -> BrushConfig
setBrushSpacing sp b = b { spacing = max 0.01 (min 2.0 sp) }

setBrushHardness :: Number -> BrushConfig -> BrushConfig
setBrushHardness h b = b { hardness = max 0.0 (min 1.0 h) }

setBrushColor :: Color -> BrushConfig -> BrushConfig
setBrushColor col b = b { color = col }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // dynamic evaluation
-- ═════════════════════════════════════════════════════════════════════════════

-- | Input state for dynamic evaluation.
type DynamicInput =
  { pressure :: Number     -- ^ 0-1
  , tiltX :: Number        -- ^ -90 to 90 degrees
  , tiltY :: Number        -- ^ -90 to 90 degrees
  , speed :: Number        -- ^ 0-1 (normalized)
  }

-- | Compute actual brush size given input state.
computeSize :: BrushConfig -> DynamicInput -> Number
computeSize brush input =
  let
    sourceVal = getSourceValue brush.sizeDynamic.source input
    multiplier = evaluateDynamic brush.sizeDynamic sourceVal
  in
    brush.baseSize * multiplier

-- | Compute actual opacity given input state.
computeOpacity :: BrushConfig -> DynamicInput -> Number
computeOpacity brush input =
  let
    sourceVal = getSourceValue brush.opacityDynamic.source input
    multiplier = evaluateDynamic brush.opacityDynamic sourceVal
  in
    brush.baseOpacity * multiplier

-- | Compute actual flow given input state.
computeFlow :: BrushConfig -> DynamicInput -> Number
computeFlow brush input =
  let
    sourceVal = getSourceValue brush.flowDynamic.source input
  in
    evaluateDynamic brush.flowDynamic sourceVal

-- | Compute actual rotation given input state.
computeRotation :: BrushConfig -> DynamicInput -> Number
computeRotation brush input =
  let
    sourceVal = getSourceValue brush.rotationDynamic.source input
  in
    brush.rotation + evaluateDynamic brush.rotationDynamic sourceVal

-- | Get value from input based on source type.
getSourceValue :: DynamicSource -> DynamicInput -> Number
getSourceValue ConstantSource _ = 1.0
getSourceValue PressureSource input = input.pressure
getSourceValue TiltXSource input = (input.tiltX + 90.0) / 180.0  -- Normalize to 0-1
getSourceValue TiltYSource input = (input.tiltY + 90.0) / 180.0
getSourceValue SpeedSource input = input.speed
getSourceValue RandomSource _ = 0.5  -- Would use random in real impl

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

displayBrush :: BrushConfig -> String
displayBrush b =
  shapeName b.shape <> " " <> show b.baseSize <> "px " <>
  "(opacity=" <> show b.baseOpacity <> ", flow=" <> show b.flow <> ")"

displayShape :: BrushShape -> String
displayShape = shapeName

displayDynamic :: DynamicCurve -> String
displayDynamic c =
  show c.source <> " [" <> show c.minVal <> "-" <> show c.maxVal <> "] " <>
  "gamma=" <> show c.gamma

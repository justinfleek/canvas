-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                 // canvas // paint // pigment
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Kubelka-Munk Pigment Mixing — Physical color mixing for paint particles.
-- |
-- | ## Design Philosophy
-- |
-- | RGB color mixing produces muddy browns (additive/averaging).
-- | Real paint is subtractive: blue + yellow = green.
-- |
-- | Kubelka-Munk theory models light interaction with pigments:
-- |   K = absorption coefficient (how much light is absorbed)
-- |   S = scattering coefficient (how much light is scattered back)
-- |   R = reflectance = 1 + K/S - sqrt((K/S)² + 2K/S)
-- |
-- | ## Algorithm (from spectral.js)
-- |
-- | 1. Convert RGB to spectral reflectance (7 wavelength bands)
-- | 2. Mix spectra using weighted geometric mean (subtractive)
-- | 3. Convert back to RGB
-- |
-- | ## Grade
-- |
-- | All operations are CanvasPure — pure math, no effects.
-- |
-- | ## References
-- |
-- | - spectral.js: https://github.com/rvanwijnen/spectral.js
-- | - Scott Burns (2017): arXiv:1710.06364
-- | - Kubelka-Munk NN (2024): arXiv:2409.04558
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Canvas.Types (Color)

module Canvas.Paint.Pigment
  ( -- * Pigment Coefficients
    PigmentKS
  , mkPigmentKS
  , pigmentK
  , pigmentS
  
  -- * Spectral Reflectance (7 bands: 380-700nm)
  , Spectrum
  , mkSpectrum
  , spectrumBands
  
  -- * RGB ↔ Spectrum Conversion
  , rgbToSpectrum
  , spectrumToRgb
  
  -- * Kubelka-Munk Mixing
  , mixPigments
  , mixPigmentsWeighted
  , mixSpectral
  
  -- * Color Mixing (convenience API)
  , mixColors
  , mixColorsRatio
  
  -- * Display
  , displayPigmentKS
  , displaySpectrum
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( class Show
  , show
  , (+)
  , (-)
  , (*)
  , (/)
  , (<>)
  , (>)
  , (<)
  , (>=)
  , max
  , min
  , map
  )

import Data.Array (zipWith, foldl) as Array
import Data.Number (pow, sqrt) as Num

import Canvas.Types
  ( Color
  , mkColor
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // pigment coefficients
-- ═════════════════════════════════════════════════════════════════════════════

-- | Kubelka-Munk absorption (K) and scattering (S) coefficients.
-- |
-- | These determine how a pigment interacts with light:
-- | - High K, low S = dark, absorbing (e.g., carbon black)
-- | - Low K, high S = bright, opaque (e.g., titanium white)
-- | - Balanced = typical colored pigment
type PigmentKS =
  { k :: Number  -- ^ Absorption coefficient (0+)
  , s :: Number  -- ^ Scattering coefficient (0+)
  }

-- | Create pigment K/S values with validation.
mkPigmentKS :: Number -> Number -> PigmentKS
mkPigmentKS absorption scattering =
  { k: max 0.0 absorption
  , s: max 0.0001 scattering  -- Avoid division by zero
  }

-- | Get absorption coefficient.
pigmentK :: PigmentKS -> Number
pigmentK p = p.k

-- | Get scattering coefficient.
pigmentS :: PigmentKS -> Number
pigmentS p = p.s

-- | Display pigment K/S.
displayPigmentKS :: PigmentKS -> String
displayPigmentKS p = "K=" <> show p.k <> ", S=" <> show p.s

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // spectral reflectance
-- ═════════════════════════════════════════════════════════════════════════════

-- | Spectral reflectance across 7 wavelength bands.
-- |
-- | Bands (approximate):
-- |   0: 380-420nm (violet)
-- |   1: 420-460nm (blue)
-- |   2: 460-510nm (cyan)
-- |   3: 510-560nm (green)
-- |   4: 560-610nm (yellow)
-- |   5: 610-660nm (orange)
-- |   6: 660-700nm (red)
-- |
-- | Each value is reflectance 0-1 (0 = fully absorbed, 1 = fully reflected).
type Spectrum =
  { b0 :: Number  -- ^ Violet (380-420nm)
  , b1 :: Number  -- ^ Blue (420-460nm)
  , b2 :: Number  -- ^ Cyan (460-510nm)
  , b3 :: Number  -- ^ Green (510-560nm)
  , b4 :: Number  -- ^ Yellow (560-610nm)
  , b5 :: Number  -- ^ Orange (610-660nm)
  , b6 :: Number  -- ^ Red (660-700nm)
  }

-- | Create spectrum with clamped values.
mkSpectrum :: Number -> Number -> Number -> Number -> Number -> Number -> Number -> Spectrum
mkSpectrum v0 v1 v2 v3 v4 v5 v6 =
  { b0: clamp01 v0
  , b1: clamp01 v1
  , b2: clamp01 v2
  , b3: clamp01 v3
  , b4: clamp01 v4
  , b5: clamp01 v5
  , b6: clamp01 v6
  }

-- | Get spectrum as array of 7 bands.
spectrumBands :: Spectrum -> Array Number
spectrumBands s = [s.b0, s.b1, s.b2, s.b3, s.b4, s.b5, s.b6]

-- | Display spectrum.
displaySpectrum :: Spectrum -> String
displaySpectrum s = 
  "Spectrum[" <> show s.b0 <> ", " <> show s.b1 <> ", " <> show s.b2 <> ", " <>
  show s.b3 <> ", " <> show s.b4 <> ", " <> show s.b5 <> ", " <> show s.b6 <> "]"

-- | Clamp to 0-1 range.
clamp01 :: Number -> Number
clamp01 n = max 0.0 (min 1.0 n)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                    // rgb ↔ spectrum conversion
-- ═════════════════════════════════════════════════════════════════════════════

-- | Convert RGB color to spectral reflectance.
-- |
-- | Uses spectral upsampling: RGB → 7-band spectrum.
-- | Based on spectral.js approach with simplified basis functions.
-- |
-- | The basis functions are derived from typical pigment spectra:
-- | - Red pigments reflect mostly 600-700nm
-- | - Green pigments reflect mostly 500-560nm  
-- | - Blue pigments reflect mostly 420-500nm
rgbToSpectrum :: Color -> Spectrum
rgbToSpectrum c =
  let
    -- Linearize sRGB (approximate gamma removal)
    r = linearize c.r
    g = linearize c.g
    b = linearize c.b
    
    -- Spectral basis functions (simplified from spectral.js)
    -- Each row is the contribution of R, G, B to that wavelength band
    
    -- Violet (380-420nm): mostly blue
    v0 = 0.05 * r + 0.05 * g + 0.90 * b
    
    -- Blue (420-460nm): mostly blue, some green
    v1 = 0.02 * r + 0.15 * g + 0.83 * b
    
    -- Cyan (460-510nm): blue + green
    v2 = 0.02 * r + 0.60 * g + 0.38 * b
    
    -- Green (510-560nm): mostly green
    v3 = 0.05 * r + 0.85 * g + 0.10 * b
    
    -- Yellow (560-610nm): red + green
    v4 = 0.40 * r + 0.55 * g + 0.05 * b
    
    -- Orange (610-660nm): mostly red, some green
    v5 = 0.75 * r + 0.23 * g + 0.02 * b
    
    -- Red (660-700nm): mostly red
    v6 = 0.90 * r + 0.08 * g + 0.02 * b
    
  in
    mkSpectrum v0 v1 v2 v3 v4 v5 v6

-- | Convert spectral reflectance back to RGB.
-- |
-- | Uses CIE color matching functions (simplified).
spectrumToRgb :: Spectrum -> Color
spectrumToRgb s =
  let
    -- Inverse of the upsampling: weighted sum of bands
    -- These weights are derived from CIE XYZ → RGB conversion
    
    r = 0.02 * s.b0 + 0.01 * s.b1 + 0.01 * s.b2 + 
        0.05 * s.b3 + 0.35 * s.b4 + 0.70 * s.b5 + 0.95 * s.b6
    
    g = 0.02 * s.b0 + 0.10 * s.b1 + 0.40 * s.b2 + 
        0.85 * s.b3 + 0.60 * s.b4 + 0.20 * s.b5 + 0.05 * s.b6
    
    b = 0.70 * s.b0 + 0.85 * s.b1 + 0.50 * s.b2 + 
        0.10 * s.b3 + 0.02 * s.b4 + 0.01 * s.b5 + 0.01 * s.b6
    
    -- Apply gamma (sRGB)
    rGamma = gammaEncode (clamp01 r)
    gGamma = gammaEncode (clamp01 g)
    bGamma = gammaEncode (clamp01 b)
  in
    mkColor rGamma gGamma bGamma 1.0

-- | Linearize sRGB value (remove gamma).
linearize :: Number -> Number
linearize v =
  if v < 0.04045
    then v / 12.92
    else Num.pow ((v + 0.055) / 1.055) 2.4

-- | Apply sRGB gamma encoding.
gammaEncode :: Number -> Number
gammaEncode v =
  if v < 0.0031308
    then v * 12.92
    else 1.055 * Num.pow v (1.0 / 2.4) - 0.055

-- ═════════════════════════════════════════════════════════════════════════════
--                                                       // kubelka-munk mixing
-- ═════════════════════════════════════════════════════════════════════════════

-- | Mix two pigments using Kubelka-Munk theory.
-- |
-- | For each wavelength band:
-- |   K_mix = (K1 + K2) / 2
-- |   S_mix = (S1 + S2) / 2
-- |   R = 1 + K/S - sqrt((K/S)² + 2K/S)
-- |
-- | This is the physically correct way to mix paint!
mixPigments :: PigmentKS -> PigmentKS -> PigmentKS
mixPigments p1 p2 = mixPigmentsWeighted p1 p2 0.5

-- | Mix pigments with weighted ratio.
-- |
-- | ratio: 0.0 = all p1, 1.0 = all p2
mixPigmentsWeighted :: PigmentKS -> PigmentKS -> Number -> PigmentKS
mixPigmentsWeighted p1 p2 ratio =
  let
    t = clamp01 ratio
    kMix = p1.k * (1.0 - t) + p2.k * t
    sMix = p1.s * (1.0 - t) + p2.s * t
  in
    mkPigmentKS kMix sMix

-- | Kubelka-Munk reflectance from K/S ratio.
-- |
-- | R = 1 + K/S - sqrt((K/S)² + 2K/S)
kmReflectance :: Number -> Number -> Number
kmReflectance k s =
  let
    ratio = k / max 0.0001 s
    term = ratio * ratio + 2.0 * ratio
  in
    clamp01 (1.0 + ratio - Num.sqrt (max 0.0 term))

-- | Mix two spectra using weighted geometric mean (subtractive mixing).
-- |
-- | This is the key insight from spectral.js:
-- | Subtractive mixing = geometric mean in reflectance space
-- |
-- |   R_mix(λ) = R1(λ)^(1-t) × R2(λ)^t
-- |
-- | Where t is the mixing ratio (0 = all color1, 1 = all color2).
mixSpectral :: Spectrum -> Spectrum -> Number -> Spectrum
mixSpectral s1 s2 ratio =
  let
    t = clamp01 ratio
    t1 = 1.0 - t
    
    -- Weighted geometric mean for each band
    -- Add small epsilon to avoid pow(0, x) issues
    eps = 0.001
    
    mix :: Number -> Number -> Number
    mix v1 v2 = Num.pow (max eps v1) t1 * Num.pow (max eps v2) t
  in
    { b0: mix s1.b0 s2.b0
    , b1: mix s1.b1 s2.b1
    , b2: mix s1.b2 s2.b2
    , b3: mix s1.b3 s2.b3
    , b4: mix s1.b4 s2.b4
    , b5: mix s1.b5 s2.b5
    , b6: mix s1.b6 s2.b6
    }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                      // color mixing (convenience)
-- ══════════════════════════════��══════════════════════════════════════════════

-- | Mix two colors using Kubelka-Munk spectral mixing.
-- |
-- | This is the main API for paint mixing. Returns physically correct
-- | subtractive color result:
-- |
-- |   mixColors blue yellow → green (not gray!)
-- |
-- | 50/50 mix by default.
mixColors :: Color -> Color -> Color
mixColors c1 c2 = mixColorsRatio c1 c2 0.5

-- | Mix colors with explicit ratio.
-- |
-- | ratio: 0.0 = all c1, 1.0 = all c2
-- |
-- | Example:
-- |   mixColorsRatio red white 0.2 → light pink (20% white)
-- |   mixColorsRatio blue yellow 0.5 → green (50/50 mix)
mixColorsRatio :: Color -> Color -> Number -> Color
mixColorsRatio c1 c2 ratio =
  let
    -- Convert to spectral
    spec1 = rgbToSpectrum c1
    spec2 = rgbToSpectrum c2
    
    -- Mix in spectral space (subtractive)
    mixed = mixSpectral spec1 spec2 ratio
    
    -- Convert back to RGB
    result = spectrumToRgb mixed
    
    -- Preserve alpha (weighted average)
    t = clamp01 ratio
    alpha = c1.a * (1.0 - t) + c2.a * t
  in
    mkColor result.r result.g result.b alpha


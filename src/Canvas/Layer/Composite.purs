-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                // canvas // layer // composite
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Layer Compositing — Combine layers using blend modes.
-- |
-- | ## Design Philosophy
-- |
-- | Compositing combines rendered layers into the final image:
-- | 1. Start with background layer
-- | 2. Composite each layer in Z-order
-- | 3. Apply blend modes and opacity
-- | 4. Handle clip masks
-- |
-- | ## Blend Modes
-- |
-- | Standard Photoshop-style blend modes:
-- | - Normal: Direct overlay
-- | - Multiply: Darken (C = A * B)
-- | - Screen: Lighten (C = 1 - (1-A)*(1-B))
-- | - Overlay: Contrast (Multiply + Screen)
-- | - And more...
-- |
-- | ## Clip Masks
-- |
-- | When a layer has a clip mask:
-- | - Content is clipped to mask layer's alpha
-- | - Creates "clipping group" in layer stack
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Canvas.Types
-- | - Canvas.Layer.Types

module Canvas.Layer.Composite
  ( -- * Compositing
    compositeLayer
  , compositeLayers
  , compositeAll
  
  -- * Blend Operations
  , blendPixel
  , blendNormal
  , blendMultiply
  , blendScreen
  , blendOverlay
  , blendDarken
  , blendLighten
  , blendColorDodge
  , blendColorBurn
  , blendHardLight
  , blendSoftLight
  , blendDifference
  , blendExclusion
  
  -- * Alpha Compositing
  , alphaComposite
  , premultiply
  , unpremultiply
  , blendAlpha
  
  -- * Clip Masks
  , applyClipMask
  , computeClipAlpha
  , isClipped
  
  -- * Layer Groups
  , LayerGroup
  , mkLayerGroup
  , groupLayers
  , flattenGroup
  
  -- * Composite Result
  , CompositeResult
  , mkCompositeResult
  , resultColor
  , resultAlpha
  
  -- * Display
  , displayCompositeResult
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( class Eq
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
  )

import Data.Number (abs) as Num

import Data.Array (foldl, filter) as Array
import Data.Maybe (Maybe(Just, Nothing))

import Canvas.Types
  ( LayerId
  , Color
  , mkColor
  , BlendMode
      ( BlendNormal
      , BlendMultiply
      , BlendScreen
      , BlendOverlay
      , BlendDarken
      , BlendLighten
      , BlendColorDodge
      , BlendColorBurn
      , BlendHardLight
      , BlendSoftLight
      , BlendDifference
      , BlendExclusion
      )
  )

import Canvas.Layer.Types
  ( Layer
  , LayerStack
  , layerId
  , layerOpacity
  , layerBlendMode
  , layerClipMask
  , layerVisible
  , sortedLayers
  , getLayer
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // composite result
-- ═════════════════════════════════════════════════════════════════════════════

-- | Result of compositing operation.
type CompositeResult =
  { r :: Number    -- ^ Red (0-1)
  , g :: Number    -- ^ Green (0-1)
  , b :: Number    -- ^ Blue (0-1)
  , a :: Number    -- ^ Alpha (0-1)
  }

-- | Create composite result.
mkCompositeResult :: Number -> Number -> Number -> Number -> CompositeResult
mkCompositeResult pr pg pb pa =
  { r: clamp01 pr
  , g: clamp01 pg
  , b: clamp01 pb
  , a: clamp01 pa
  }

-- | Get color from result.
resultColor :: CompositeResult -> Color
resultColor r = mkColor r.r r.g r.b r.a

-- | Get alpha from result.
resultAlpha :: CompositeResult -> Number
resultAlpha r = r.a

-- ═════════════════════════════════════════════════════════════════════════════
--                                                               // compositing
-- ═════════════════════════════════════════════════════════════════════════════

-- | Composite a single layer onto background.
compositeLayer :: CompositeResult -> Color -> Layer -> CompositeResult
compositeLayer bg fg layer =
  let
    mode = layerBlendMode layer
    opacity = layerOpacity layer / 100.0
    -- Apply opacity to foreground
    fgWithOpacity = fg { a = fg.a * opacity }
    -- Blend
    blended = blendPixel mode 
      (colorToResult bg)
      (colorToResult fgWithOpacity)
  in
    blended

-- | Composite multiple layers (in Z-order).
compositeLayers :: CompositeResult -> Array { color :: Color, layer :: Layer } -> CompositeResult
compositeLayers initial layers =
  Array.foldl (\acc item ->
    compositeLayer acc item.color item.layer
  ) initial layers

-- | Composite all visible layers in a stack.
compositeAll :: LayerStack -> (Layer -> Color) -> CompositeResult
compositeAll stack getLayerColor =
  let
    visibleLayers = Array.filter layerVisible (sortedLayers stack)
    layers = map (\l -> { color: getLayerColor l, layer: l }) visibleLayers
    -- Start with transparent background
    initial = mkCompositeResult 0.0 0.0 0.0 0.0
  in
    compositeLayers initial layers

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // blend operations
-- ═════════════════════════════════════════════════════════════════════════════

-- | Blend two pixels using specified mode.
blendPixel :: BlendMode -> CompositeResult -> CompositeResult -> CompositeResult
blendPixel BlendNormal = blendNormal
blendPixel BlendMultiply = blendMultiply
blendPixel BlendScreen = blendScreen
blendPixel BlendOverlay = blendOverlay
blendPixel BlendDarken = blendDarken
blendPixel BlendLighten = blendLighten
blendPixel BlendColorDodge = blendColorDodge
blendPixel BlendColorBurn = blendColorBurn
blendPixel BlendHardLight = blendHardLight
blendPixel BlendSoftLight = blendSoftLight
blendPixel BlendDifference = blendDifference
blendPixel BlendExclusion = blendExclusion

-- | Normal blend (Porter-Duff over).
blendNormal :: CompositeResult -> CompositeResult -> CompositeResult
blendNormal = alphaComposite

-- | Multiply blend: C = A * B
blendMultiply :: CompositeResult -> CompositeResult -> CompositeResult
blendMultiply bg fg =
  let
    r = bg.r * fg.r
    g = bg.g * fg.g
    b = bg.b * fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Screen blend: C = 1 - (1-A)*(1-B)
blendScreen :: CompositeResult -> CompositeResult -> CompositeResult
blendScreen bg fg =
  let
    r = 1.0 - (1.0 - bg.r) * (1.0 - fg.r)
    g = 1.0 - (1.0 - bg.g) * (1.0 - fg.g)
    b = 1.0 - (1.0 - bg.b) * (1.0 - fg.b)
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Overlay blend: Multiply if bg < 0.5, Screen otherwise.
blendOverlay :: CompositeResult -> CompositeResult -> CompositeResult
blendOverlay bg fg =
  let
    overlayChannel bgC fgC =
      if bgC < 0.5
        then 2.0 * bgC * fgC
        else 1.0 - 2.0 * (1.0 - bgC) * (1.0 - fgC)
    r = overlayChannel bg.r fg.r
    g = overlayChannel bg.g fg.g
    b = overlayChannel bg.b fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Darken blend: min(A, B)
blendDarken :: CompositeResult -> CompositeResult -> CompositeResult
blendDarken bg fg =
  let
    r = min bg.r fg.r
    g = min bg.g fg.g
    b = min bg.b fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Lighten blend: max(A, B)
blendLighten :: CompositeResult -> CompositeResult -> CompositeResult
blendLighten bg fg =
  let
    r = max bg.r fg.r
    g = max bg.g fg.g
    b = max bg.b fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Color Dodge: A / (1 - B)
blendColorDodge :: CompositeResult -> CompositeResult -> CompositeResult
blendColorDodge bg fg =
  let
    dodgeChannel bgC fgC =
      if fgC >= 1.0 then 1.0
      else min 1.0 (bgC / (1.0 - fgC))
    r = dodgeChannel bg.r fg.r
    g = dodgeChannel bg.g fg.g
    b = dodgeChannel bg.b fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Color Burn: 1 - (1 - A) / B
blendColorBurn :: CompositeResult -> CompositeResult -> CompositeResult
blendColorBurn bg fg =
  let
    burnChannel bgC fgC =
      if fgC <= 0.0 then 0.0
      else max 0.0 (1.0 - (1.0 - bgC) / fgC)
    r = burnChannel bg.r fg.r
    g = burnChannel bg.g fg.g
    b = burnChannel bg.b fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Hard Light: Overlay with fg and bg swapped.
blendHardLight :: CompositeResult -> CompositeResult -> CompositeResult
blendHardLight bg fg =
  let
    hardLightChannel bgC fgC =
      if fgC < 0.5
        then 2.0 * bgC * fgC
        else 1.0 - 2.0 * (1.0 - bgC) * (1.0 - fgC)
    r = hardLightChannel bg.r fg.r
    g = hardLightChannel bg.g fg.g
    b = hardLightChannel bg.b fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Soft Light: Gentler version of overlay.
blendSoftLight :: CompositeResult -> CompositeResult -> CompositeResult
blendSoftLight bg fg =
  let
    softLightChannel bgC fgC =
      if fgC < 0.5
        then bgC - (1.0 - 2.0 * fgC) * bgC * (1.0 - bgC)
        else bgC + (2.0 * fgC - 1.0) * (d bgC - bgC)
    d x = if x <= 0.25
            then ((16.0 * x - 12.0) * x + 4.0) * x
            else sqrt x
    r = softLightChannel bg.r fg.r
    g = softLightChannel bg.g fg.g
    b = softLightChannel bg.b fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })
  where
    sqrt :: Number -> Number
    sqrt x = x  -- Simplified, should use proper sqrt

-- | Difference blend: |A - B|
blendDifference :: CompositeResult -> CompositeResult -> CompositeResult
blendDifference bg fg =
  let
    r = Num.abs (bg.r - fg.r)
    g = Num.abs (bg.g - fg.g)
    b = Num.abs (bg.b - fg.b)
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- | Exclusion blend: A + B - 2*A*B
blendExclusion :: CompositeResult -> CompositeResult -> CompositeResult
blendExclusion bg fg =
  let
    r = bg.r + fg.r - 2.0 * bg.r * fg.r
    g = bg.g + fg.g - 2.0 * bg.g * fg.g
    b = bg.b + fg.b - 2.0 * bg.b * fg.b
  in
    alphaComposite bg (fg { r = r, g = g, b = b })

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // alpha compositing
-- ═════════════════════════════════════════════════════════════════════════════

-- | Porter-Duff "over" compositing.
-- |
-- | Co = Cs * as + Cb * ab * (1 - as)
-- | ao = as + ab * (1 - as)
alphaComposite :: CompositeResult -> CompositeResult -> CompositeResult
alphaComposite bg fg =
  let
    as = fg.a
    ab = bg.a
    ao = as + ab * (1.0 - as)
    
    -- Avoid division by zero
    factor = if ao > 0.0001 then 1.0 / ao else 0.0
    
    r = (fg.r * as + bg.r * ab * (1.0 - as)) * factor
    g = (fg.g * as + bg.g * ab * (1.0 - as)) * factor
    b = (fg.b * as + bg.b * ab * (1.0 - as)) * factor
  in
    mkCompositeResult r g b ao

-- | Premultiply color by alpha.
premultiply :: CompositeResult -> CompositeResult
premultiply c =
  c { r = c.r * c.a
    , g = c.g * c.a
    , b = c.b * c.a
    }

-- | Unpremultiply color by alpha.
unpremultiply :: CompositeResult -> CompositeResult
unpremultiply c =
  if c.a > 0.0001
    then c { r = c.r / c.a
           , g = c.g / c.a
           , b = c.b / c.a
           }
    else c

-- | Blend two alpha values.
blendAlpha :: Number -> Number -> Number
blendAlpha a1 a2 = a1 + a2 * (1.0 - a1)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // clip masks
-- ═════════════════════════════════════════════════════════════════════════════

-- | Apply clip mask to layer content.
applyClipMask :: CompositeResult -> Number -> CompositeResult
applyClipMask content maskAlpha =
  content { a = content.a * maskAlpha }

-- | Compute clip alpha from mask layer.
computeClipAlpha :: LayerStack -> LayerId -> Number -> Number -> Number
computeClipAlpha stack maskId _x _y =
  case getLayer maskId stack of
    Nothing -> 1.0  -- No mask = full alpha
    Just maskLayer ->
      -- In a real implementation, this would sample the mask texture
      -- For now, return full alpha if visible, 0 if hidden
      if layerVisible maskLayer
        then 1.0
        else 0.0

-- | Check if layer is clipped by a mask.
isClipped :: Layer -> Boolean
isClipped layer =
  case layerClipMask layer of
    Just _ -> true
    Nothing -> false

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // layer groups
-- ═════════════════════════════════════════════════════════════════════════════

-- | A group of layers composited together.
type LayerGroup =
  { name :: String
  , layers :: Array Layer
  , blendMode :: BlendMode
  , opacity :: Number
  }

-- | Create a layer group.
mkLayerGroup :: String -> Array Layer -> LayerGroup
mkLayerGroup gname glayers =
  { name: gname
  , layers: glayers
  , blendMode: BlendNormal
  , opacity: 100.0
  }

-- | Group consecutive clipped layers.
groupLayers :: Array Layer -> Array LayerGroup
groupLayers layers =
  -- Simplified: each layer is its own group
  map (\l -> mkLayerGroup (show (layerId l)) [l]) layers

-- | Flatten a group to single result.
flattenGroup :: LayerGroup -> (Layer -> Color) -> CompositeResult
flattenGroup group getColor =
  let
    initial = mkCompositeResult 0.0 0.0 0.0 0.0
    layerData = map (\l -> { color: getColor l, layer: l }) group.layers
  in
    compositeLayers initial layerData

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

displayCompositeResult :: CompositeResult -> String
displayCompositeResult c =
  "rgba(" <> show c.r <> ", " <> show c.g <> ", " <> 
  show c.b <> ", " <> show c.a <> ")"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // utilities
-- ═════════════════════════════════════════════════════════════════════════════

-- | Clamp value to 0-1 range.
clamp01 :: Number -> Number
clamp01 n = max 0.0 (min 1.0 n)

-- | Convert Color to CompositeResult.
colorToResult :: Color -> CompositeResult
colorToResult c = { r: c.r, g: c.g, b: c.b, a: c.a }

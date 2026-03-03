-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                  // canvas // layer // render
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Layer Rendering — Render individual layers to elements.
-- |
-- | ## Design Philosophy
-- |
-- | Each layer renders to an isolated element that can be:
-- | - Positioned absolutely within the canvas
-- | - Composited with other layers via blend modes
-- | - Clipped by masks
-- | - Cached for performance
-- |
-- | ## Render Pipeline
-- |
-- | 1. Sort layers by Z-index
-- | 2. For each visible layer:
-- |    a. Render background (if background layer)
-- |    b. Render committed strokes
-- |    c. Render active particles
-- |    d. Apply layer effects (blur, etc.)
-- | 3. Composite all layers
-- |
-- | ## Performance
-- |
-- | - Static layers are cached as textures
-- | - Only dirty regions are re-rendered
-- | - Particles use instanced rendering
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Hydrogen.Render.Element
-- | - Canvas.Types
-- | - Canvas.Layer.Types
-- | - Canvas.Paint.Particle

module Canvas.Layer.Render
  ( -- * Layer Rendering
    renderLayer
  , renderLayerContent
  , renderLayerBackground
  , renderLayerStrokes
  , renderLayerParticles
  
  -- * Layer Container
  , layerContainer
  , layerStyle
  , layerTransform
  
  -- * Background Rendering
  , renderBackground
  , renderSolidBackground
  , renderGradientBackground
  , renderTextureBackground
  , renderTransparentBackground
  
  -- * Stroke Rendering
  , renderStroke
  , renderStrokePath
  , renderStrokePoints
  
  -- * Particle Rendering
  , renderParticle
  , renderParticleCircle
  , renderParticleBatch
  
  -- * Effects
  , applyLayerEffects
  , applyBlur
  , applyOpacity
  
  -- * Dirty Regions
  , DirtyRegion
  , mkDirtyRegion
  , isDirty
  , markDirty
  , clearDirty
  , expandDirty
  
  -- * Cache
  , LayerCache
  , mkLayerCache
  , isCached
  , invalidateCache
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
  , not
  )

import Data.Array (length, foldl) as Array
import Data.Tuple (Tuple(Tuple))
import Data.Maybe (Maybe(Just, Nothing))

import Hydrogen.Render.Element as E
import Hydrogen.Render.Element
  ( Element
  , div_
  , span_
  , text
  , class_
  , styles
  )

import Canvas.Types
  ( LayerId
  , unwrapLayerId
  , ZIndex
  , unwrapZIndex
  , Point2D
  , Bounds
  , mkBounds
  , boundsIntersects
  , Color
  , BlendMode
  , blendModeName
  )

import Canvas.Layer.Types
  ( Layer
  , layerId
  , layerName
  , layerZIndex
  , layerVisible
  , layerOpacity
  , layerBlendMode
  , layerBounds
  , isBackgroundLayer
  , Background
  , BackgroundType(SolidBackground, GradientBackground, TextureBackground, TransparentBackground)
  , backgroundType
  , backgroundColor
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // layer rendering
-- ═════════════════════════════════════════════════════════════════════════════

-- | Render a single layer as an Element.
-- |
-- | Takes the layer and a render function for content.
renderLayer :: forall msg. Layer -> Array (Element msg) -> Element msg
renderLayer layer content =
  if not (layerVisible layer)
    then div_ [] []  -- Hidden layer renders nothing
    else
      div_
        ([ class_ ("layer layer-" <> show (unwrapLayerId (layerId layer)))
        ] <> layerStyle layer)
        content

-- | Render layer content (strokes + particles).
renderLayerContent :: forall msg. Layer -> Array (Element msg) -> Array (Element msg) -> Element msg
renderLayerContent layer strokes particles =
  div_
    [ class_ "layer-content" ]
    (strokes <> particles)

-- | Render layer background (for background layer only).
renderLayerBackground :: forall msg. Layer -> Background -> Element msg
renderLayerBackground layer bg =
  if isBackgroundLayer layer
    then renderBackground bg (layerBounds layer)
    else div_ [] []

-- | Render layer strokes container.
renderLayerStrokes :: forall msg. Array (Element msg) -> Element msg
renderLayerStrokes strokes =
  div_
    ([ class_ "layer-strokes" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" "0"
        , Tuple "left" "0"
        , Tuple "width" "100%"
        , Tuple "height" "100%"
        , Tuple "pointer-events" "none"
        ])
    strokes

-- | Render layer particles container.
renderLayerParticles :: forall msg. Array (Element msg) -> Element msg
renderLayerParticles particles =
  E.svg_
    (styles
        [ Tuple "position" "absolute"
        , Tuple "top" "0"
        , Tuple "left" "0"
        , Tuple "width" "100%"
        , Tuple "height" "100%"
        , Tuple "pointer-events" "none"
        ])
    particles

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // layer container
-- ═════════════════════════════════════════════════════════════════════════════

-- | Create layer container div.
layerContainer :: forall msg. Layer -> Array (Element msg) -> Element msg
layerContainer layer = div_ (layerStyle layer)

-- | Generate layer style attributes.
layerStyle :: forall msg. Layer -> Array (E.Attribute msg)
layerStyle layer =
  let
    bounds = layerBounds layer
    zIdx = unwrapZIndex (layerZIndex layer)
    opacity = layerOpacity layer / 100.0
    blend = blendModeName (layerBlendMode layer)
  in
    styles
      [ Tuple "position" "absolute"
      , Tuple "top" (show bounds.y <> "px")
      , Tuple "left" (show bounds.x <> "px")
      , Tuple "width" (show bounds.width <> "px")
      , Tuple "height" (show bounds.height <> "px")
      , Tuple "z-index" (show zIdx)
      , Tuple "opacity" (show opacity)
      , Tuple "mix-blend-mode" blend
      , Tuple "pointer-events" "none"
      ]

-- | Generate layer transform string.
layerTransform :: Layer -> String
layerTransform _layer = "none"  -- No transform for basic layers

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // background rendering
-- ═════════════════════════════════════════════════════════════════════════════

-- | Render background based on type.
renderBackground :: forall msg. Background -> Bounds -> Element msg
renderBackground bg bounds =
  case backgroundType bg of
    SolidBackground -> renderSolidBackground (backgroundColor bg) bounds
    GradientBackground -> renderGradientBackground bg bounds
    TextureBackground -> renderTextureBackground bg bounds
    TransparentBackground -> renderTransparentBackground bounds

-- | Render solid color background.
renderSolidBackground :: forall msg. Color -> Bounds -> Element msg
renderSolidBackground color bounds =
  div_
    ([ class_ "bg-solid" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" (show bounds.y <> "px")
        , Tuple "left" (show bounds.x <> "px")
        , Tuple "width" (show bounds.width <> "px")
        , Tuple "height" (show bounds.height <> "px")
        , Tuple "background-color" (colorToCss color)
        ])
    []

-- | Render gradient background.
renderGradientBackground :: forall msg. Background -> Bounds -> Element msg
renderGradientBackground bg bounds =
  let color = backgroundColor bg
  in div_
    ([ class_ "bg-gradient" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" (show bounds.y <> "px")
        , Tuple "left" (show bounds.x <> "px")
        , Tuple "width" (show bounds.width <> "px")
        , Tuple "height" (show bounds.height <> "px")
        , Tuple "background" ("linear-gradient(180deg, " <> colorToCss color <> " 0%, white 100%)")
        ])
    []

-- | Render texture background.
renderTextureBackground :: forall msg. Background -> Bounds -> Element msg
renderTextureBackground bg bounds =
  let url = case bg.textureUrl of
        Just u -> u
        Nothing -> ""
  in div_
    ([ class_ "bg-texture" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" (show bounds.y <> "px")
        , Tuple "left" (show bounds.x <> "px")
        , Tuple "width" (show bounds.width <> "px")
        , Tuple "height" (show bounds.height <> "px")
        , Tuple "background-image" ("url(" <> url <> ")")
        , Tuple "background-size" "cover"
        ])
    []

-- | Render transparent background (checkerboard pattern).
renderTransparentBackground :: forall msg. Bounds -> Element msg
renderTransparentBackground bounds =
  div_
    ([ class_ "bg-transparent" ] <> styles
        [ Tuple "position" "absolute"
        , Tuple "top" (show bounds.y <> "px")
        , Tuple "left" (show bounds.x <> "px")
        , Tuple "width" (show bounds.width <> "px")
        , Tuple "height" (show bounds.height <> "px")
        , Tuple "background-image" "linear-gradient(45deg, #ccc 25%, transparent 25%), linear-gradient(-45deg, #ccc 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #ccc 75%), linear-gradient(-45deg, transparent 75%, #ccc 75%)"
        , Tuple "background-size" "20px 20px"
        , Tuple "background-position" "0 0, 0 10px, 10px -10px, -10px 0px"
        ])
    []

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // stroke rendering
-- ═════════════════════════════════════════════════════════════════════════════

-- | Render a stroke as SVG path.
renderStroke :: forall msg. Array Point2D -> Color -> Number -> Element msg
renderStroke points color width =
  E.path_
    [ E.attr "d" (renderStrokePath points)
    , E.attr "stroke" (colorToCss color)
    , E.attr "stroke-width" (show width)
    , E.attr "fill" "none"
    , E.attr "stroke-linecap" "round"
    , E.attr "stroke-linejoin" "round"
    ]

-- | Generate SVG path data from points.
renderStrokePath :: Array Point2D -> String
renderStrokePath points =
  case Array.length points of
    0 -> ""
    1 -> case points of
      [p] -> "M " <> show p.x <> " " <> show p.y
      _ -> ""
    _ -> 
      Array.foldl (\acc pt ->
        if acc == ""
          then "M " <> show pt.x <> " " <> show pt.y
          else acc <> " L " <> show pt.x <> " " <> show pt.y
      ) "" points
  where
    foldl = Array.foldl

-- | Render stroke as individual point circles (for debugging).
renderStrokePoints :: forall msg. Array Point2D -> Color -> Number -> Array (Element msg)
renderStrokePoints points color radius =
  map (\pt -> renderParticleCircle pt.x pt.y radius color) points

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // particle rendering
-- ═════════════════════════════════════════════════════════════════════════════

-- | Simplified particle for rendering.
type RenderParticle =
  { x :: Number
  , y :: Number
  , radius :: Number
  , color :: Color
  , opacity :: Number
  }

-- | Render a single particle.
renderParticle :: forall msg. RenderParticle -> Element msg
renderParticle p =
  renderParticleCircle p.x p.y p.radius p.color

-- | Render particle as SVG circle.
renderParticleCircle :: forall msg. Number -> Number -> Number -> Color -> Element msg
renderParticleCircle x y radius color =
  E.circle_
    [ E.attr "cx" (show x)
    , E.attr "cy" (show y)
    , E.attr "r" (show radius)
    , E.attr "fill" (colorToCss color)
    ]

-- | Render batch of particles (for performance).
renderParticleBatch :: forall msg. Array RenderParticle -> Element msg
renderParticleBatch particles =
  E.g_ [] (map renderParticle particles)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // effects
-- ═════════════════════════════════════════════════════════════════════════════

-- | Apply layer effects (blur, etc).
applyLayerEffects :: forall msg. Number -> Number -> Element msg -> Element msg
applyLayerEffects blur opacity element =
  div_
    (styles
        [ Tuple "filter" (if blur > 0.0 then "blur(" <> show blur <> "px)" else "none")
        , Tuple "opacity" (show opacity)
        ])
    [element]

-- | Apply blur effect.
applyBlur :: Number -> String
applyBlur amount =
  if amount > 0.0
    then "blur(" <> show amount <> "px)"
    else "none"

-- | Apply opacity effect.
applyOpacity :: Number -> String
applyOpacity amount = show (max 0.0 (min 1.0 amount))

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // dirty regions
-- ═════════════════════════════════════════════════════════════════════════════

-- | Dirty region for incremental rendering.
type DirtyRegion =
  { bounds :: Bounds
  , dirty :: Boolean
  }

-- | Create dirty region.
mkDirtyRegion :: Bounds -> DirtyRegion
mkDirtyRegion b = { bounds: b, dirty: true }

-- | Check if region is dirty.
isDirty :: DirtyRegion -> Boolean
isDirty r = r.dirty

-- | Mark region as dirty.
markDirty :: DirtyRegion -> DirtyRegion
markDirty r = r { dirty = true }

-- | Clear dirty flag.
clearDirty :: DirtyRegion -> DirtyRegion
clearDirty r = r { dirty = false }

-- | Expand dirty region to include another bounds.
expandDirty :: DirtyRegion -> Bounds -> DirtyRegion
expandDirty r newBounds =
  let
    minX = min r.bounds.x newBounds.x
    minY = min r.bounds.y newBounds.y
    maxX = max (r.bounds.x + r.bounds.width) (newBounds.x + newBounds.width)
    maxY = max (r.bounds.y + r.bounds.height) (newBounds.y + newBounds.height)
  in
    r { bounds = mkBounds minX minY (maxX - minX) (maxY - minY)
      , dirty = true
      }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                      // cache
-- ═════════════════════════════════════════════════════════════════════════════

-- | Layer cache for static content.
type LayerCache =
  { layerId :: LayerId
  , valid :: Boolean
  , lastModified :: Number     -- ^ Timestamp of last modification
  }

-- | Create layer cache.
mkLayerCache :: LayerId -> LayerCache
mkLayerCache lid =
  { layerId: lid
  , valid: false
  , lastModified: 0.0
  }

-- | Check if cache is valid.
isCached :: LayerCache -> Boolean
isCached c = c.valid

-- | Invalidate cache.
invalidateCache :: LayerCache -> LayerCache
invalidateCache c = c { valid = false }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // utilities
-- ═════════════════════════════════════════════════════════════════════════════

-- | Convert Color to CSS string.
colorToCss :: Color -> String
colorToCss c =
  "rgba(" <> 
  show (c.r * 255.0) <> "," <>
  show (c.g * 255.0) <> "," <>
  show (c.b * 255.0) <> "," <>
  show c.a <> ")"

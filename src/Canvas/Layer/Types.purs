-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                   // canvas // layer // types
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Layer Types — Paint layer system with isolation and compositing.
-- |
-- | ## Design Philosophy
-- |
-- | Each layer is an isolated rendering surface with its own:
-- | - Particle system (SPH fluid simulation)
-- | - Committed strokes (dried paint)
-- | - Blend mode and opacity
-- | - Optional clip mask
-- |
-- | ## Layer Hierarchy
-- |
-- | Z-Index | Type     | Contents
-- | --------|----------|----------------------------------
-- | 0       | Static   | Background (paper texture, fill)
-- | 1-99    | Dynamic  | User paint layers
-- | 100     | Transient| Active stroke (current brush)
-- | 101     | UI       | Selection rectangle
-- | 102     | UI       | Grid, guides, rulers
-- | 103     | UI       | Tool cursor
-- | 104     | UI       | Tooltips, menus
-- | 105     | UI       | Debug overlay
-- |
-- | ## Isolation
-- |
-- | When a layer has effects (blur, noise), they are confined to that
-- | layer's framebuffer. No bleed to adjacent layers.
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Data.Maybe
-- | - Canvas.Types

module Canvas.Layer.Types
  ( -- * Layer
    Layer
  , mkLayer
  , mkLayer3D
  , layerId
  , layerName
  , layerZIndex
  , layerVisible
  , layerLocked
  , layerOpacity
  , layerBlendMode
  , layerClipMask
  , layerBounds
  
  -- * Layer Mutations
  , setLayerName
  , setLayerZIndex
  , setLayerVisible
  , setLayerLocked
  , setLayerOpacity
  , setLayerBlendMode
  , setLayerClipMask
  , clearLayerClipMask
  
  -- * Layer Predicates
  , isLayerVisible
  , isLayerLocked
  , isLayerEditable
  , isBackgroundLayer
  , isPaintLayer
  , isUILayer
  
  -- * Layer Stack
  , LayerStack
  , mkLayerStack
  , emptyLayerStack
  , stackLayers
  , stackActiveLayerId
  , addLayer
  , removeLayer
  , getLayer
  , updateLayer
  , setActiveLayer
  , getActiveLayer
  , layerCount
  , sortedLayers
  
  -- * Stack Navigation
  , moveLayerUp
  , moveLayerDown
  , bringLayerToFront
  , sendLayerToBack
  
  -- * Background
  , BackgroundType
      ( SolidBackground
      , GradientBackground
      , TextureBackground
      , TransparentBackground
      )
  , Background
  , mkBackground
  , backgroundType
  , backgroundColor
  , defaultBackground
  , paperTextureBackground
  
  -- * Display
  , displayLayer
  , displayLayerStack
  , displayBackground
  
  -- * Layer Content Type (2D/3D)
  , LayerContentType
      ( Paint2DContent
      , Scene3DContent
      )
  , layerContentType
  , setLayerContentType
  , isPaint2DLayer
  , isScene3DLayer
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
  , (<>)
  , map
  , max
  , min
  , compare
  , comparing
  , not
  )

import Data.Array (length, filter, snoc, sortBy, findIndex, index, updateAt, deleteAt, foldl, fromFoldable) as Array
import Data.Maybe (Maybe(Just, Nothing), fromMaybe, isJust)
import Data.Map (Map)
import Data.Map (empty, insert, lookup, delete, values, size) as Map

import Canvas.Types
  ( LayerId
  , mkLayerId
  , unwrapLayerId
  , backgroundLayerId
  , ZIndex
  , mkZIndex
  , unwrapZIndex
  , zIndexBackground
  , zIndexPaintMin
  , zIndexPaintMax
  , Bounds
  , mkBounds
  , BlendMode(BlendNormal)
  , Color
  , colorWhite
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // layer content type
-- ═════════════════════════════════════════════════════════════════════════════

-- | Type of content in a layer.
-- |
-- | A layer can contain either:
-- | - 2D paint content (SPH particle simulation, strokes)
-- | - 3D scene content (meshes, lights, camera)
-- |
-- | This allows mixing 2D painting with 3D elements in the same canvas.
data LayerContentType
  = Paint2DContent    -- ^ Traditional 2D paint layer
  | Scene3DContent    -- ^ 3D scene layer (uses Layer3D)

derive instance eqLayerContentType :: Eq LayerContentType
derive instance ordLayerContentType :: Ord LayerContentType

instance showLayerContentType :: Show LayerContentType where
  show Paint2DContent = "2D Paint"
  show Scene3DContent = "3D Scene"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                      // layer
-- ═════════════════════════════════════════════════════════════════════════════

-- | A single layer in the canvas.
-- |
-- | Layers can contain either 2D paint or 3D scene content.
-- | The contentType field determines which rendering path is used.
type Layer =
  { id :: LayerId
  , name :: String
  , zIndex :: ZIndex
  , visible :: Boolean
  , locked :: Boolean
  , opacity :: Number          -- ^ 0-100
  , blendMode :: BlendMode
  , clipMask :: Maybe LayerId  -- ^ Clip to another layer
  , bounds :: Bounds           -- ^ Layer bounds
  , contentType :: LayerContentType  -- ^ 2D paint or 3D scene
  }

-- | Create a new 2D paint layer.
mkLayer :: LayerId -> String -> ZIndex -> Bounds -> Layer
mkLayer lid lname zidx lbounds =
  { id: lid
  , name: lname
  , zIndex: zidx
  , visible: true
  , locked: false
  , opacity: 100.0
  , blendMode: BlendNormal
  , clipMask: Nothing
  , bounds: lbounds
  , contentType: Paint2DContent
  }

-- | Create a new 3D scene layer.
mkLayer3D :: LayerId -> String -> ZIndex -> Bounds -> Layer
mkLayer3D lid lname zidx lbounds =
  { id: lid
  , name: lname
  , zIndex: zidx
  , visible: true
  , locked: false
  , opacity: 100.0
  , blendMode: BlendNormal
  , clipMask: Nothing
  , bounds: lbounds
  , contentType: Scene3DContent
  }

-- | Get layer ID.
layerId :: Layer -> LayerId
layerId l = l.id

-- | Get layer name.
layerName :: Layer -> String
layerName l = l.name

-- | Get layer Z-index.
layerZIndex :: Layer -> ZIndex
layerZIndex l = l.zIndex

-- | Check if layer is visible.
layerVisible :: Layer -> Boolean
layerVisible l = l.visible

-- | Check if layer is locked.
layerLocked :: Layer -> Boolean
layerLocked l = l.locked

-- | Get layer opacity (0-100).
layerOpacity :: Layer -> Number
layerOpacity l = l.opacity

-- | Get layer blend mode.
layerBlendMode :: Layer -> BlendMode
layerBlendMode l = l.blendMode

-- | Get layer clip mask.
layerClipMask :: Layer -> Maybe LayerId
layerClipMask l = l.clipMask

-- | Get layer bounds.
layerBounds :: Layer -> Bounds
layerBounds l = l.bounds

-- | Get layer content type.
layerContentType :: Layer -> LayerContentType
layerContentType l = l.contentType

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // layer mutations
-- ═════════════════════════════════════════════════════════════════════════════

-- | Set layer name.
setLayerName :: String -> Layer -> Layer
setLayerName newName l = l { name = newName }

-- | Set layer Z-index.
setLayerZIndex :: ZIndex -> Layer -> Layer
setLayerZIndex z l = l { zIndex = z }

-- | Set layer visibility.
setLayerVisible :: Boolean -> Layer -> Layer
setLayerVisible v l = l { visible = v }

-- | Set layer locked state.
setLayerLocked :: Boolean -> Layer -> Layer
setLayerLocked locked l = l { locked = locked }

-- | Set layer opacity (clamped to 0-100).
setLayerOpacity :: Number -> Layer -> Layer
setLayerOpacity o l = l { opacity = max 0.0 (min 100.0 o) }

-- | Set layer blend mode.
setLayerBlendMode :: BlendMode -> Layer -> Layer
setLayerBlendMode bm l = l { blendMode = bm }

-- | Set layer clip mask.
setLayerClipMask :: LayerId -> Layer -> Layer
setLayerClipMask maskId l = l { clipMask = Just maskId }

-- | Clear layer clip mask.
clearLayerClipMask :: Layer -> Layer
clearLayerClipMask l = l { clipMask = Nothing }

-- | Set layer content type.
setLayerContentType :: LayerContentType -> Layer -> Layer
setLayerContentType ct l = l { contentType = ct }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // layer predicates
-- ═════════════════════════════════════════════════════════════════════════════

-- | Check if layer is visible.
isLayerVisible :: Layer -> Boolean
isLayerVisible l = l.visible

-- | Check if layer is locked.
isLayerLocked :: Layer -> Boolean
isLayerLocked l = l.locked

-- | Check if layer can be edited (visible and not locked).
isLayerEditable :: Layer -> Boolean
isLayerEditable l = l.visible && not l.locked

-- | Check if this is the background layer.
isBackgroundLayer :: Layer -> Boolean
isBackgroundLayer l = unwrapZIndex l.zIndex == 0

-- | Check if this is a paint layer (Z 1-99).
isPaintLayer :: Layer -> Boolean
isPaintLayer l =
  let z = unwrapZIndex l.zIndex
  in z >= 1 && z <= 99

-- | Check if this is a UI layer (Z >= 100).
isUILayer :: Layer -> Boolean
isUILayer l = unwrapZIndex l.zIndex >= 100

-- | Check if layer contains 2D paint content.
isPaint2DLayer :: Layer -> Boolean
isPaint2DLayer l = l.contentType == Paint2DContent

-- | Check if layer contains 3D scene content.
isScene3DLayer :: Layer -> Boolean
isScene3DLayer l = l.contentType == Scene3DContent

-- ═════════════════════════════════════════════════════════════════════════════
--                                                               // layer stack
-- ═════════════════════════════════════════════════════════════════════════════

-- | A stack of layers with an active layer selection.
type LayerStack =
  { layers :: Map Int Layer    -- ^ LayerId Int -> Layer
  , activeLayerId :: LayerId
  , nextLayerId :: Int
  }

-- | Create a layer stack with initial layers.
mkLayerStack :: Array Layer -> LayerId -> LayerStack
mkLayerStack initialLayers activeId =
  let
    insertLayer :: Map Int Layer -> Layer -> Map Int Layer
    insertLayer m l = Map.insert (unwrapLayerId l.id) l m
    
    layerMap = Array.foldl insertLayer Map.empty initialLayers
    
    maxId = Array.foldl (\acc l -> max acc (unwrapLayerId l.id)) 0 initialLayers
  in
    { layers: layerMap
    , activeLayerId: activeId
    , nextLayerId: maxId + 1
    }
  where
    foldl :: forall a b. (b -> a -> b) -> b -> Array a -> b
    foldl = Array.foldl

-- | Empty layer stack.
emptyLayerStack :: LayerStack
emptyLayerStack =
  { layers: Map.empty
  , activeLayerId: mkLayerId 0
  , nextLayerId: 1
  }

-- | Get all layers as array.
stackLayers :: LayerStack -> Array Layer
stackLayers stack = Array.fromFoldable (Map.values stack.layers)

-- | Get active layer ID.
stackActiveLayerId :: LayerStack -> LayerId
stackActiveLayerId stack = stack.activeLayerId

-- | Add a layer to the stack.
addLayer :: Layer -> LayerStack -> LayerStack
addLayer l stack =
  stack { layers = Map.insert (unwrapLayerId l.id) l stack.layers }

-- | Remove a layer from the stack.
removeLayer :: LayerId -> LayerStack -> LayerStack
removeLayer lid stack =
  stack { layers = Map.delete (unwrapLayerId lid) stack.layers }

-- | Get a layer by ID.
getLayer :: LayerId -> LayerStack -> Maybe Layer
getLayer lid stack = Map.lookup (unwrapLayerId lid) stack.layers

-- | Update a layer in the stack.
updateLayer :: LayerId -> (Layer -> Layer) -> LayerStack -> LayerStack
updateLayer lid f stack =
  case Map.lookup (unwrapLayerId lid) stack.layers of
    Just l -> 
      stack { layers = Map.insert (unwrapLayerId lid) (f l) stack.layers }
    Nothing -> stack

-- | Set the active layer.
setActiveLayer :: LayerId -> LayerStack -> LayerStack
setActiveLayer lid stack = stack { activeLayerId = lid }

-- | Get the active layer.
getActiveLayer :: LayerStack -> Maybe Layer
getActiveLayer stack = getLayer stack.activeLayerId stack

-- | Get total layer count.
layerCount :: LayerStack -> Int
layerCount stack = Map.size stack.layers

-- | Get layers sorted by Z-index (bottom to top).
sortedLayers :: LayerStack -> Array Layer
sortedLayers stack =
  Array.sortBy (comparing layerZIndex) (stackLayers stack)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // stack navigation
-- ═════════════════════════════════════════════════════════════════════════════

-- | Move layer up in Z-order (swap with layer above).
moveLayerUp :: LayerId -> LayerStack -> LayerStack
moveLayerUp lid stack =
  case getLayer lid stack of
    Nothing -> stack
    Just layer ->
      let
        currentZ = unwrapZIndex (layerZIndex layer)
        sorted = sortedLayers stack
        layerAbove = findLayerAbove currentZ sorted
      in
        case layerAbove of
          Nothing -> stack
          Just above ->
            let
              newStack = updateLayer lid (setLayerZIndex (layerZIndex above)) stack
            in
              updateLayer (layerId above) (setLayerZIndex (layerZIndex layer)) newStack

-- | Move layer down in Z-order (swap with layer below).
moveLayerDown :: LayerId -> LayerStack -> LayerStack
moveLayerDown lid stack =
  case getLayer lid stack of
    Nothing -> stack
    Just layer ->
      let
        currentZ = unwrapZIndex (layerZIndex layer)
        sorted = sortedLayers stack
        layerBelow = findLayerBelow currentZ sorted
      in
        case layerBelow of
          Nothing -> stack
          Just below ->
            let
              newStack = updateLayer lid (setLayerZIndex (layerZIndex below)) stack
            in
              updateLayer (layerId below) (setLayerZIndex (layerZIndex layer)) newStack

-- | Bring layer to front (highest Z in paint range).
bringLayerToFront :: LayerId -> LayerStack -> LayerStack
bringLayerToFront lid stack =
  let
    paintLayers = Array.filter isPaintLayer (stackLayers stack)
    maxZ = Array.foldl 
      (\acc l -> max acc (unwrapZIndex (layerZIndex l))) 
      1 
      paintLayers
    newZ = min 99 (maxZ + 1)
  in
    updateLayer lid (setLayerZIndex (mkZIndex newZ)) stack
  where
    foldl :: forall a b. (b -> a -> b) -> b -> Array a -> b
    foldl = Array.foldl

-- | Send layer to back (lowest Z in paint range).
sendLayerToBack :: LayerId -> LayerStack -> LayerStack
sendLayerToBack lid stack =
  let
    paintLayers = Array.filter isPaintLayer (stackLayers stack)
    minZ = Array.foldl 
      (\acc l -> min acc (unwrapZIndex (layerZIndex l))) 
      99 
      paintLayers
    newZ = max 1 (minZ - 1)
  in
    updateLayer lid (setLayerZIndex (mkZIndex newZ)) stack
  where
    foldl :: forall a b. (b -> a -> b) -> b -> Array a -> b
    foldl = Array.foldl

-- | Find layer immediately above given Z-index.
findLayerAbove :: Int -> Array Layer -> Maybe Layer
findLayerAbove currentZ layers =
  let
    above = Array.filter (\l -> unwrapZIndex (layerZIndex l) > currentZ && isPaintLayer l) layers
    sorted = Array.sortBy (comparing layerZIndex) above
  in
    Array.index sorted 0

-- | Find layer immediately below given Z-index.
findLayerBelow :: Int -> Array Layer -> Maybe Layer
findLayerBelow currentZ layers =
  let
    below = Array.filter (\l -> unwrapZIndex (layerZIndex l) < currentZ && isPaintLayer l) layers
    sorted = Array.sortBy (\a b -> compare (layerZIndex b) (layerZIndex a)) below
  in
    Array.index sorted 0

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // background
-- ═════════════════════════════════════════════════════════════════════════════

-- | Type of background fill.
data BackgroundType
  = SolidBackground
  | GradientBackground
  | TextureBackground
  | TransparentBackground

derive instance eqBackgroundType :: Eq BackgroundType
derive instance ordBackgroundType :: Ord BackgroundType

instance showBackgroundType :: Show BackgroundType where
  show SolidBackground = "solid"
  show GradientBackground = "gradient"
  show TextureBackground = "texture"
  show TransparentBackground = "transparent"

-- | Background configuration.
type Background =
  { bgType :: BackgroundType
  , color :: Color
  , textureUrl :: Maybe String
  }

-- | Create a background.
mkBackground :: BackgroundType -> Color -> Background
mkBackground bt bc =
  { bgType: bt
  , color: bc
  , textureUrl: Nothing
  }

-- | Get background type.
backgroundType :: Background -> BackgroundType
backgroundType bg = bg.bgType

-- | Get background color.
backgroundColor :: Background -> Color
backgroundColor bg = bg.color

-- | Default white background.
defaultBackground :: Background
defaultBackground = mkBackground SolidBackground colorWhite

-- | Paper texture background.
paperTextureBackground :: String -> Background
paperTextureBackground url =
  { bgType: TextureBackground
  , color: colorWhite
  , textureUrl: Just url
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

-- | Display layer info.
displayLayer :: Layer -> String
displayLayer l =
  "Layer[" <> show (unwrapLayerId l.id) <> "] \"" <> l.name <> "\" " <>
  "z:" <> show (unwrapZIndex l.zIndex) <> " " <>
  (if l.visible then "visible" else "hidden") <> " " <>
  (if l.locked then "locked" else "unlocked") <> " " <>
  "opacity:" <> show l.opacity <> "%"

-- | Display layer stack summary.
displayLayerStack :: LayerStack -> String
displayLayerStack stack =
  "LayerStack[" <> show (layerCount stack) <> " layers, " <>
  "active:" <> show (unwrapLayerId stack.activeLayerId) <> "]"

-- | Display background info.
displayBackground :: Background -> String
displayBackground bg =
  "Background(" <> show bg.bgType <> ")"

-- Redefine foldl to avoid import conflict
foldl :: forall a b. (b -> a -> b) -> b -> Array a -> b
foldl = Array.foldl

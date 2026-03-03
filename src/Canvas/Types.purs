-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                        // canvas // types
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas Types — Core type definitions for the paint application.
-- |
-- | ## Design Philosophy
-- |
-- | Canvas is a professional digital art application where paint particles
-- | follow physics. These types define the fundamental building blocks:
-- |
-- | - **LayerId**: Unique identifier for paint layers
-- | - **StrokeId**: Unique identifier for brush strokes
-- | - **Tool**: Currently selected tool (brush, eraser, etc.)
-- | - **Bounds**: Rectangle defining canvas/layer boundaries
-- | - **Point2D/Vec2D**: 2D coordinates and vectors
-- |
-- | ## Z-Index Conventions
-- |
-- | Layers follow a strict Z-index hierarchy:
-- |   0        = Background (paper texture)
-- |   1-99     = Paint layers (user content)
-- |   100      = Active stroke (currently painting)
-- |   101      = Selection overlay
-- |   102      = Guides (grid, rulers)
-- |   103      = Tool cursor
-- |   104      = UI overlays (tooltips, menus)
-- |   105      = Debug overlay
-- |
-- | ## Dependencies
-- | - Prelude

module Canvas.Types
  ( -- * Identifiers
    LayerId
  , mkLayerId
  , unwrapLayerId
  , defaultLayerId
  , backgroundLayerId
  , activeStrokeLayerId
  , selectionLayerId
  , guidesLayerId
  , toolsLayerId
  , overlaysLayerId
  , debugLayerId
  
  , StrokeId
  , mkStrokeId
  , unwrapStrokeId
  
  , ParticleId
  , mkParticleId
  , unwrapParticleId
  
  -- * Tool System
  , Tool
      ( BrushTool
      , EraserTool
      , EyedropperTool
      , PanTool
      , ZoomTool
      , SelectionTool
      , FillTool
      )
  , allTools
  , toolName
  , toolShortcut
  , isPaintingTool
  
  -- * Geometry
  , Point2D
  , mkPoint2D
  , point2DX
  , point2DY
  , pointOrigin
  
  , Vec2D
  , mkVec2D
  , vec2DX
  , vec2DY
  , vecZero
  , vecAdd
  , vecSub
  , vecScale
  , vecMagnitude
  , vecNormalize
  , vecDot
  
  , Bounds
  , mkBounds
  , boundsX
  , boundsY
  , boundsWidth
  , boundsHeight
  , boundsContains
  , boundsIntersects
  , boundsCenter
  
  -- * Z-Index
  , ZIndex
  , mkZIndex
  , unwrapZIndex
  , zIndexBackground
  , zIndexPaintMin
  , zIndexPaintMax
  , zIndexActiveStroke
  , zIndexSelection
  , zIndexGuides
  , zIndexTools
  , zIndexOverlays
  , zIndexDebug
  
  -- * Color (simplified, wraps Hydrogen)
  , Color
  , mkColor
  , colorR
  , colorG
  , colorB
  , colorA
  , colorBlack
  , colorWhite
  , colorTransparent
  
  -- * Blend Modes
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
  , allBlendModes
  , blendModeName
  
  -- * Display
  , displayTool
  , displayBounds
  , displayPoint
  , displayVec
  , displayColor
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
  , negate
  )

import Data.Number (sqrt) as Num

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                // identifiers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Unique identifier for a layer.
newtype LayerId = LayerId Int

derive instance eqLayerId :: Eq LayerId
derive instance ordLayerId :: Ord LayerId

instance showLayerId :: Show LayerId where
  show (LayerId n) = "LayerId(" <> show n <> ")"

-- | Create a layer ID.
mkLayerId :: Int -> LayerId
mkLayerId n = LayerId (max 0 n)

-- | Extract the raw ID.
unwrapLayerId :: LayerId -> Int
unwrapLayerId (LayerId n) = n

-- | Default paint layer (1).
defaultLayerId :: LayerId
defaultLayerId = LayerId 1

-- | Background layer (0).
backgroundLayerId :: LayerId
backgroundLayerId = LayerId 0

-- | Active stroke layer (100).
activeStrokeLayerId :: LayerId
activeStrokeLayerId = LayerId 100

-- | Selection overlay (101).
selectionLayerId :: LayerId
selectionLayerId = LayerId 101

-- | Guides layer (102).
guidesLayerId :: LayerId
guidesLayerId = LayerId 102

-- | Tools layer (103).
toolsLayerId :: LayerId
toolsLayerId = LayerId 103

-- | Overlays layer (104).
overlaysLayerId :: LayerId
overlaysLayerId = LayerId 104

-- | Debug layer (105).
debugLayerId :: LayerId
debugLayerId = LayerId 105

-- | Unique identifier for a stroke.
newtype StrokeId = StrokeId Int

derive instance eqStrokeId :: Eq StrokeId
derive instance ordStrokeId :: Ord StrokeId

instance showStrokeId :: Show StrokeId where
  show (StrokeId n) = "StrokeId(" <> show n <> ")"

-- | Create a stroke ID.
mkStrokeId :: Int -> StrokeId
mkStrokeId n = StrokeId (max 0 n)

-- | Extract the raw ID.
unwrapStrokeId :: StrokeId -> Int
unwrapStrokeId (StrokeId n) = n

-- | Unique identifier for a particle.
newtype ParticleId = ParticleId Int

derive instance eqParticleId :: Eq ParticleId
derive instance ordParticleId :: Ord ParticleId

instance showParticleId :: Show ParticleId where
  show (ParticleId n) = "ParticleId(" <> show n <> ")"

-- | Create a particle ID.
mkParticleId :: Int -> ParticleId
mkParticleId n = ParticleId (max 0 n)

-- | Extract the raw ID.
unwrapParticleId :: ParticleId -> Int
unwrapParticleId (ParticleId n) = n

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // tool system
-- ═════════════════════════════════════════════════════════════════════════════

-- | Available tools in the canvas application.
data Tool
  = BrushTool         -- ^ Paint with brush
  | EraserTool        -- ^ Erase content
  | EyedropperTool    -- ^ Pick color from canvas
  | PanTool           -- ^ Pan the canvas view
  | ZoomTool          -- ^ Zoom in/out
  | SelectionTool     -- ^ Select regions
  | FillTool          -- ^ Fill regions with color

derive instance eqTool :: Eq Tool
derive instance ordTool :: Ord Tool

instance showTool :: Show Tool where
  show BrushTool = "brush"
  show EraserTool = "eraser"
  show EyedropperTool = "eyedropper"
  show PanTool = "pan"
  show ZoomTool = "zoom"
  show SelectionTool = "selection"
  show FillTool = "fill"

-- | All available tools.
allTools :: Array Tool
allTools = 
  [ BrushTool
  , EraserTool
  , EyedropperTool
  , PanTool
  , ZoomTool
  , SelectionTool
  , FillTool
  ]

-- | Human-readable tool name.
toolName :: Tool -> String
toolName BrushTool = "Brush"
toolName EraserTool = "Eraser"
toolName EyedropperTool = "Eyedropper"
toolName PanTool = "Pan"
toolName ZoomTool = "Zoom"
toolName SelectionTool = "Selection"
toolName FillTool = "Fill"

-- | Keyboard shortcut for tool.
toolShortcut :: Tool -> String
toolShortcut BrushTool = "B"
toolShortcut EraserTool = "E"
toolShortcut EyedropperTool = "I"
toolShortcut PanTool = "H"
toolShortcut ZoomTool = "Z"
toolShortcut SelectionTool = "V"
toolShortcut FillTool = "G"

-- | Check if tool creates paint strokes.
isPaintingTool :: Tool -> Boolean
isPaintingTool BrushTool = true
isPaintingTool EraserTool = true
isPaintingTool _ = false

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // geometry
-- ═════════════════════════════════════════════════════════════════════════════

-- | A 2D point in canvas space.
type Point2D =
  { x :: Number
  , y :: Number
  }

-- | Create a 2D point.
mkPoint2D :: Number -> Number -> Point2D
mkPoint2D px py = { x: px, y: py }

-- | Get X coordinate.
point2DX :: Point2D -> Number
point2DX p = p.x

-- | Get Y coordinate.
point2DY :: Point2D -> Number
point2DY p = p.y

-- | Origin point (0, 0).
pointOrigin :: Point2D
pointOrigin = { x: 0.0, y: 0.0 }

-- | A 2D vector.
type Vec2D =
  { vx :: Number
  , vy :: Number
  }

-- | Create a 2D vector.
mkVec2D :: Number -> Number -> Vec2D
mkVec2D vx vy = { vx, vy }

-- | Get X component.
vec2DX :: Vec2D -> Number
vec2DX v = v.vx

-- | Get Y component.
vec2DY :: Vec2D -> Number
vec2DY v = v.vy

-- | Zero vector.
vecZero :: Vec2D
vecZero = { vx: 0.0, vy: 0.0 }

-- | Add two vectors.
vecAdd :: Vec2D -> Vec2D -> Vec2D
vecAdd a b = { vx: a.vx + b.vx, vy: a.vy + b.vy }

-- | Subtract two vectors.
vecSub :: Vec2D -> Vec2D -> Vec2D
vecSub a b = { vx: a.vx - b.vx, vy: a.vy - b.vy }

-- | Scale a vector.
vecScale :: Number -> Vec2D -> Vec2D
vecScale s v = { vx: s * v.vx, vy: s * v.vy }

-- | Vector magnitude.
vecMagnitude :: Vec2D -> Number
vecMagnitude v = Num.sqrt (v.vx * v.vx + v.vy * v.vy)

-- | Normalize to unit vector.
vecNormalize :: Vec2D -> Vec2D
vecNormalize v =
  let mag = vecMagnitude v
  in if mag > 0.0001
     then { vx: v.vx / mag, vy: v.vy / mag }
     else vecZero

-- | Dot product.
vecDot :: Vec2D -> Vec2D -> Number
vecDot a b = a.vx * b.vx + a.vy * b.vy

-- | A rectangular bounds in canvas space.
type Bounds =
  { x :: Number       -- ^ Left edge
  , y :: Number       -- ^ Top edge
  , width :: Number   -- ^ Width
  , height :: Number  -- ^ Height
  }

-- | Create bounds with validation.
mkBounds :: Number -> Number -> Number -> Number -> Bounds
mkBounds bx by bw bh =
  { x: bx
  , y: by
  , width: max 0.0 bw
  , height: max 0.0 bh
  }

-- | Get left edge.
boundsX :: Bounds -> Number
boundsX b = b.x

-- | Get top edge.
boundsY :: Bounds -> Number
boundsY b = b.y

-- | Get width.
boundsWidth :: Bounds -> Number
boundsWidth b = b.width

-- | Get height.
boundsHeight :: Bounds -> Number
boundsHeight b = b.height

-- | Check if point is inside bounds.
boundsContains :: Bounds -> Point2D -> Boolean
boundsContains b p =
  p.x >= b.x && p.x <= b.x + b.width &&
  p.y >= b.y && p.y <= b.y + b.height

-- | Check if two bounds intersect.
boundsIntersects :: Bounds -> Bounds -> Boolean
boundsIntersects a b =
  a.x < b.x + b.width &&
  a.x + a.width > b.x &&
  a.y < b.y + b.height &&
  a.y + a.height > b.y

-- | Get center point of bounds.
boundsCenter :: Bounds -> Point2D
boundsCenter b =
  { x: b.x + b.width / 2.0
  , y: b.y + b.height / 2.0
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // z-index
-- ═════════════════════════════════════════════════════════════════════════════

-- | Z-index for layer ordering.
newtype ZIndex = ZIndex Int

derive instance eqZIndex :: Eq ZIndex
derive instance ordZIndex :: Ord ZIndex

instance showZIndex :: Show ZIndex where
  show (ZIndex n) = "ZIndex(" <> show n <> ")"

-- | Create a Z-index (clamped to 0-999).
mkZIndex :: Int -> ZIndex
mkZIndex n = ZIndex (max 0 (min 999 n))

-- | Extract raw Z-index.
unwrapZIndex :: ZIndex -> Int
unwrapZIndex (ZIndex n) = n

-- | Background layer (0).
zIndexBackground :: ZIndex
zIndexBackground = ZIndex 0

-- | Minimum paint layer (1).
zIndexPaintMin :: ZIndex
zIndexPaintMin = ZIndex 1

-- | Maximum paint layer (99).
zIndexPaintMax :: ZIndex
zIndexPaintMax = ZIndex 99

-- | Active stroke (100).
zIndexActiveStroke :: ZIndex
zIndexActiveStroke = ZIndex 100

-- | Selection overlay (101).
zIndexSelection :: ZIndex
zIndexSelection = ZIndex 101

-- | Guides (102).
zIndexGuides :: ZIndex
zIndexGuides = ZIndex 102

-- | Tools cursor (103).
zIndexTools :: ZIndex
zIndexTools = ZIndex 103

-- | UI overlays (104).
zIndexOverlays :: ZIndex
zIndexOverlays = ZIndex 104

-- | Debug overlay (105).
zIndexDebug :: ZIndex
zIndexDebug = ZIndex 105

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                      // color
-- ═════════════════════════════════════════════════════════════════════════════

-- | RGBA color (simplified for canvas app).
type Color =
  { r :: Number  -- ^ Red (0-1)
  , g :: Number  -- ^ Green (0-1)
  , b :: Number  -- ^ Blue (0-1)
  , a :: Number  -- ^ Alpha (0-1)
  }

-- | Create a color with clamped values.
mkColor :: Number -> Number -> Number -> Number -> Color
mkColor cr cg cb ca =
  { r: clamp01 cr
  , g: clamp01 cg
  , b: clamp01 cb
  , a: clamp01 ca
  }

-- | Get red component.
colorR :: Color -> Number
colorR c = c.r

-- | Get green component.
colorG :: Color -> Number
colorG c = c.g

-- | Get blue component.
colorB :: Color -> Number
colorB c = c.b

-- | Get alpha component.
colorA :: Color -> Number
colorA c = c.a

-- | Black color.
colorBlack :: Color
colorBlack = { r: 0.0, g: 0.0, b: 0.0, a: 1.0 }

-- | White color.
colorWhite :: Color
colorWhite = { r: 1.0, g: 1.0, b: 1.0, a: 1.0 }

-- | Fully transparent.
colorTransparent :: Color
colorTransparent = { r: 0.0, g: 0.0, b: 0.0, a: 0.0 }

-- | Clamp to 0-1 range.
clamp01 :: Number -> Number
clamp01 n = max 0.0 (min 1.0 n)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                // blend modes
-- ═════════════════════════════════════════════════════════════════════════════

-- | Blend modes for layer compositing.
data BlendMode
  = BlendNormal
  | BlendMultiply
  | BlendScreen
  | BlendOverlay
  | BlendDarken
  | BlendLighten
  | BlendColorDodge
  | BlendColorBurn
  | BlendHardLight
  | BlendSoftLight
  | BlendDifference
  | BlendExclusion

derive instance eqBlendMode :: Eq BlendMode
derive instance ordBlendMode :: Ord BlendMode

instance showBlendMode :: Show BlendMode where
  show BlendNormal = "normal"
  show BlendMultiply = "multiply"
  show BlendScreen = "screen"
  show BlendOverlay = "overlay"
  show BlendDarken = "darken"
  show BlendLighten = "lighten"
  show BlendColorDodge = "color-dodge"
  show BlendColorBurn = "color-burn"
  show BlendHardLight = "hard-light"
  show BlendSoftLight = "soft-light"
  show BlendDifference = "difference"
  show BlendExclusion = "exclusion"

-- | All blend modes.
allBlendModes :: Array BlendMode
allBlendModes =
  [ BlendNormal
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
  ]

-- | Human-readable blend mode name.
blendModeName :: BlendMode -> String
blendModeName BlendNormal = "Normal"
blendModeName BlendMultiply = "Multiply"
blendModeName BlendScreen = "Screen"
blendModeName BlendOverlay = "Overlay"
blendModeName BlendDarken = "Darken"
blendModeName BlendLighten = "Lighten"
blendModeName BlendColorDodge = "Color Dodge"
blendModeName BlendColorBurn = "Color Burn"
blendModeName BlendHardLight = "Hard Light"
blendModeName BlendSoftLight = "Soft Light"
blendModeName BlendDifference = "Difference"
blendModeName BlendExclusion = "Exclusion"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

-- | Display tool info.
displayTool :: Tool -> String
displayTool t = toolName t <> " (" <> toolShortcut t <> ")"

-- | Display bounds.
displayBounds :: Bounds -> String
displayBounds b =
  "Bounds(" <> show b.x <> ", " <> show b.y <> ", " <>
  show b.width <> "x" <> show b.height <> ")"

-- | Display point.
displayPoint :: Point2D -> String
displayPoint p = "(" <> show p.x <> ", " <> show p.y <> ")"

-- | Display vector.
displayVec :: Vec2D -> String
displayVec v = "<" <> show v.vx <> ", " <> show v.vy <> ">"

-- | Display color.
displayColor :: Color -> String
displayColor c =
  "rgba(" <> show c.r <> ", " <> show c.g <> ", " <>
  show c.b <> ", " <> show c.a <> ")"

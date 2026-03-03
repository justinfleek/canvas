-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                  // canvas // physics // bounds
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Physics Bounds — Boundary handling for particle simulation.
-- |
-- | ## Design Philosophy
-- |
-- | Paint particles need boundaries to contain them. This module provides:
-- | - Hard boundaries (reflect particles)
-- | - Soft boundaries (repel particles)
-- | - Sticky boundaries (absorb velocity)
-- | - Wraparound boundaries (for infinite canvas feel)
-- |
-- | ## Boundary Types
-- |
-- | Different edges can have different behaviors:
-- | - **Canvas edge**: Hard reflect (paint bounces off)
-- | - **Layer mask**: Soft repel (paint piles up)
-- | - **Selection**: Sticky absorb (paint sticks)
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Canvas.Types

module Canvas.Physics.Bounds
  ( -- * Boundary Type
    BoundaryType
      ( HardReflect
      , SoftRepel
      , StickyAbsorb
      , Wraparound
      , Open
      )
  , boundaryTypeName
  
  -- * Boundary Config
  , BoundaryConfig
  , mkBoundaryConfig
  , defaultBoundaryConfig
  , stickyBoundaryConfig
  , softBoundaryConfig
  
  -- * Edge Configuration
  , EdgeConfig
  , mkEdgeConfig
  , uniformEdges
  , mixedEdges
  
  -- * Boundary Enforcement
  , enforceBoundary
  , enforceWithConfig
  , enforcePoint
  , enforceVelocity
  
  -- * Collision Detection
  , isOutOfBounds
  , distanceToBoundary
  , closestEdge
  , Edge(Top, Bottom, Left, Right)
  
  -- * Boundary Forces
  , computeBoundaryForce
  , softRepelForce
  , stickyAbsorbForce
  
  -- * Viewport Handling
  , clampToViewport
  , wrapAroundViewport
  , mirrorInViewport
  
  -- * Display
  , displayBoundaryType
  , displayBoundaryConfig
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

import Data.Number (abs) as Num

import Data.Number (sqrt) as Num

import Canvas.Types
  ( Point2D
  , mkPoint2D
  , Vec2D
  , mkVec2D
  , Bounds
  , mkBounds
  , boundsContains
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // boundary type
-- ═════════════════════════════════════════════════════════════════════════════

-- | How boundaries handle particles.
data BoundaryType
  = HardReflect    -- ^ Reflect velocity, conserve energy (minus damping)
  | SoftRepel      -- ^ Apply repulsion force near boundary
  | StickyAbsorb   -- ^ Absorb velocity, particle sticks
  | Wraparound     -- ^ Wrap to opposite side
  | Open           -- ^ No boundary, particles can escape

derive instance eqBoundaryType :: Eq BoundaryType
derive instance ordBoundaryType :: Ord BoundaryType

instance showBoundaryType :: Show BoundaryType where
  show HardReflect = "hard-reflect"
  show SoftRepel = "soft-repel"
  show StickyAbsorb = "sticky-absorb"
  show Wraparound = "wraparound"
  show Open = "open"

-- | Human-readable boundary name.
boundaryTypeName :: BoundaryType -> String
boundaryTypeName HardReflect = "Hard Reflect"
boundaryTypeName SoftRepel = "Soft Repel"
boundaryTypeName StickyAbsorb = "Sticky Absorb"
boundaryTypeName Wraparound = "Wraparound"
boundaryTypeName Open = "Open"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                       // edge
-- ═════════════════════════════════════════════════════════════════════════════

-- | Canvas edge identifier.
data Edge = Top | Bottom | Left | Right

derive instance eqEdge :: Eq Edge
derive instance ordEdge :: Ord Edge

instance showEdge :: Show Edge where
  show Top = "top"
  show Bottom = "bottom"
  show Left = "left"
  show Right = "right"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // boundary config
-- ═════════════════════════════════════════════════════════════════════════════

-- | Configuration for boundary behavior.
type BoundaryConfig =
  { boundaryType :: BoundaryType
  , damping :: Number            -- ^ Velocity reduction on collision (0-1)
  , repelDistance :: Number      -- ^ Distance for soft repel (pixels)
  , repelStrength :: Number      -- ^ Force strength for soft repel
  , stickyThreshold :: Number    -- ^ Velocity below which particle sticks
  }

-- | Create boundary config.
mkBoundaryConfig :: BoundaryType -> Number -> BoundaryConfig
mkBoundaryConfig btype damp =
  { boundaryType: btype
  , damping: max 0.0 (min 1.0 damp)
  , repelDistance: 20.0
  , repelStrength: 1000.0
  , stickyThreshold: 5.0
  }

-- | Default config (hard reflect with 40% damping).
defaultBoundaryConfig :: BoundaryConfig
defaultBoundaryConfig = mkBoundaryConfig HardReflect 0.6

-- | Sticky boundary config.
stickyBoundaryConfig :: BoundaryConfig
stickyBoundaryConfig = mkBoundaryConfig StickyAbsorb 0.0

-- | Soft boundary config.
softBoundaryConfig :: BoundaryConfig
softBoundaryConfig = 
  let base = mkBoundaryConfig SoftRepel 0.3
  in base { repelDistance = 30.0, repelStrength = 2000.0 }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                             // edge config
-- ═════════════════════════════════════════════════════════════════════════════

-- | Per-edge boundary configuration.
type EdgeConfig =
  { top :: BoundaryConfig
  , bottom :: BoundaryConfig
  , left :: BoundaryConfig
  , right :: BoundaryConfig
  }

-- | Create edge config with same config for all edges.
mkEdgeConfig :: BoundaryConfig -> EdgeConfig
mkEdgeConfig c = { top: c, bottom: c, left: c, right: c }

-- | Uniform edges (same behavior all around).
uniformEdges :: BoundaryType -> Number -> EdgeConfig
uniformEdges btype damp = mkEdgeConfig (mkBoundaryConfig btype damp)

-- | Mixed edges (e.g., open top, reflect others).
mixedEdges 
  :: BoundaryConfig  -- ^ top
  -> BoundaryConfig  -- ^ bottom
  -> BoundaryConfig  -- ^ left
  -> BoundaryConfig  -- ^ right
  -> EdgeConfig
mixedEdges t b l r = { top: t, bottom: b, left: l, right: r }

-- | Get config for specific edge.
getEdgeConfig :: Edge -> EdgeConfig -> BoundaryConfig
getEdgeConfig Top edges = edges.top
getEdgeConfig Bottom edges = edges.bottom
getEdgeConfig Left edges = edges.left
getEdgeConfig Right edges = edges.right

-- ═════════════════════════════════════════════════════════════════════════════
--                                                       // boundary enforcement
-- ═════════════════════════════════════════════════════════════════════════════

-- | Particle state for boundary enforcement.
type ParticleState =
  { x :: Number
  , y :: Number
  , vx :: Number
  , vy :: Number
  }

-- | Enforce boundary on particle with default config.
enforceBoundary :: Bounds -> ParticleState -> ParticleState
enforceBoundary = enforceWithConfig (mkEdgeConfig defaultBoundaryConfig)

-- | Enforce boundary with edge configuration.
enforceWithConfig :: EdgeConfig -> Bounds -> ParticleState -> ParticleState
enforceWithConfig edges bounds p =
  let
    minX = bounds.x
    maxX = bounds.x + bounds.width
    minY = bounds.y
    maxY = bounds.y + bounds.height
    
    -- Check each edge
    p1 = if p.x < minX
      then applyBoundary (getEdgeConfig Left edges) p minX true true
      else if p.x > maxX
        then applyBoundary (getEdgeConfig Right edges) p maxX true false
        else p
    
    p2 = if p1.y < minY
      then applyBoundary (getEdgeConfig Top edges) p1 minY false true
      else if p1.y > maxY
        then applyBoundary (getEdgeConfig Bottom edges) p1 maxY false false
        else p1
  in
    p2

-- | Apply boundary behavior at specific edge.
applyBoundary :: BoundaryConfig -> ParticleState -> Number -> Boolean -> Boolean -> ParticleState
applyBoundary config p edgePos isHorizontal isMin =
  case config.boundaryType of
    HardReflect ->
      if isHorizontal
        then p { x = edgePos, vx = negate p.vx * config.damping }
        else p { y = edgePos, vy = negate p.vy * config.damping }
    
    StickyAbsorb ->
      let
        speed = if isHorizontal then Num.abs p.vx else Num.abs p.vy
      in
        if speed < config.stickyThreshold
          then
            if isHorizontal
              then p { x = edgePos, vx = 0.0 }
              else p { y = edgePos, vy = 0.0 }
          else
            -- Still moving, apply hard reflect
            if isHorizontal
              then p { x = edgePos, vx = negate p.vx * config.damping }
              else p { y = edgePos, vy = negate p.vy * config.damping }
    
    Wraparound ->
      -- Wrap position to opposite side (handled by wrapAroundViewport)
      p
    
    SoftRepel ->
      -- Soft repel is handled by force computation, just clamp position
      if isHorizontal
        then p { x = edgePos }
        else p { y = edgePos }
    
    Open ->
      -- No enforcement, particle escapes
      p

-- | Enforce just position (clamp to bounds).
enforcePoint :: Bounds -> Point2D -> Point2D
enforcePoint bounds pt =
  let
    x = max bounds.x (min (bounds.x + bounds.width) pt.x)
    y = max bounds.y (min (bounds.y + bounds.height) pt.y)
  in
    mkPoint2D x y

-- | Enforce velocity based on position (for soft boundaries).
enforceVelocity :: Bounds -> Number -> ParticleState -> ParticleState
enforceVelocity bounds repelDist p =
  let
    force = computeBoundaryForce bounds repelDist 1000.0 (mkPoint2D p.x p.y)
    -- Apply small impulse toward interior
    scale = 0.1
  in
    p { vx = p.vx + force.vx * scale
      , vy = p.vy + force.vy * scale
      }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // collision detection
-- ═════════════════════════════════════════════════════════════════════════════

-- | Check if point is outside bounds.
isOutOfBounds :: Bounds -> Point2D -> Boolean
isOutOfBounds bounds pt =
  pt.x < bounds.x || 
  pt.x > bounds.x + bounds.width ||
  pt.y < bounds.y || 
  pt.y > bounds.y + bounds.height

-- | Distance to nearest boundary edge.
distanceToBoundary :: Bounds -> Point2D -> Number
distanceToBoundary bounds pt =
  let
    distLeft = pt.x - bounds.x
    distRight = bounds.x + bounds.width - pt.x
    distTop = pt.y - bounds.y
    distBottom = bounds.y + bounds.height - pt.y
  in
    min (min distLeft distRight) (min distTop distBottom)

-- | Find closest edge.
closestEdge :: Bounds -> Point2D -> Edge
closestEdge bounds pt =
  let
    distLeft = pt.x - bounds.x
    distRight = bounds.x + bounds.width - pt.x
    distTop = pt.y - bounds.y
    distBottom = bounds.y + bounds.height - pt.y
    
    minH = if distLeft < distRight then { d: distLeft, e: Left } else { d: distRight, e: Right }
    minV = if distTop < distBottom then { d: distTop, e: Top } else { d: distBottom, e: Bottom }
  in
    if minH.d < minV.d then minH.e else minV.e

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // boundary forces
-- ═════════════════════════════════════════════════════════════════════════════

-- | Compute repulsion force from boundaries.
computeBoundaryForce :: Bounds -> Number -> Number -> Point2D -> Vec2D
computeBoundaryForce bounds repelDist strength pt =
  let
    -- Left edge
    distLeft = pt.x - bounds.x
    forceLeft = if distLeft < repelDist && distLeft > 0.0
      then softRepelForce distLeft repelDist strength
      else 0.0
    
    -- Right edge
    distRight = bounds.x + bounds.width - pt.x
    forceRight = if distRight < repelDist && distRight > 0.0
      then negate (softRepelForce distRight repelDist strength)
      else 0.0
    
    -- Top edge
    distTop = pt.y - bounds.y
    forceTop = if distTop < repelDist && distTop > 0.0
      then softRepelForce distTop repelDist strength
      else 0.0
    
    -- Bottom edge
    distBottom = bounds.y + bounds.height - pt.y
    forceBottom = if distBottom < repelDist && distBottom > 0.0
      then negate (softRepelForce distBottom repelDist strength)
      else 0.0
  in
    mkVec2D (forceLeft + forceRight) (forceTop + forceBottom)

-- | Soft repulsion force (increases as distance decreases).
-- |
-- | Uses inverse square falloff: F = strength * (1 - d/maxD)^2
softRepelForce :: Number -> Number -> Number -> Number
softRepelForce distance maxDistance strength =
  if distance >= maxDistance
    then 0.0
    else
      let ratio = 1.0 - distance / maxDistance
      in strength * ratio * ratio

-- | Sticky absorption force (decays velocity).
stickyAbsorbForce :: Number -> Number -> Number
stickyAbsorbForce velocity threshold =
  if Num.abs velocity < threshold
    then negate velocity  -- Completely stop
    else negate (velocity * 0.5)  -- Partial absorption

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // viewport handling
-- ═════════════════════════════════════════════════════════════════════════════

-- | Clamp position to viewport bounds.
clampToViewport :: Bounds -> Point2D -> Point2D
clampToViewport bounds pt =
  mkPoint2D
    (max bounds.x (min (bounds.x + bounds.width) pt.x))
    (max bounds.y (min (bounds.y + bounds.height) pt.y))

-- | Wrap position around viewport (for infinite canvas feel).
wrapAroundViewport :: Bounds -> Point2D -> Point2D
wrapAroundViewport bounds pt =
  let
    -- Wrap X
    x = if pt.x < bounds.x
      then pt.x + bounds.width
      else if pt.x > bounds.x + bounds.width
        then pt.x - bounds.width
        else pt.x
    
    -- Wrap Y
    y = if pt.y < bounds.y
      then pt.y + bounds.height
      else if pt.y > bounds.y + bounds.height
        then pt.y - bounds.height
        else pt.y
  in
    mkPoint2D x y

-- | Mirror position in viewport (reflect at edges).
mirrorInViewport :: Bounds -> Point2D -> Point2D
mirrorInViewport bounds pt =
  let
    -- Mirror X
    x = if pt.x < bounds.x
      then 2.0 * bounds.x - pt.x
      else if pt.x > bounds.x + bounds.width
        then 2.0 * (bounds.x + bounds.width) - pt.x
        else pt.x
    
    -- Mirror Y
    y = if pt.y < bounds.y
      then 2.0 * bounds.y - pt.y
      else if pt.y > bounds.y + bounds.height
        then 2.0 * (bounds.y + bounds.height) - pt.y
        else pt.y
  in
    mkPoint2D x y

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

displayBoundaryType :: BoundaryType -> String
displayBoundaryType = boundaryTypeName

displayBoundaryConfig :: BoundaryConfig -> String
displayBoundaryConfig c =
  "BoundaryConfig { type=" <> show c.boundaryType <>
  ", damping=" <> show c.damping <> " }"

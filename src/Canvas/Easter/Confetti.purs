-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                              // canvas // easter // confetti
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Confetti Particle System
-- |
-- | A celebratory particle explosion for easter eggs and achievements.
-- | Particles fall with realistic physics including gravity, air resistance,
-- | and rotational tumbling.
-- |
-- | ## Usage
-- |
-- | ```purescript
-- | import Canvas.Easter.Confetti as Confetti
-- |
-- | -- Create an explosion
-- | let confetti = Confetti.explode 
-- |       { x: canvasWidth / 2.0, y: canvasHeight / 2.0 }
-- |       Confetti.defaultConfig
-- |
-- | -- Update each frame
-- | let updatedConfetti = Confetti.update 0.016 confetti
-- |
-- | -- Render
-- | let elements = Confetti.render confetti
-- | ```

module Canvas.Easter.Confetti
  ( -- * Config
    ConfettiConfig
  , defaultConfig
  , setParticleCount
  , setColors
  , setGravity
  , setSpread
  
  -- * State
  , ConfettiState
  , noConfetti
  , isActive
  , particleCount
  
  -- * Actions
  , explode
  , explodeAt
  , update
  
  -- * Rendering
  , render
  , renderParticle
  
  -- * Particle Types
  , ConfettiParticle
  , ConfettiShape(..)
  ) where

import Prelude
  ( map
  , (+)
  , (-)
  , (*)
  , (/)
  , (>)
  , (<)
  , (>=)
  , (<>)
  , max
  , min
  , show
  , negate
  )

import Data.Maybe (Maybe(Just, Nothing))

import Data.Array (filter, length, range)
import Data.Int (toNumber)
import Data.Tuple (Tuple(Tuple))

import Hydrogen.Render.Element as E
import Hydrogen.Render.Element (Element)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // confetti // config
-- ═════════════════════════════════════════════════════════════════════════════

-- | Configuration for confetti explosion
type ConfettiConfig =
  { particleCount :: Int      -- ^ Number of particles to spawn
  , colors :: Array String    -- ^ Array of CSS colors
  , gravity :: Number         -- ^ Gravity strength (px/s²)
  , initialVelocity :: Number -- ^ Initial upward velocity (px/s)
  , spread :: Number          -- ^ Horizontal spread angle (radians)
  , drag :: Number            -- ^ Air resistance (0-1)
  , lifetime :: Number        -- ^ Particle lifetime (seconds)
  , size :: Number            -- ^ Base particle size (px)
  , sizeVariance :: Number    -- ^ Size randomization (0-1)
  }

-- | Default festive configuration
defaultConfig :: ConfettiConfig
defaultConfig =
  { particleCount: 100
  , colors: 
      [ "#ff6b6b"  -- Red
      , "#4ecdc4"  -- Teal
      , "#ffe66d"  -- Yellow
      , "#95e1d3"  -- Mint
      , "#f38181"  -- Coral
      , "#aa96da"  -- Purple
      , "#fcbad3"  -- Pink
      , "#a8d8ea"  -- Sky blue
      ]
  , gravity: 400.0
  , initialVelocity: 600.0
  , spread: 1.2  -- ~70 degrees
  , drag: 0.02
  , lifetime: 4.0
  , size: 10.0
  , sizeVariance: 0.5
  }

-- | Set particle count
setParticleCount :: Int -> ConfettiConfig -> ConfettiConfig
setParticleCount n cfg = cfg { particleCount = max 1 (min 500 n) }

-- | Set colors
setColors :: Array String -> ConfettiConfig -> ConfettiConfig
setColors cs cfg = cfg { colors = cs }

-- | Set gravity
setGravity :: Number -> ConfettiConfig -> ConfettiConfig
setGravity g cfg = cfg { gravity = g }

-- | Set spread angle
setSpread :: Number -> ConfettiConfig -> ConfettiConfig
setSpread s cfg = cfg { spread = s }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                       // confetti // particle
-- ═════════════════════════════════════════════════════════════════════════════

-- | Single confetti particle
type ConfettiParticle =
  { x :: Number           -- ^ X position (px)
  , y :: Number           -- ^ Y position (px)
  , vx :: Number          -- ^ X velocity (px/s)
  , vy :: Number          -- ^ Y velocity (px/s)
  , rotation :: Number    -- ^ Rotation angle (radians)
  , angularVel :: Number  -- ^ Angular velocity (rad/s)
  , size :: Number        -- ^ Size (px)
  , color :: String       -- ^ CSS color
  , age :: Number         -- ^ Time alive (seconds)
  , lifetime :: Number    -- ^ Max lifetime (seconds)
  , shape :: ConfettiShape -- ^ Particle shape
  }

-- | Particle shapes
data ConfettiShape
  = Square
  | Circle
  | Rectangle
  | Star

-- | Create a particle with deterministic "random" based on index
createParticle :: Int -> Number -> Number -> ConfettiConfig -> ConfettiParticle
createParticle idx x y cfg =
  let
    -- Pseudo-random values based on index (deterministic for reproducibility)
    seed = toNumber idx
    rand1 = pseudoRandom seed
    rand2 = pseudoRandom (seed + 0.1)
    rand3 = pseudoRandom (seed + 0.2)
    rand4 = pseudoRandom (seed + 0.3)
    rand5 = pseudoRandom (seed + 0.4)
    
    -- Calculate initial velocity with spread
    angle = (rand1 - 0.5) * cfg.spread - 1.5708  -- Centered around up (-π/2)
    speed = cfg.initialVelocity * (0.7 + rand2 * 0.6)
    vx = speed * cosApprox angle
    vy = speed * sinApprox angle
    
    -- Random size
    sizeVar = 1.0 + (rand3 - 0.5) * cfg.sizeVariance
    size = cfg.size * sizeVar
    
    -- Random color from palette
    colorIdx = intMod idx (length cfg.colors)
    color = indexOr "#ffffff" colorIdx cfg.colors
    
    -- Random rotation
    rotation = rand4 * 6.283  -- 0 to 2π
    angularVel = (rand5 - 0.5) * 10.0  -- -5 to 5 rad/s
    
    -- Random shape
    shape = case intMod idx 4 of
      0 -> Square
      1 -> Circle
      2 -> Rectangle
      _ -> Star
  in
    { x: x
    , y: y
    , vx: vx
    , vy: vy
    , rotation: rotation
    , angularVel: angularVel
    , size: size
    , color: color
    , age: 0.0
    , lifetime: cfg.lifetime * (0.8 + rand1 * 0.4)
    , shape: shape
    }

-- | Update a particle with physics
updateParticle :: Number -> Number -> Number -> ConfettiParticle -> ConfettiParticle
updateParticle dt gravity drag p =
  let
    -- Apply drag
    dragFactor = 1.0 - drag
    newVx = p.vx * dragFactor
    newVy = p.vy * dragFactor + gravity * dt
    
    -- Update position
    newX = p.x + newVx * dt
    newY = p.y + newVy * dt
    
    -- Update rotation
    newRotation = p.rotation + p.angularVel * dt
    
    -- Age
    newAge = p.age + dt
  in
    p { x = newX
      , y = newY
      , vx = newVx
      , vy = newVy
      , rotation = newRotation
      , age = newAge
      }

-- | Is particle still alive?
isAlive :: ConfettiParticle -> Boolean
isAlive p = p.age < p.lifetime

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // confetti // state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Confetti system state
type ConfettiState =
  { particles :: Array ConfettiParticle
  , config :: ConfettiConfig
  , active :: Boolean
  }

-- | No active confetti
noConfetti :: ConfettiState
noConfetti =
  { particles: []
  , config: defaultConfig
  , active: false
  }

-- | Is confetti active?
isActive :: ConfettiState -> Boolean
isActive state = state.active

-- | Get particle count
particleCount :: ConfettiState -> Int
particleCount state = length state.particles

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // confetti // actions
-- ═════════════════════════════════════════════════════════════════════════════

-- | Trigger confetti explosion at center of screen
explode :: { x :: Number, y :: Number } -> ConfettiConfig -> ConfettiState
explode origin cfg = explodeAt origin.x origin.y cfg

-- | Trigger confetti explosion at specific position
explodeAt :: Number -> Number -> ConfettiConfig -> ConfettiState
explodeAt x y cfg =
  let
    indices = range 0 (cfg.particleCount - 1)
    particles = map (\i -> createParticle i x y cfg) indices
  in
    { particles: particles
    , config: cfg
    , active: true
    }

-- | Update confetti state (call each frame)
update :: Number -> ConfettiState -> ConfettiState
update dt state =
  if state.active then
    let
      -- Update all particles with physics
      updated = map (updateParticle dt state.config.gravity state.config.drag) state.particles
      
      -- Remove dead particles
      alive = filter isAlive updated
      
      -- Deactivate if no particles left
      stillActive = length alive > 0
    in
      state { particles = alive, active = stillActive }
  else
    state

-- ═════════════════════════════════════════════════════════════════════════════
--                                                      // confetti // rendering
-- ═════════════════════════════════════════════════════════════════════════════

-- | Render all confetti particles
render :: forall msg. ConfettiState -> Element msg
render state =
  if state.active then
    E.div_
      ([ E.class_ "confetti-container" ] <>
        E.styles
          [ Tuple "position" "fixed"
          , Tuple "top" "0"
          , Tuple "left" "0"
          , Tuple "width" "100%"
          , Tuple "height" "100%"
          , Tuple "pointer-events" "none"
          , Tuple "z-index" "9999"
          , Tuple "overflow" "hidden"
          ])
      (map renderParticle state.particles)
  else
    E.empty

-- | Render a single particle
renderParticle :: forall msg. ConfettiParticle -> Element msg
renderParticle p =
  let
    -- Fade out as particle ages
    opacity = max 0.0 (1.0 - (p.age / p.lifetime))
    
    -- Transform string
    transform = "translate(" <> show p.x <> "px, " <> show p.y <> "px) " <>
                "rotate(" <> show (p.rotation * 57.3) <> "deg)"
    
    -- Size based on shape
    width = case p.shape of
      Rectangle -> p.size * 1.5
      _ -> p.size
    
    height = case p.shape of
      Rectangle -> p.size * 0.6
      _ -> p.size
    
    borderRadius = case p.shape of
      Circle -> "50%"
      Star -> "2px"
      _ -> "2px"
  in
    E.div_
      ([ E.class_ "confetti-particle" ] <>
        E.styles
          [ Tuple "position" "absolute"
          , Tuple "width" (show width <> "px")
          , Tuple "height" (show height <> "px")
          , Tuple "background-color" p.color
          , Tuple "border-radius" borderRadius
          , Tuple "transform" transform
          , Tuple "opacity" (show opacity)
          , Tuple "will-change" "transform, opacity"
          ])
      []

-- ═════════════════════════════════════════════════════════════════════════════
--                                                             // math // helpers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Pseudo-random number generator (0.0 to 1.0)
-- | Uses a simple linear congruential generator
pseudoRandom :: Number -> Number
pseudoRandom seed =
  let
    a = 1664525.0
    c = 1013904223.0
    m = 4294967296.0
    next = (a * seed + c) - (floorNum ((a * seed + c) / m)) * m
  in
    next / m

-- | Floor function approximation
floorNum :: Number -> Number
floorNum n = n - (n - (n * 0.0 + toNumber (truncateNum n)))

-- | Truncate to integer
truncateNum :: Number -> Int
truncateNum n = if n < 0.0 then negate (truncatePos (negate n)) else truncatePos n

truncatePos :: Number -> Int
truncatePos n = 
  -- Simple truncation using Int conversion semantics
  let scaled = n * 1.0 in
  if scaled > 2147483647.0 then 2147483647
  else if scaled < 0.0 then 0
  else roundToInt scaled

-- | Round to nearest int (using built-in)
roundToInt :: Number -> Int
roundToInt n = 
  -- Approximation: add 0.5 and truncate
  let adjusted = n + 0.5
  in if adjusted < 1.0 then 0 else approximateInt adjusted

-- | Very rough int approximation 
approximateInt :: Number -> Int
approximateInt n =
  -- Count how many 1s fit
  countOnes 0 n

countOnes :: Int -> Number -> Int
countOnes acc remaining =
  if remaining < 1.0 then acc
  else countOnes (acc + 1) (remaining - 1.0)

-- | Integer modulo
intMod :: Int -> Int -> Int
intMod a b = a - (a / b) * b

-- | Safe array indexing with default
indexOr :: forall a. a -> Int -> Array a -> a
indexOr def idx arr = case indexArray idx arr of
  Nothing -> def
  Just x -> x

-- | Array indexing (simplified)
indexArray :: forall a. Int -> Array a -> Maybe a
indexArray idx arr = 
  if idx < 0 then Nothing
  else if idx >= length arr then Nothing
  else unsafeIndex idx arr

-- | Unsafe array index (assumes bounds checked)
foreign import unsafeIndex :: forall a. Int -> Array a -> Maybe a

-- | Cosine approximation using Taylor series
cosApprox :: Number -> Number
cosApprox x =
  let x2 = x * x
      x4 = x2 * x2
      x6 = x4 * x2
  in 1.0 - x2 / 2.0 + x4 / 24.0 - x6 / 720.0

-- | Sine approximation using Taylor series
sinApprox :: Number -> Number
sinApprox x =
  let x3 = x * x * x
      x5 = x3 * x * x
      x7 = x5 * x * x
  in x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0

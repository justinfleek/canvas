-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                 // canvas // paint // particle
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Paint Particle System — SPH fluid simulation for realistic paint.
-- |
-- | ## Design Philosophy
-- |
-- | Every paint stroke is a collection of particles following SPH physics.
-- | When you tilt your phone, particles flow according to:
-- |
-- |   F_total = F_pressure + F_viscosity + F_gravity + F_surface
-- |
-- | ## Paint Types (from Hydrogen Schema)
-- |
-- | - **Watercolor**: Low viscosity, high bleed, granulation
-- | - **Oil**: High viscosity, slow drying, impasto support
-- | - **Acrylic**: Medium viscosity, fast drying
-- | - **Gouache**: Opaque, re-wettable
-- | - **Ink**: Very low viscosity, permanent when dry
-- | - **Honey**: Ultra-high viscosity, supports own weight
-- |
-- | ## Integration
-- |
-- | Wraps Hydrogen.Schema.Physics.Fluid.Particle (SPH kernels)
-- | and Hydrogen.Schema.Brush.WetMedia (paint properties).
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Hydrogen.Schema.Physics.Fluid.Particle
-- | - Hydrogen.Schema.Physics.Fluid.Solver
-- | - Hydrogen.Schema.Brush.WetMedia
-- | - Canvas.Types
-- | - Canvas.Physics.Gravity

module Canvas.Paint.Particle
  ( -- * Paint Particle
    PaintParticle
  , Particle
  , mkPaintParticle
  , mkPaintParticleWithHeight
  , particlePosition
  , particleVelocity
  , particleColor
  , particleColorHex
  , particleWetness
  , particleViscosity
  , particleRadius
  , particleHeight
  , setParticleHeight
  , addParticleHeight
  
  -- * Paint System (collection of particles)
  , PaintSystem
  , mkPaintSystem
  , emptyPaintSystem
  , systemParticles
  , allParticles
  , systemBounds
  , addParticle
  , removeParticle
  , clearParticles
  , particleCount
  
  -- * Paint Presets
  , PaintPreset
      ( Watercolor
      , OilPaint
      , Acrylic
      , Gouache
      , Ink
      , Honey
      )
  , allPaintPresets
  , presetName
  , presetProperties
  
  -- * Simulation Step
  , simulateStep
  , applyGravity
  , computeDensities
  , computePressures
  , computeForces
  , integrateParticles
  , enforceBounds
  , applyImpastoStacking
  
  -- * Drying
  , applyDrying
  , commitDriedParticles
  , isDried
  
  -- * Drag Physics (finger painting)
  , BrushDrag
  , applyBrushDrag
  , mkBrushDrag
  
  -- * Analysis
  , systemEnergy
  , averageWetness
  , maxVelocity
  
  -- * Display
  , displayParticle
  , displaySystem
  , displayPreset
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
  , not
  , otherwise
  )

import Data.Array (length, filter, snoc, foldl) as Array
import Data.Number (sqrt) as Num
import Data.Int (toNumber, floor) as Int

-- Hydrogen SPH Particle System
import Hydrogen.Schema.Physics.Fluid.Particle as SPH

-- Hydrogen Fluid Solver (for presets like honey)
import Hydrogen.Schema.Physics.Fluid.Solver as Solver

-- Hydrogen WetMedia (paint properties)
import Hydrogen.Schema.Brush.WetMedia as WetMedia
import Hydrogen.Schema.Brush.WetMedia.Atoms
  ( Wetness
  , Viscosity
  , DryingRate
  , mkWetness
  , mkViscosity
  , mkDryingRate
  , unwrapWetness
  , unwrapViscosity
  )
import Hydrogen.Schema.Brush.WetMedia.Dynamics
  ( applyDrying
  ) as WMDynamics

-- Canvas Types
import Canvas.Types
  ( Point2D
  , mkPoint2D
  , Vec2D
  , mkVec2D
  , Bounds
  , mkBounds
  , boundsContains
  , Color
  , mkColor
  , colorBlack
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                             // paint particle
-- ═════════════════════════════════════════════════════════════════════════════

-- | A single paint particle with physical and visual properties.
-- |
-- | Combines SPH physics particle with wet media paint properties.
-- |
-- | ## Impasto Physics
-- |
-- | The `height` field tracks paint thickness for impasto effects.
-- | When particles overlap, their heights accumulate - simulating how
-- | thick paint builds up on a real canvas. Height affects:
-- | - Z-ordering (taller paint renders on top)
-- | - Visual appearance (thicker paint = more opaque, cast shadows)
-- | - Flow resistance (thick paint resists gravity more)
type PaintParticle =
  { id :: Int                  -- ^ Unique identifier
  , x :: Number                -- ^ X position (canvas coords)
  , y :: Number                -- ^ Y position (canvas coords)
  , vx :: Number               -- ^ X velocity (px/s)
  , vy :: Number               -- ^ Y velocity (px/s)
  , mass :: Number             -- ^ Particle mass
  , density :: Number          -- ^ Computed SPH density
  , pressure :: Number         -- ^ Computed SPH pressure
  , color :: Color             -- ^ Pigment color (RGBA)
  , wetness :: Wetness         -- ^ How wet (affects flow)
  , viscosity :: Viscosity     -- ^ Resistance to flow
  , dryingRate :: DryingRate   -- ^ How fast it dries
  , radius :: Number           -- ^ Visual radius (px)
  , height :: Number           -- ^ Paint thickness/height for impasto (0.0 = flat, 1.0+ = thick)
  , age :: Number              -- ^ Time since creation (s)
  }

-- | Create a paint particle at position with color.
mkPaintParticle 
  :: Int           -- ^ ID
  -> Number        -- ^ X position
  -> Number        -- ^ Y position
  -> Color         -- ^ Paint color
  -> Wetness       -- ^ Initial wetness
  -> Viscosity     -- ^ Paint viscosity
  -> PaintParticle
mkPaintParticle pid px py pcolor pwet pvisc =
  { id: pid
  , x: px
  , y: py
  , vx: 0.0
  , vy: 0.0
  , mass: 1.0
  , density: 1000.0
  , pressure: 0.0
  , color: pcolor
  , wetness: pwet
  , viscosity: pvisc
  , dryingRate: mkDryingRate 10.0  -- Default: medium drying
  , radius: 3.0                     -- Default: 3px radius
  , height: 0.1                     -- Default: thin layer of paint
  , age: 0.0
  }

-- | Create a paint particle with explicit height (for impasto).
mkPaintParticleWithHeight
  :: Int           -- ^ ID
  -> Number        -- ^ X position
  -> Number        -- ^ Y position
  -> Color         -- ^ Paint color
  -> Wetness       -- ^ Initial wetness
  -> Viscosity     -- ^ Paint viscosity
  -> Number        -- ^ Initial height/thickness
  -> PaintParticle
mkPaintParticleWithHeight pid px py pcolor pwet pvisc pheight =
  { id: pid
  , x: px
  , y: py
  , vx: 0.0
  , vy: 0.0
  , mass: 1.0
  , density: 1000.0
  , pressure: 0.0
  , color: pcolor
  , wetness: pwet
  , viscosity: pvisc
  , dryingRate: mkDryingRate 10.0
  , radius: 3.0
  , height: pheight
  , age: 0.0
  }

-- | Get particle position.
particlePosition :: PaintParticle -> Point2D
particlePosition p = mkPoint2D p.x p.y

-- | Get particle velocity.
particleVelocity :: PaintParticle -> Vec2D
particleVelocity p = mkVec2D p.vx p.vy

-- | Get particle color.
particleColor :: PaintParticle -> Color
particleColor p = p.color

-- | Get particle wetness.
particleWetness :: PaintParticle -> Wetness
particleWetness p = p.wetness

-- | Get particle viscosity.
particleViscosity :: PaintParticle -> Viscosity
particleViscosity p = p.viscosity

-- | Get particle radius.
particleRadius :: PaintParticle -> Number
particleRadius p = p.radius

-- | Get particle height (thickness for impasto).
particleHeight :: PaintParticle -> Number
particleHeight p = p.height

-- | Set particle height (for impasto stacking).
setParticleHeight :: Number -> PaintParticle -> PaintParticle
setParticleHeight h p = p { height = h }

-- | Add to particle height (accumulate impasto).
addParticleHeight :: Number -> PaintParticle -> PaintParticle
addParticleHeight dh p = p { height = p.height + dh }

-- | Get particle color as hex string (for SVG rendering).
-- |
-- | Converts 0-1 RGBA to #RRGGBB hex format.
particleColorHex :: PaintParticle -> String
particleColorHex p = colorToHex p.color

-- | Type alias for View.purs compatibility.
type Particle = PaintParticle

-- | Convert Color (0-1 floats) to hex string.
colorToHex :: Color -> String
colorToHex c = 
  let
    -- Convert 0-1 float to 0-255 int, then to 2-char hex
    toHex2 :: Number -> String
    toHex2 n = 
      let 
        i = Int.floor (n * 255.0)
        hi = i / 16
        lo = i - (hi * 16)
      in hexDigit hi <> hexDigit lo
    
    hexDigit :: Int -> String
    hexDigit d
      | d < 0 = "0"
      | d == 0 = "0"
      | d == 1 = "1"
      | d == 2 = "2"
      | d == 3 = "3"
      | d == 4 = "4"
      | d == 5 = "5"
      | d == 6 = "6"
      | d == 7 = "7"
      | d == 8 = "8"
      | d == 9 = "9"
      | d == 10 = "a"
      | d == 11 = "b"
      | d == 12 = "c"
      | d == 13 = "d"
      | d == 14 = "e"
      | otherwise = "f"
  in
    "#" <> toHex2 c.r <> toHex2 c.g <> toHex2 c.b

-- ═════════════════════════════════════════════════════════════════════════════
--                                                               // paint system
-- ═════════════════════════════════════════════════════════════════════════════

-- | Collection of paint particles with simulation parameters.
type PaintSystem =
  { particles :: Array PaintParticle
  , bounds :: Bounds                    -- ^ Canvas bounds
  , smoothingRadius :: Number           -- ^ SPH kernel radius
  , restDensity :: Number               -- ^ Target fluid density
  , stiffness :: Number                 -- ^ Pressure stiffness (k)
  , gravityX :: Number                  -- ^ Current gravity X
  , gravityY :: Number                  -- ^ Current gravity Y
  , nextId :: Int                       -- ^ Next particle ID
  , preset :: PaintPreset               -- ^ Current paint type
  }

-- | Create a paint system with bounds and preset.
mkPaintSystem :: Bounds -> PaintPreset -> PaintSystem
mkPaintSystem systemBounds paintPreset =
  { particles: []
  , bounds: systemBounds
  , smoothingRadius: 15.0              -- 15px kernel radius
  , restDensity: 1000.0
  , stiffness: presetStiffness paintPreset
  , gravityX: 0.0
  , gravityY: 0.0
  , nextId: 0
  , preset: paintPreset
  }

-- | Empty paint system (default bounds).
emptyPaintSystem :: PaintSystem
emptyPaintSystem = mkPaintSystem (mkBounds 0.0 0.0 1920.0 1080.0) Watercolor

-- | Get all particles.
systemParticles :: PaintSystem -> Array PaintParticle
systemParticles sys = sys.particles

-- | Get all particles (alias for View.purs).
allParticles :: PaintSystem -> Array PaintParticle
allParticles = systemParticles

-- | Get system bounds.
systemBounds :: PaintSystem -> Bounds
systemBounds sys = sys.bounds

-- | Add a particle at position with current preset's properties.
addParticle :: PaintSystem -> Number -> Number -> Color -> PaintSystem
addParticle sys px py pcolor =
  let
    props = presetProperties sys.preset
    newParticle = mkPaintParticle sys.nextId px py pcolor props.wetness props.viscosity
  in
    sys 
      { particles = Array.snoc sys.particles newParticle
      , nextId = sys.nextId + 1
      }

-- | Remove a particle by ID.
removeParticle :: PaintSystem -> Int -> PaintSystem
removeParticle sys pid =
  sys { particles = Array.filter (\p -> p.id /= pid) sys.particles }

-- | Clear all particles.
clearParticles :: PaintSystem -> PaintSystem
clearParticles sys = sys { particles = [], nextId = 0 }

-- | Get particle count.
particleCount :: PaintSystem -> Int
particleCount sys = Array.length sys.particles

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // paint presets
-- ═════════════════════════════════════════════════════════════════════════════

-- | Paint preset types with distinct physical behaviors.
data PaintPreset
  = Watercolor     -- ^ Low viscosity, high bleed, granulation
  | OilPaint       -- ^ High viscosity, slow drying, impasto
  | Acrylic        -- ^ Medium viscosity, fast drying
  | Gouache        -- ^ Opaque, re-wettable
  | Ink            -- ^ Very low viscosity, permanent
  | Honey          -- ^ Ultra-high viscosity, supports own weight

derive instance eqPaintPreset :: Eq PaintPreset
derive instance ordPaintPreset :: Ord PaintPreset

instance showPaintPreset :: Show PaintPreset where
  show Watercolor = "watercolor"
  show OilPaint = "oil"
  show Acrylic = "acrylic"
  show Gouache = "gouache"
  show Ink = "ink"
  show Honey = "honey"

-- | All available presets.
allPaintPresets :: Array PaintPreset
allPaintPresets = [Watercolor, OilPaint, Acrylic, Gouache, Ink, Honey]

-- | Human-readable preset name.
presetName :: PaintPreset -> String
presetName Watercolor = "Watercolor"
presetName OilPaint = "Oil Paint"
presetName Acrylic = "Acrylic"
presetName Gouache = "Gouache"
presetName Ink = "Ink"
presetName Honey = "Honey"

-- | Physical properties for each preset.
type PresetProperties =
  { wetness :: Wetness
  , viscosity :: Viscosity
  , dryingRate :: DryingRate
  , bleedRate :: Number      -- ^ Edge spreading (0-1)
  , granulation :: Number    -- ^ Pigment settling (0-1)
  , opacity :: Number        -- ^ Base opacity (0-1)
  }

-- | Get properties for a preset.
presetProperties :: PaintPreset -> PresetProperties
presetProperties Watercolor =
  { wetness: mkWetness 80.0
  , viscosity: mkViscosity 15.0      -- Low viscosity, flows easily
  , dryingRate: mkDryingRate 25.0
  , bleedRate: 0.7                   -- High bleed
  , granulation: 0.5                 -- Medium granulation
  , opacity: 0.6                     -- Semi-transparent
  }
presetProperties OilPaint =
  { wetness: mkWetness 60.0
  , viscosity: mkViscosity 75.0      -- High viscosity
  , dryingRate: mkDryingRate 5.0     -- Very slow drying
  , bleedRate: 0.2
  , granulation: 0.1
  , opacity: 0.95                    -- Nearly opaque
  }
presetProperties Acrylic =
  { wetness: mkWetness 70.0
  , viscosity: mkViscosity 50.0      -- Medium viscosity
  , dryingRate: mkDryingRate 60.0    -- Fast drying
  , bleedRate: 0.3
  , granulation: 0.2
  , opacity: 0.9
  }
presetProperties Gouache =
  { wetness: mkWetness 65.0
  , viscosity: mkViscosity 55.0
  , dryingRate: mkDryingRate 40.0
  , bleedRate: 0.25
  , granulation: 0.15
  , opacity: 1.0                     -- Fully opaque
  }
presetProperties Ink =
  { wetness: mkWetness 90.0
  , viscosity: mkViscosity 5.0       -- Very low viscosity
  , dryingRate: mkDryingRate 70.0    -- Dries quickly
  , bleedRate: 0.8                   -- High bleed
  , granulation: 0.0                 -- No granulation
  , opacity: 1.0
  }
presetProperties Honey =
  { wetness: mkWetness 95.0          -- Very wet
  , viscosity: mkViscosity 95.0      -- Ultra-high viscosity
  , dryingRate: mkDryingRate 2.0     -- Almost never dries
  , bleedRate: 0.05
  , granulation: 0.0
  , opacity: 0.85
  }

-- | Get stiffness coefficient for preset (affects pressure response).
presetStiffness :: PaintPreset -> Number
presetStiffness Watercolor = 500.0    -- Soft, spreadable
presetStiffness OilPaint = 2000.0     -- Stiff, holds shape
presetStiffness Acrylic = 1000.0      -- Medium
presetStiffness Gouache = 1200.0
presetStiffness Ink = 300.0           -- Very soft
presetStiffness Honey = 5000.0        -- Extremely stiff, supports weight

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // simulation step
-- ═════════════════════════════════════════════════════════════════════════════

-- | Run one simulation step (full SPH cycle).
-- |
-- | dt is timestep in seconds (typically 0.016 for 60fps).
simulateStep :: PaintSystem -> Number -> PaintSystem
simulateStep sys dt =
  let
    -- 1. Compute densities using SPH
    withDensities = computeDensities sys
    -- 2. Compute pressures from densities
    withPressures = computePressures withDensities
    -- 3. Compute all forces (pressure + viscosity + gravity)
    withForces = computeForces withPressures
    -- 4. Integrate particle positions
    integrated = integrateParticles withForces dt
    -- 5. Enforce boundary conditions
    bounded = enforceBounds integrated
    -- 6. Apply impasto stacking (overlapping particles accumulate height)
    stacked = applyImpastoStacking bounded
    -- 7. Apply drying
    dried = applyDrying stacked dt
  in
    dried

-- | Apply impasto stacking — overlapping particles accumulate height.
-- |
-- | When paint particles occupy the same space, they stack on top of each
-- | other like real thick paint. This creates the impasto effect where
-- | adding more paint builds up visible thickness.
-- |
-- | ## Algorithm
-- |
-- | For each particle, find nearby particles (within smoothing radius).
-- | If overlapping significantly (distance < radius), increase height
-- | proportional to the overlap and the neighbor's paint amount.
-- |
-- | Height is modulated by:
-- | - Viscosity (thick paint stacks more)
-- | - Wetness (wet paint merges/flows, dry paint stacks)
applyImpastoStacking :: PaintSystem -> PaintSystem
applyImpastoStacking sys =
  let
    h = sys.smoothingRadius
    
    -- Calculate height contribution from neighbors
    computeStackingHeight :: PaintParticle -> Number
    computeStackingHeight p =
      Array.foldl (\acc neighbor ->
        if neighbor.id == p.id then acc
        else
          let
            dx = p.x - neighbor.x
            dy = p.y - neighbor.y
            dist = Num.sqrt (dx * dx + dy * dy)
            -- Overlap factor: 1.0 when exactly on top, 0.0 when at smoothing radius
            overlapFactor = max 0.0 (1.0 - dist / h)
            -- Viscosity modulation: thick paint (high viscosity) stacks more
            viscMod = unwrapViscosity neighbor.viscosity / 100.0
            -- Wet paint contribution (wet paint can stack before it flows away)
            wetMod = unwrapWetness neighbor.wetness / 100.0
            -- Height contribution from this neighbor
            -- Higher viscosity = more stacking, wet paint can still stack temporarily
            contribution = overlapFactor * overlapFactor * viscMod * wetMod * neighbor.height * 0.1
          in
            acc + contribution
      ) 0.0 sys.particles
    
    -- Update particle heights with stacking
    updateHeight p =
      let 
        stackAdd = computeStackingHeight p
        -- Height increases from stacking, but slowly settles if no overlap
        newHeight = p.height + stackAdd
        -- Cap maximum height to prevent runaway
        cappedHeight = min 5.0 newHeight
      in
        p { height = cappedHeight }
  in
    sys { particles = map updateHeight sys.particles }

-- | Apply gravity to all particles.
applyGravity :: PaintSystem -> Number -> Number -> PaintSystem
applyGravity sys gx gy = sys { gravityX = gx, gravityY = gy }

-- | Compute SPH densities for all particles.
-- |
-- | Uses Poly6 kernel from Hydrogen.
computeDensities :: PaintSystem -> PaintSystem
computeDensities sys =
  let
    h = sys.smoothingRadius
    
    computeParticleDensity :: PaintParticle -> Number
    computeParticleDensity p =
      Array.foldl (\acc neighbor -> 
        let
          dx = p.x - neighbor.x
          dy = p.y - neighbor.y
          r = Num.sqrt (dx * dx + dy * dy)
          w = SPH.kernelPoly6 r h
        in
          acc + neighbor.mass * w
      ) 0.0 sys.particles
    
    updateDensity p = p { density = computeParticleDensity p }
  in
    sys { particles = map updateDensity sys.particles }

-- | Compute pressures from densities.
-- |
-- | Uses Tait equation: p = k * (rho - rho0)
computePressures :: PaintSystem -> PaintSystem
computePressures sys =
  let
    updatePressure p = 
      let
        pressure = max 0.0 (sys.stiffness * (p.density - sys.restDensity))
      in
        p { pressure = pressure }
  in
    sys { particles = map updatePressure sys.particles }

-- | Compute all forces on particles.
-- |
-- | F_total = F_pressure + F_viscosity + F_gravity
-- | Viscosity is modulated by particle's wetness and viscosity atoms.
computeForces :: PaintSystem -> PaintSystem
computeForces sys =
  let
    h = sys.smoothingRadius
    
    computeParticleForce :: PaintParticle -> { fx :: Number, fy :: Number }
    computeParticleForce p =
      let
        -- Pressure force (using Spiky gradient)
        fPressure = Array.foldl (\acc neighbor ->
          if neighbor.id == p.id then acc
          else
            let
              dx = p.x - neighbor.x
              dy = p.y - neighbor.y
              r = Num.sqrt (dx * dx + dy * dy)
              gradW = SPH.kernelGradientSpiky r h
              avgPressure = (p.pressure + neighbor.pressure) / 2.0
              scale = (0.0 - neighbor.mass) * avgPressure / max 0.001 neighbor.density * gradW
              dirX = if r > 0.0001 then dx / r else 0.0
              dirY = if r > 0.0001 then dy / r else 0.0
            in
              { fx: acc.fx + scale * dirX, fy: acc.fy + scale * dirY }
        ) { fx: 0.0, fy: 0.0 } sys.particles
        
        -- Viscosity force (using Laplacian kernel)
        -- Modulated by paint viscosity
        viscMod = unwrapViscosity p.viscosity / 100.0
        wetMod = unwrapWetness p.wetness / 100.0
        effectiveVisc = viscMod * wetMod * 0.5
        
        fViscosity = Array.foldl (\acc neighbor ->
          if neighbor.id == p.id then acc
          else
            let
              dx = p.x - neighbor.x
              dy = p.y - neighbor.y
              r = Num.sqrt (dx * dx + dy * dy)
              lapW = SPH.kernelLaplacianViscosity r h
              dvx = neighbor.vx - p.vx
              dvy = neighbor.vy - p.vy
              scale = effectiveVisc * neighbor.mass / max 0.001 neighbor.density * lapW
            in
              { fx: acc.fx + scale * dvx, fy: acc.fy + scale * dvy }
        ) { fx: 0.0, fy: 0.0 } sys.particles
        
        -- Gravity force (from device tilt)
        fGravityX = p.mass * sys.gravityX * wetMod  -- Wet paint flows more
        fGravityY = p.mass * sys.gravityY * wetMod
      in
        { fx: fPressure.fx + fViscosity.fx + fGravityX
        , fy: fPressure.fy + fViscosity.fy + fGravityY
        }
    
    applyForce p =
      let f = computeParticleForce p
      in p { vx = p.vx + f.fx / p.mass, vy = p.vy + f.fy / p.mass }
  in
    sys { particles = map applyForce sys.particles }

-- | Integrate particle positions using symplectic Euler.
integrateParticles :: PaintSystem -> Number -> PaintSystem
integrateParticles sys dt =
  let
    integrate p =
      p { x = p.x + p.vx * dt
        , y = p.y + p.vy * dt
        , age = p.age + dt
        }
  in
    sys { particles = map integrate sys.particles }

-- | Enforce boundary conditions (reflect off walls).
enforceBounds :: PaintSystem -> PaintSystem
enforceBounds sys =
  let
    b = sys.bounds
    minX = b.x
    maxX = b.x + b.width
    minY = b.y
    maxY = b.y + b.height
    damping = 0.6  -- Energy loss on bounce
    
    enforceBoundary p =
      let
        -- X boundary
        p1 = if p.x < minX
          then p { x = minX, vx = (0.0 - p.vx) * damping }
          else if p.x > maxX
            then p { x = maxX, vx = (0.0 - p.vx) * damping }
            else p
        -- Y boundary
        p2 = if p1.y < minY
          then p1 { y = minY, vy = (0.0 - p1.vy) * damping }
          else if p1.y > maxY
            then p1 { y = maxY, vy = (0.0 - p1.vy) * damping }
            else p1
      in
        p2
  in
    sys { particles = map enforceBoundary sys.particles }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                     // drying
-- ═════════════════════════════════════════════════════════════════════════════

-- | Apply drying to all particles over time.
applyDrying :: PaintSystem -> Number -> PaintSystem
applyDrying sys dt =
  let
    dryParticle p =
      let newWetness = WMDynamics.applyDrying p.wetness p.dryingRate dt
      in p { wetness = newWetness }
  in
    sys { particles = map dryParticle sys.particles }

-- | Commit fully dried particles (wetness < 1%) to stroke cache.
-- |
-- | Returns (still-wet particles, dried particles).
commitDriedParticles :: PaintSystem -> { wet :: PaintSystem, dried :: Array PaintParticle }
commitDriedParticles sys =
  let
    isWet p = unwrapWetness p.wetness >= 1.0
    wet = Array.filter isWet sys.particles
    dried = Array.filter (\p -> not (isWet p)) sys.particles
  in
    { wet: sys { particles = wet }
    , dried: dried
    }

-- | Check if a particle is fully dried.
isDried :: PaintParticle -> Boolean
isDried p = unwrapWetness p.wetness < 1.0

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // drag physics
-- ═════════════════════════════════════════════════════════════════════════════

-- | Brush drag input — represents finger/stylus motion.
-- |
-- | Used to apply drag forces to nearby paint particles,
-- | pulling wet paint along with the brush stroke.
type BrushDrag =
  { x :: Number        -- ^ Current brush X position
  , y :: Number        -- ^ Current brush Y position
  , vx :: Number       -- ^ Brush velocity X (dx/dt)
  , vy :: Number       -- ^ Brush velocity Y (dy/dt)
  , radius :: Number   -- ^ Brush influence radius
  , strength :: Number -- ^ Drag strength (0-1)
  }

-- | Apply brush drag to paint particles.
-- |
-- | When the user drags their finger/stylus across wet paint,
-- | particles within the brush radius are pulled along.
-- | This creates the "finger painting" smearing effect.
-- |
-- | ## Physics
-- |
-- | Particles receive velocity in the direction of brush motion,
-- | modulated by:
-- | - Distance from brush center (closer = more drag)
-- | - Particle wetness (wet paint smears, dry paint doesn't)
-- | - Particle viscosity (thick paint resists more)
-- | - Brush strength (pressure-sensitive)
applyBrushDrag :: BrushDrag -> PaintSystem -> PaintSystem
applyBrushDrag brush sys =
  let
    -- Apply drag force to a single particle
    applyDrag :: PaintParticle -> PaintParticle
    applyDrag p =
      let
        -- Distance from brush to particle
        dx = p.x - brush.x
        dy = p.y - brush.y
        dist = Num.sqrt (dx * dx + dy * dy)
        
        -- Only affect particles within brush radius
        inRange = dist < brush.radius
        
        -- Distance falloff: 1.0 at center, 0.0 at edge
        falloff = if inRange 
          then (1.0 - dist / brush.radius) * (1.0 - dist / brush.radius)
          else 0.0
        
        -- Wetness modulation: only wet paint moves
        wetMod = unwrapWetness p.wetness / 100.0
        
        -- Viscosity resistance: thick paint resists drag
        -- High viscosity = low drag coefficient
        viscResist = 1.0 - (unwrapViscosity p.viscosity / 150.0)
        viscMod = max 0.1 viscResist
        
        -- Combined drag coefficient
        dragCoeff = falloff * wetMod * viscMod * brush.strength
        
        -- Apply velocity from brush motion
        newVx = p.vx + brush.vx * dragCoeff
        newVy = p.vy + brush.vy * dragCoeff
        
        -- Also slightly move position for immediate response
        newX = p.x + brush.vx * dragCoeff * 0.1
        newY = p.y + brush.vy * dragCoeff * 0.1
      in
        if inRange && wetMod > 0.01
          then p { vx = newVx, vy = newVy, x = newX, y = newY }
          else p
  in
    sys { particles = map applyDrag sys.particles }

-- | Create brush drag from pointer movement.
-- |
-- | Takes current and previous positions to calculate velocity.
mkBrushDrag 
  :: Number  -- ^ Current X
  -> Number  -- ^ Current Y  
  -> Number  -- ^ Previous X
  -> Number  -- ^ Previous Y
  -> Number  -- ^ Brush radius
  -> Number  -- ^ Pressure (0-1)
  -> BrushDrag
mkBrushDrag cx cy px py radius pressure =
  { x: cx
  , y: cy
  , vx: (cx - px) * 2.0  -- Scale up for responsiveness
  , vy: (cy - py) * 2.0
  , radius: radius
  , strength: pressure
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // analysis
-- ═════════════════════════════════════════════════════════════════════════════

-- | Total kinetic energy of the system.
systemEnergy :: PaintSystem -> Number
systemEnergy sys =
  Array.foldl (\acc p ->
    let speed2 = p.vx * p.vx + p.vy * p.vy
    in acc + 0.5 * p.mass * speed2
  ) 0.0 sys.particles

-- | Average wetness across all particles.
averageWetness :: PaintSystem -> Number
averageWetness sys =
  let
    total = Array.foldl (\acc p -> acc + unwrapWetness p.wetness) 0.0 sys.particles
    count = Int.toNumber (Array.length sys.particles)
  in
    if count > 0.0 then total / count else 0.0

-- | Maximum particle speed.
maxVelocity :: PaintSystem -> Number
maxVelocity sys =
  Array.foldl (\maxV p ->
    let speed = Num.sqrt (p.vx * p.vx + p.vy * p.vy)
    in max maxV speed
  ) 0.0 sys.particles

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

-- | Display particle info.
displayParticle :: PaintParticle -> String
displayParticle p =
  "Particle[" <> show p.id <> "] at (" <> show p.x <> ", " <> show p.y <> ") " <>
  "wetness=" <> show (unwrapWetness p.wetness) <> "%"

-- | Display system summary.
displaySystem :: PaintSystem -> String
displaySystem sys =
  "PaintSystem[" <> show (particleCount sys) <> " particles, " <>
  presetName sys.preset <> ", " <>
  "energy=" <> show (systemEnergy sys) <> "]"

-- | Display preset info.
displayPreset :: PaintPreset -> String
displayPreset p =
  let props = presetProperties p
  in presetName p <> " (viscosity=" <> show (unwrapViscosity props.viscosity) <> "%)"

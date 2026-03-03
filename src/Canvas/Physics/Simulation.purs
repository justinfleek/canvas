-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                              // canvas // physics // simulation
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Physics Simulation — SPH fluid simulation wrapper.
-- |
-- | ## Design Philosophy
-- |
-- | This module provides a high-level interface to the SPH (Smoothed Particle
-- | Hydrodynamics) simulation. It wraps Hydrogen's fluid physics with:
-- |
-- | - Configuration presets for different paint types
-- | - Performance tuning (substeps, spatial hashing)
-- | - Integration with canvas coordinate system
-- |
-- | ## SPH Algorithm
-- |
-- | Each step computes:
-- | 1. Density: ρ_i = Σ_j m_j * W(r_ij, h)
-- | 2. Pressure: p_i = k * (ρ_i - ρ_0)
-- | 3. Forces: F = F_pressure + F_viscosity + F_gravity
-- | 4. Integration: Semi-implicit Euler (symplectic)
-- |
-- | ## Performance
-- |
-- | - Spatial hashing for O(n) neighbor lookup
-- | - Fixed timestep with substeps for stability
-- | - Adaptive quality based on particle count
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Hydrogen.Schema.Physics.Fluid.Particle
-- | - Hydrogen.Schema.Physics.Fluid.Solver
-- | - Canvas.Types

module Canvas.Physics.Simulation
  ( -- * Simulation Config
    SimulationConfig
  , mkSimulationConfig
  , defaultSimConfig
  , highQualitySimConfig
  , fastSimConfig
  
  -- * Config Accessors
  , simTimestep
  , simSubsteps
  , simSmoothingRadius
  , simRestDensity
  , simStiffness
  , simViscosity
  , simGravityScale
  
  -- * Simulation State
  , SimParticle
  , SimulationState
  , mkSimulationState
  , emptySimState
  , simParticleCount
  , simEnergy
  , simBounds
  
  -- * Simulation Step
  , step
  , stepN
  , stepWithConfig
  
  -- * Force Computation
  , computeAllForces
  , computePressureForce
  , computeViscosityForce
  , computeGravityForce
  
  -- * Spatial Hashing
  , SpatialHash
  , buildSpatialHash
  , findNeighbors
  , hashPosition
  
  -- * Integration
  , integrateEuler
  , integrateSemiImplicit
  , integrateVerlet
  
  -- * Analysis
  , totalKineticEnergy
  , totalPotentialEnergy
  , maxParticleSpeed
  , averageParticleSpeed
  
  -- * Comparison
  , configsEqual
  , configsDiffer
  , particlesEqual
  , particlesDiffer
  
  -- * Stability Analysis
  , isSimulationStable
  , isSimulationSettled
  , hasHighPressure
  , hasRunawayParticles
  , countActiveParticles
  , filterStableParticles
  , filterUnstableParticles
  
  -- * Display
  , displaySimConfig
  , displaySimState
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
  , negate
  )

import Data.Array (length, foldl, filter, snoc) as Array
import Data.Number (sqrt) as Num
import Data.Int (toNumber, floor) as Int
import Data.Map (Map)
import Data.Map (empty, insert, lookup) as Map
import Data.Maybe (Maybe(Just, Nothing), fromMaybe)

import Hydrogen.Schema.Physics.Fluid.Particle as SPH

import Canvas.Types
  ( Point2D
  , mkPoint2D
  , Vec2D
  , mkVec2D
  , vecMagnitude
  , Bounds
  , mkBounds
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // simulation config
-- ═════════════════════════════════════════════════════════════════════════════

-- | Configuration for SPH simulation.
type SimulationConfig =
  { timestep :: Number         -- ^ Fixed timestep (seconds)
  , substeps :: Int            -- ^ Substeps per frame
  , smoothingRadius :: Number  -- ^ SPH kernel radius (pixels)
  , restDensity :: Number      -- ^ Target fluid density
  , stiffness :: Number        -- ^ Pressure stiffness (k)
  , viscosity :: Number        -- ^ Viscosity coefficient
  , gravityScale :: Number     -- ^ Gravity strength multiplier
  , boundaryDamping :: Number  -- ^ Energy loss at boundaries (0-1)
  , maxParticles :: Int        -- ^ Maximum particle count
  }

-- | Create simulation config with validation.
mkSimulationConfig 
  :: Number   -- ^ timestep
  -> Int      -- ^ substeps
  -> Number   -- ^ smoothing radius
  -> Number   -- ^ stiffness
  -> SimulationConfig
mkSimulationConfig dt subs smooth stiff =
  { timestep: max 0.001 (min 0.1 dt)
  , substeps: max 1 (min 10 subs)
  , smoothingRadius: max 5.0 (min 100.0 smooth)
  , restDensity: 1000.0
  , stiffness: max 100.0 (min 10000.0 stiff)
  , viscosity: 0.5
  , gravityScale: 1.0
  , boundaryDamping: 0.6
  , maxParticles: 10000
  }

-- | Default simulation config (60fps, 1 substep).
defaultSimConfig :: SimulationConfig
defaultSimConfig = mkSimulationConfig 0.016 1 15.0 500.0

-- | High quality config (more substeps, smoother).
highQualitySimConfig :: SimulationConfig
highQualitySimConfig = 
  let base = mkSimulationConfig 0.016 4 20.0 800.0
  in base { viscosity = 0.8 }

-- | Fast config (fewer calculations).
fastSimConfig :: SimulationConfig
fastSimConfig = mkSimulationConfig 0.016 1 10.0 300.0

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // config accessors
-- ═════════════════════════════════════════════════════════════════════════════

simTimestep :: SimulationConfig -> Number
simTimestep c = c.timestep

simSubsteps :: SimulationConfig -> Int
simSubsteps c = c.substeps

simSmoothingRadius :: SimulationConfig -> Number
simSmoothingRadius c = c.smoothingRadius

simRestDensity :: SimulationConfig -> Number
simRestDensity c = c.restDensity

simStiffness :: SimulationConfig -> Number
simStiffness c = c.stiffness

simViscosity :: SimulationConfig -> Number
simViscosity c = c.viscosity

simGravityScale :: SimulationConfig -> Number
simGravityScale c = c.gravityScale

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // simulation state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Particle for simulation.
-- |
-- | Uses Point2D for position and Vec2D for velocity to maintain
-- | type consistency with the rest of the canvas system.
type SimParticle =
  { id :: Int
  , position :: Point2D       -- ^ Position in canvas coordinates
  , velocity :: Vec2D         -- ^ Velocity vector (px/s)
  , mass :: Number
  , density :: Number
  , pressure :: Number
  }

-- | Complete simulation state.
type SimulationState =
  { particles :: Array SimParticle
  , bounds :: Bounds
  , gravityX :: Number
  , gravityY :: Number
  , time :: Number           -- ^ Total simulated time
  , stepCount :: Int         -- ^ Total steps executed
  }

-- | Create simulation state.
mkSimulationState :: Bounds -> SimulationState
mkSimulationState b =
  { particles: []
  , bounds: b
  , gravityX: 0.0
  , gravityY: 9.81
  , time: 0.0
  , stepCount: 0
  }

-- | Empty simulation state (default bounds).
emptySimState :: SimulationState
emptySimState = mkSimulationState (mkBounds 0.0 0.0 1920.0 1080.0)

-- | Get particle count.
simParticleCount :: SimulationState -> Int
simParticleCount s = Array.length s.particles

-- | Get total kinetic energy.
simEnergy :: SimulationState -> Number
simEnergy = totalKineticEnergy

-- | Get bounds.
simBounds :: SimulationState -> Bounds
simBounds s = s.bounds

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // simulation step
-- ═════════════════════════════════════════════════════════════════════════════

-- | Execute one simulation step with default config.
step :: SimulationState -> SimulationState
step = stepWithConfig defaultSimConfig

-- | Execute N simulation steps.
stepN :: Int -> SimulationState -> SimulationState
stepN n state =
  if n <= 0 
    then state
    else stepN (n - 1) (step state)

-- | Execute one simulation step with config.
stepWithConfig :: SimulationConfig -> SimulationState -> SimulationState
stepWithConfig config state =
  let
    dt = config.timestep / Int.toNumber config.substeps
    
    -- Run substeps
    runSubstep :: SimulationState -> SimulationState
    runSubstep s = singleStep config dt s
    
    stepped = foldlN config.substeps runSubstep state
  in
    stepped { time = stepped.time + config.timestep
            , stepCount = stepped.stepCount + 1
            }

-- | Single simulation substep.
singleStep :: SimulationConfig -> Number -> SimulationState -> SimulationState
singleStep config dt state =
  let
    -- 1. Build spatial hash for neighbor lookup
    hash = buildSpatialHash config.smoothingRadius state.particles
    
    -- 2. Compute densities
    withDensities = computeDensities config hash state
    
    -- 3. Compute pressures
    withPressures = computePressures config withDensities
    
    -- 4. Compute forces and integrate
    integrated = integrateAll config hash dt withPressures
    
    -- 5. Enforce boundaries
    bounded = enforceBoundaries config integrated
  in
    bounded

-- | Compute densities for all particles.
computeDensities :: SimulationConfig -> SpatialHash -> SimulationState -> SimulationState
computeDensities config hash state =
  let
    h = config.smoothingRadius
    
    computeDensity :: SimParticle -> SimParticle
    computeDensity p =
      let
        neighbors = findNeighbors hash p.position.x p.position.y h
        density = Array.foldl (\acc n ->
          let
            dx = p.position.x - n.position.x
            dy = p.position.y - n.position.y
            r = Num.sqrt (dx * dx + dy * dy)
            w = SPH.kernelPoly6 r h
          in
            acc + n.mass * w
        ) 0.0 neighbors
      in
        p { density = max 0.001 density }
  in
    state { particles = map computeDensity state.particles }

-- | Compute pressures from densities.
computePressures :: SimulationConfig -> SimulationState -> SimulationState
computePressures config state =
  let
    computePressure :: SimParticle -> SimParticle
    computePressure p =
      let
        pressure = max 0.0 (config.stiffness * (p.density - config.restDensity))
      in
        p { pressure = pressure }
  in
    state { particles = map computePressure state.particles }

-- | Integrate all particles.
integrateAll :: SimulationConfig -> SpatialHash -> Number -> SimulationState -> SimulationState
integrateAll config hash dt state =
  let
    h = config.smoothingRadius
    
    integrateParticle :: SimParticle -> SimParticle
    integrateParticle p =
      let
        neighbors = findNeighbors hash p.position.x p.position.y h
        force = computeAllForces config p neighbors state.gravityX state.gravityY
        -- Semi-implicit Euler
        newVx = p.velocity.vx + force.fx / p.mass * dt
        newVy = p.velocity.vy + force.fy / p.mass * dt
        newX = p.position.x + newVx * dt
        newY = p.position.y + newVy * dt
        newPos = mkPoint2D newX newY
        newVel = mkVec2D newVx newVy
      in
        p { position = newPos, velocity = newVel }
  in
    state { particles = map integrateParticle state.particles }

-- | Enforce boundary conditions.
enforceBoundaries :: SimulationConfig -> SimulationState -> SimulationState
enforceBoundaries config state =
  let
    b = state.bounds
    minX = b.x
    maxX = b.x + b.width
    minY = b.y
    maxY = b.y + b.height
    damp = config.boundaryDamping
    
    enforce :: SimParticle -> SimParticle
    enforce p =
      let
        px = p.position.x
        py = p.position.y
        vx = p.velocity.vx
        vy = p.velocity.vy
        
        -- X boundary
        result1 = if px < minX 
          then { x: minX, vx: negate vx * damp }
          else if px > maxX 
            then { x: maxX, vx: negate vx * damp }
            else { x: px, vx: vx }
        
        -- Y boundary
        result2 = if py < minY
          then { y: minY, vy: negate vy * damp }
          else if py > maxY
            then { y: maxY, vy: negate vy * damp }
            else { y: py, vy: vy }
        
        newPos = mkPoint2D result1.x result2.y
        newVel = mkVec2D result1.vx result2.vy
      in
        p { position = newPos, velocity = newVel }
  in
    state { particles = map enforce state.particles }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // force computation
-- ═════════════════════════════════════════════════════════════════════════════

-- | Compute all forces on a particle.
computeAllForces 
  :: SimulationConfig 
  -> SimParticle 
  -> Array SimParticle 
  -> Number  -- ^ gravity X
  -> Number  -- ^ gravity Y
  -> { fx :: Number, fy :: Number }
computeAllForces config p neighbors gx gy =
  let
    fPressure = computePressureForce config p neighbors
    fViscosity = computeViscosityForce config p neighbors
    fGravity = computeGravityForce config p gx gy
  in
    { fx: fPressure.fx + fViscosity.fx + fGravity.fx
    , fy: fPressure.fy + fViscosity.fy + fGravity.fy
    }

-- | Compute pressure force using Spiky kernel gradient.
computePressureForce 
  :: SimulationConfig 
  -> SimParticle 
  -> Array SimParticle 
  -> { fx :: Number, fy :: Number }
computePressureForce config p neighbors =
  let
    h = config.smoothingRadius
  in
    Array.foldl (\acc n ->
      if n.id == p.id then acc
      else
        let
          dx = p.position.x - n.position.x
          dy = p.position.y - n.position.y
          r = Num.sqrt (dx * dx + dy * dy)
          gradW = SPH.kernelGradientSpiky r h
          avgPressure = (p.pressure + n.pressure) / 2.0
          scale = negate n.mass * avgPressure / max 0.001 n.density * gradW
          dirX = if r > 0.0001 then dx / r else 0.0
          dirY = if r > 0.0001 then dy / r else 0.0
        in
          { fx: acc.fx + scale * dirX, fy: acc.fy + scale * dirY }
    ) { fx: 0.0, fy: 0.0 } neighbors

-- | Compute viscosity force using Laplacian kernel.
computeViscosityForce 
  :: SimulationConfig 
  -> SimParticle 
  -> Array SimParticle 
  -> { fx :: Number, fy :: Number }
computeViscosityForce config p neighbors =
  let
    h = config.smoothingRadius
    mu = config.viscosity
  in
    Array.foldl (\acc n ->
      if n.id == p.id then acc
      else
        let
          dx = p.position.x - n.position.x
          dy = p.position.y - n.position.y
          r = Num.sqrt (dx * dx + dy * dy)
          lapW = SPH.kernelLaplacianViscosity r h
          dvx = n.velocity.vx - p.velocity.vx
          dvy = n.velocity.vy - p.velocity.vy
          scale = mu * n.mass / max 0.001 n.density * lapW
        in
          { fx: acc.fx + scale * dvx, fy: acc.fy + scale * dvy }
    ) { fx: 0.0, fy: 0.0 } neighbors

-- | Compute gravity force.
computeGravityForce 
  :: SimulationConfig 
  -> SimParticle 
  -> Number  -- ^ gravity X
  -> Number  -- ^ gravity Y
  -> { fx :: Number, fy :: Number }
computeGravityForce config p gx gy =
  { fx: p.mass * gx * config.gravityScale
  , fy: p.mass * gy * config.gravityScale
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // spatial hashing
-- ═════════════════════════════════════════════════════════════════════════════

-- | Spatial hash for fast neighbor lookup.
type SpatialHash =
  { cellSize :: Number
  , cells :: Map Int (Array SimParticle)
  }

-- | Build spatial hash from particles.
buildSpatialHash :: Number -> Array SimParticle -> SpatialHash
buildSpatialHash cellSize particles =
  let
    emptyHash = { cellSize: cellSize, cells: Map.empty }
    
    insertParticle :: SpatialHash -> SimParticle -> SpatialHash
    insertParticle hash p =
      let
        key = hashPosition hash.cellSize p.position.x p.position.y
        existing = fromMaybe [] (Map.lookup key hash.cells)
        updated = Array.snoc existing p
      in
        hash { cells = Map.insert key updated hash.cells }
  in
    Array.foldl insertParticle emptyHash particles

-- | Find neighbors within radius.
findNeighbors :: SpatialHash -> Number -> Number -> Number -> Array SimParticle
findNeighbors hash px py radius =
  let
    -- Check 9 cells (3x3 grid around particle)
    cx = Int.floor (px / hash.cellSize)
    cy = Int.floor (py / hash.cellSize)
    
    cellKeys = 
      [ hashXY (cx - 1) (cy - 1), hashXY cx (cy - 1), hashXY (cx + 1) (cy - 1)
      , hashXY (cx - 1) cy,       hashXY cx cy,       hashXY (cx + 1) cy
      , hashXY (cx - 1) (cy + 1), hashXY cx (cy + 1), hashXY (cx + 1) (cy + 1)
      ]
    
    getAllFromCells = Array.foldl (\acc key ->
      case Map.lookup key hash.cells of
        Just ps -> acc <> ps
        Nothing -> acc
    ) []
    
    candidates = getAllFromCells cellKeys
    
    -- Filter by actual distance
    r2 = radius * radius
  in
    Array.filter (\p ->
      let
        dx = p.position.x - px
        dy = p.position.y - py
      in
        dx * dx + dy * dy <= r2
    ) candidates

-- | Hash position to cell key.
hashPosition :: Number -> Number -> Number -> Int
hashPosition cellSize px py =
  let
    cx = Int.floor (px / cellSize)
    cy = Int.floor (py / cellSize)
  in
    hashXY cx cy

-- | Combine cell coordinates into hash key.
hashXY :: Int -> Int -> Int
hashXY cx cy = cx * 73856093 + cy * 19349663  -- Large primes for mixing

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                // integration
-- ═════════════════════════════════════════════════════════════════════════════

-- | Simple Euler integration.
integrateEuler :: Number -> SimParticle -> { fx :: Number, fy :: Number } -> SimParticle
integrateEuler dt p force =
  let
    ax = force.fx / p.mass
    ay = force.fy / p.mass
    newX = p.position.x + p.velocity.vx * dt
    newY = p.position.y + p.velocity.vy * dt
    newVx = p.velocity.vx + ax * dt
    newVy = p.velocity.vy + ay * dt
    newPos = mkPoint2D newX newY
    newVel = mkVec2D newVx newVy
  in
    p { position = newPos, velocity = newVel }

-- | Semi-implicit Euler (symplectic).
integrateSemiImplicit :: Number -> SimParticle -> { fx :: Number, fy :: Number } -> SimParticle
integrateSemiImplicit dt p force =
  let
    ax = force.fx / p.mass
    ay = force.fy / p.mass
    newVx = p.velocity.vx + ax * dt
    newVy = p.velocity.vy + ay * dt
    newX = p.position.x + newVx * dt
    newY = p.position.y + newVy * dt
    newPos = mkPoint2D newX newY
    newVel = mkVec2D newVx newVy
  in
    p { position = newPos, velocity = newVel }

-- | Verlet integration (for energy conservation).
integrateVerlet :: Number -> SimParticle -> { fx :: Number, fy :: Number } -> Point2D -> SimParticle
integrateVerlet dt p force prevPos =
  let
    ax = force.fx / p.mass
    ay = force.fy / p.mass
    newX = 2.0 * p.position.x - prevPos.x + ax * dt * dt
    newY = 2.0 * p.position.y - prevPos.y + ay * dt * dt
    newVx = (newX - prevPos.x) / (2.0 * dt)
    newVy = (newY - prevPos.y) / (2.0 * dt)
    newPos = mkPoint2D newX newY
    newVel = mkVec2D newVx newVy
  in
    p { position = newPos, velocity = newVel }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // analysis
-- ═════════════════════════════════════════════════════════════════════════════

-- | Total kinetic energy of all particles.
totalKineticEnergy :: SimulationState -> Number
totalKineticEnergy state =
  Array.foldl (\acc p ->
    let speed2 = vecMagnitude p.velocity * vecMagnitude p.velocity
    in acc + 0.5 * p.mass * speed2
  ) 0.0 state.particles

-- | Total gravitational potential energy.
totalPotentialEnergy :: SimulationState -> Number
totalPotentialEnergy state =
  let maxY = state.bounds.y + state.bounds.height
  in Array.foldl (\acc p ->
    acc + p.mass * state.gravityY * (maxY - p.position.y)
  ) 0.0 state.particles

-- | Maximum particle speed.
maxParticleSpeed :: SimulationState -> Number
maxParticleSpeed state =
  Array.foldl (\maxV p ->
    let speed = vecMagnitude p.velocity
    in max maxV speed
  ) 0.0 state.particles

-- | Average particle speed.
averageParticleSpeed :: SimulationState -> Number
averageParticleSpeed state =
  let
    n = Array.length state.particles
    totalSpeed = Array.foldl (\acc p ->
      acc + vecMagnitude p.velocity
    ) 0.0 state.particles
  in
    if n > 0 then totalSpeed / Int.toNumber n else 0.0

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                  // comparison
-- ═════════════════════════════════════════════════════════════════════════════

-- | Check if two simulation configs are equal.
-- |
-- | Useful for determining if a config change requires re-initialization.
configsEqual :: SimulationConfig -> SimulationConfig -> Boolean
configsEqual a b =
  a.timestep == b.timestep &&
  a.substeps == b.substeps &&
  a.smoothingRadius == b.smoothingRadius &&
  a.restDensity == b.restDensity &&
  a.stiffness == b.stiffness &&
  a.viscosity == b.viscosity &&
  a.gravityScale == b.gravityScale &&
  a.boundaryDamping == b.boundaryDamping &&
  a.maxParticles == b.maxParticles

-- | Check if two simulation configs differ.
-- |
-- | Returns true if any parameter has changed, triggering potential re-init.
configsDiffer :: SimulationConfig -> SimulationConfig -> Boolean
configsDiffer a b = configsEqual a b == false

-- | Check if two particles are the same (by ID).
particlesEqual :: SimParticle -> SimParticle -> Boolean
particlesEqual a b = a.id == b.id

-- | Check if two particles are different (by ID).
-- |
-- | Used in force calculations to skip self-interaction.
particlesDiffer :: SimParticle -> SimParticle -> Boolean
particlesDiffer a b = a.id /= b.id

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // stability analysis
-- ═════════════════════════════════════════════════════════════════════════════

-- | Check if simulation is numerically stable.
-- |
-- | A simulation is stable if:
-- | - No particle exceeds maximum velocity threshold
-- | - No particle has negative or infinite density
-- | - Total energy is bounded
isSimulationStable :: SimulationConfig -> SimulationState -> Boolean
isSimulationStable config state =
  let
    maxSpeed = maxParticleSpeed state
    maxAllowedSpeed = config.smoothingRadius / config.timestep  -- CFL condition
    energyBounded = totalKineticEnergy state < 1.0e10  -- Arbitrary large bound
    hasParticles = simParticleCount state >= 0
  in
    maxSpeed < maxAllowedSpeed && energyBounded && hasParticles

-- | Check if simulation has settled to equilibrium.
-- |
-- | A simulation is settled when:
-- | - Average speed is below threshold (particles mostly still)
-- | - Maximum speed is below threshold (no fast outliers)
-- | - Sufficient time has passed
isSimulationSettled :: Number -> Number -> SimulationState -> Boolean
isSimulationSettled speedThreshold minTime state =
  let
    avgSpeed = averageParticleSpeed state
    maxSpeed = maxParticleSpeed state
    timeElapsed = state.time
  in
    avgSpeed < speedThreshold && maxSpeed < speedThreshold * 2.0 && timeElapsed >= minTime

-- | Check if any particle has pressure above threshold.
-- |
-- | High pressure indicates potential instability or compression.
hasHighPressure :: Number -> SimulationState -> Boolean
hasHighPressure threshold state =
  Array.foldl (\acc p -> acc || p.pressure >= threshold) false state.particles

-- | Check if any particles have escaped to unreasonable velocities.
-- |
-- | Runaway particles indicate numerical instability.
hasRunawayParticles :: Number -> SimulationState -> Boolean
hasRunawayParticles maxAllowedSpeed state =
  Array.foldl (\acc p ->
    let speed = vecMagnitude p.velocity
    in acc || speed >= maxAllowedSpeed
  ) false state.particles

-- | Count particles that are "active" (moving above threshold).
countActiveParticles :: Number -> SimulationState -> Int
countActiveParticles speedThreshold state =
  Array.length (Array.filter (\p ->
    vecMagnitude p.velocity >= speedThreshold
  ) state.particles)

-- | Filter particles that are stable (moving slowly, reasonable pressure).
filterStableParticles :: Number -> Number -> SimulationState -> Array SimParticle
filterStableParticles maxSpeed maxPressure state =
  Array.filter (\p ->
    let speed = vecMagnitude p.velocity
    in speed < maxSpeed && p.pressure < maxPressure
  ) state.particles

-- | Filter particles that are unstable (moving fast OR high pressure).
filterUnstableParticles :: Number -> Number -> SimulationState -> Array SimParticle
filterUnstableParticles maxSpeed maxPressure state =
  Array.filter (\p ->
    let speed = vecMagnitude p.velocity
    in speed >= maxSpeed || p.pressure >= maxPressure
  ) state.particles

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

displaySimConfig :: SimulationConfig -> String
displaySimConfig c =
  "SimConfig { dt=" <> show c.timestep <> ", substeps=" <> show c.substeps <>
  ", h=" <> show c.smoothingRadius <> ", k=" <> show c.stiffness <> " }"

displaySimState :: SimulationState -> String
displaySimState s =
  "SimState { particles=" <> show (simParticleCount s) <>
  ", time=" <> show s.time <> "s, energy=" <> show (simEnergy s) <> " }"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // utilities
-- ═════════════════════════════════════════════════════════════════════════════

-- | Fold N times.
foldlN :: forall a. Int -> (a -> a) -> a -> a
foldlN n f initial =
  if n <= 0
    then initial
    else foldlN (n - 1) f (f initial)

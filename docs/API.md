# Canvas API Reference

Complete API documentation for the Canvas paint application.

## Table of Contents

- [Canvas.Types](#canvastypes)
- [Canvas.Paint.Stroke](#canvaspaintstroke)
- [Canvas.Paint.Brush](#canvaspaintbrush)
- [Canvas.Paint.Particle](#canvaspaintparticle)
- [Canvas.Paint.Drying](#canvaspaintdrying)
- [Canvas.Physics.Simulation](#canvasphysicssimulation)
- [Canvas.Physics.Gravity](#canvasphysicsgravity)
- [Canvas.Physics.Bounds](#canvasphysicsbounds)
- [Canvas.Layer.Types](#canvaslayertypes)
- [Canvas.Layer.Render](#canvaslayerrender)
- [Canvas.Layer.Composite](#canvaslayercomposite)

---

## Canvas.Types

Core type definitions used throughout the application.

### Point2D

A 2D point in canvas coordinates.

```purescript
type Point2D = { x :: Number, y :: Number }

mkPoint2D :: Number -> Number -> Point2D
```

### Vec2D

A 2D vector for velocities and forces.

```purescript
type Vec2D = { vx :: Number, vy :: Number }

mkVec2D :: Number -> Number -> Vec2D
vecMagnitude :: Vec2D -> Number
vecNormalize :: Vec2D -> Vec2D
vecScale :: Number -> Vec2D -> Vec2D
vecAdd :: Vec2D -> Vec2D -> Vec2D
vecDot :: Vec2D -> Vec2D -> Number
```

### Color

RGBA color representation.

```purescript
type Color = { r :: Number, g :: Number, b :: Number, a :: Number }

mkColor :: Number -> Number -> Number -> Number -> Color
colorBlack :: Color
colorWhite :: Color
colorTransparent :: Color
```

### Identifiers

Type-safe identifiers for strokes and layers.

```purescript
newtype StrokeId
newtype LayerId

mkStrokeId :: Int -> StrokeId
mkLayerId :: Int -> LayerId
unwrapStrokeId :: StrokeId -> Int
unwrapLayerId :: LayerId -> Int
```

### Bounds

Rectangular bounds for collision and rendering.

```purescript
type Bounds = { x :: Number, y :: Number, width :: Number, height :: Number }

mkBounds :: Number -> Number -> Number -> Number -> Bounds
boundsContains :: Point2D -> Bounds -> Boolean
boundsIntersects :: Bounds -> Bounds -> Boolean
```

---

## Canvas.Paint.Stroke

Stroke recording and analysis.

### StrokePoint

A single input sample with full stylus state.

```purescript
type StrokePoint =
  { x :: Number           -- X position
  , y :: Number           -- Y position
  , pressure :: Number    -- 0-1, 0.5 for touch
  , tiltX :: Number       -- -90 to 90 degrees
  , tiltY :: Number       -- -90 to 90 degrees
  , timestamp :: Number   -- ms since stroke start
  }

mkStrokePoint :: Number -> Number -> Number -> Number -> Number -> Number -> StrokePoint
```

### StrokeSegment

A segment between two consecutive points.

```purescript
type StrokeSegment = { start :: StrokePoint, end :: StrokePoint }

mkStrokeSegment :: StrokePoint -> StrokePoint -> StrokeSegment
segmentLength :: StrokeSegment -> Number
segmentAveragePressure :: StrokeSegment -> Number
segmentVelocity :: StrokeSegment -> { vx :: Number, vy :: Number }
computeStrokeSegments :: Stroke -> Array StrokeSegment
```

### Stroke

A complete brush stroke.

```purescript
type Stroke =
  { id :: StrokeId
  , layerId :: LayerId
  , color :: Color
  , brushSize :: Number
  , points :: Array StrokePoint
  , active :: Boolean
  , startTime :: Number
  , endTime :: Number
  }
```

#### Construction

```purescript
mkStroke :: StrokeId -> LayerId -> Color -> Number -> Stroke
emptyStroke :: Stroke
beginStroke :: StrokeId -> LayerId -> Color -> Number -> Number -> Number -> Number -> Number -> Stroke
addPoint :: Stroke -> Number -> Number -> Number -> Number -> Stroke
endStroke :: Stroke -> Number -> Stroke
```

#### Analysis

```purescript
strokeLength :: Stroke -> Number
strokeAverageSpeed :: Stroke -> Number
strokeAveragePressure :: Stroke -> Number
strokePointCount :: Stroke -> Int
strokeBounds :: Stroke -> Bounds
strokeDuration :: Stroke -> Number
```

#### Comparison

```purescript
pointsEqual :: StrokePoint -> StrokePoint -> Boolean
pointsDiffer :: StrokePoint -> StrokePoint -> Boolean
strokesEqual :: Stroke -> Stroke -> Boolean
strokesDiffer :: Stroke -> Stroke -> Boolean
```

#### Validation

```purescript
isStrokeValid :: Stroke -> Boolean
isStrokeCommittable :: Stroke -> Boolean
hasMinimumLength :: Number -> Stroke -> Boolean
hasMinimumPoints :: Int -> Stroke -> Boolean
filterHighPressurePoints :: Number -> Stroke -> Array StrokePoint
filterLowPressurePoints :: Number -> Stroke -> Array StrokePoint
```

#### Transforms

```purescript
mirrorStrokeX :: Number -> Stroke -> Stroke
mirrorStrokeY :: Number -> Stroke -> Stroke
translateStroke :: Number -> Number -> Stroke -> Stroke
```

#### Particle Generation

```purescript
-- Position-only (fast)
generateParticlePositions :: Number -> Stroke -> Array Point2D

-- Full data with pressure interpolation
generateParticleData :: Number -> Stroke -> Array ParticleSpawnData

type ParticleSpawnData =
  { position :: Point2D
  , pressure :: Number
  , tiltX :: Number
  , tiltY :: Number
  }
```

---

## Canvas.Paint.Brush

Brush configuration and presets.

### BrushConfig

```purescript
type BrushConfig =
  { size :: Number
  , hardness :: Number      -- 0 = soft, 1 = hard edge
  , opacity :: Number       -- 0-1
  , flow :: Number          -- 0-1, paint flow rate
  , spacing :: Number       -- fraction of brush size
  , roundness :: Number     -- 0-1, ellipse ratio
  , angle :: Number         -- rotation in degrees
  }
```

### Presets

```purescript
defaultBrush :: BrushConfig
softBrush :: BrushConfig
hardBrush :: BrushConfig
airbrush :: BrushConfig
calligraphyBrush :: BrushConfig
```

---

## Canvas.Paint.Particle

Paint particle system.

### PaintParticle

```purescript
type PaintParticle =
  { id :: Int
  , position :: Point2D
  , velocity :: Vec2D
  , color :: Color
  , size :: Number
  , wetness :: Number       -- 0-1
  , age :: Number           -- seconds
  }
```

### Operations

```purescript
mkParticle :: Int -> Point2D -> Color -> Number -> PaintParticle
updateParticle :: Number -> PaintParticle -> PaintParticle
isParticleDry :: PaintParticle -> Boolean
particlesToRender :: Array PaintParticle -> Array RenderParticle
```

---

## Canvas.Paint.Drying

Paint drying simulation.

### DryingConfig

```purescript
type DryingConfig =
  { dryingRate :: Number       -- wetness decay per second
  , colorShift :: Number       -- how much color changes when dry
  , absorptionRate :: Number   -- how fast paint absorbs into canvas
  }
```

### Operations

```purescript
defaultDryingConfig :: DryingConfig
applyDrying :: Number -> DryingConfig -> PaintParticle -> PaintParticle
computeDryColor :: Color -> Number -> Color
```

---

## Canvas.Physics.Simulation

SPH fluid dynamics simulation.

### SimulationConfig

```purescript
type SimulationConfig =
  { timestep :: Number         -- seconds
  , substeps :: Int            -- substeps per frame
  , smoothingRadius :: Number  -- SPH kernel radius (px)
  , restDensity :: Number      -- target fluid density
  , stiffness :: Number        -- pressure stiffness (k)
  , viscosity :: Number        -- viscosity coefficient
  , gravityScale :: Number     -- gravity multiplier
  , boundaryDamping :: Number  -- energy loss at boundaries
  , maxParticles :: Int
  }
```

### Presets

```purescript
defaultSimConfig :: SimulationConfig
highQualitySimConfig :: SimulationConfig
fastSimConfig :: SimulationConfig
mkSimulationConfig :: Number -> Int -> Number -> Number -> SimulationConfig
```

### SimParticle

```purescript
type SimParticle =
  { id :: Int
  , position :: Point2D
  , velocity :: Vec2D
  , mass :: Number
  , density :: Number
  , pressure :: Number
  }
```

### SimulationState

```purescript
type SimulationState =
  { particles :: Array SimParticle
  , bounds :: Bounds
  , gravityX :: Number
  , gravityY :: Number
  , time :: Number
  , stepCount :: Int
  }

mkSimulationState :: Bounds -> SimulationState
emptySimState :: SimulationState
```

### Stepping

```purescript
step :: SimulationState -> SimulationState
stepN :: Int -> SimulationState -> SimulationState
stepWithConfig :: SimulationConfig -> SimulationState -> SimulationState
```

### Force Computation

```purescript
computeAllForces :: SimulationConfig -> SimParticle -> Array SimParticle -> Number -> Number -> { fx :: Number, fy :: Number }
computePressureForce :: SimulationConfig -> SimParticle -> Array SimParticle -> { fx :: Number, fy :: Number }
computeViscosityForce :: SimulationConfig -> SimParticle -> Array SimParticle -> { fx :: Number, fy :: Number }
computeGravityForce :: SimulationConfig -> SimParticle -> Number -> Number -> { fx :: Number, fy :: Number }
```

### Spatial Hashing

For O(n) neighbor lookup:

```purescript
type SpatialHash = { cellSize :: Number, cells :: Map Int (Array SimParticle) }

buildSpatialHash :: Number -> Array SimParticle -> SpatialHash
findNeighbors :: SpatialHash -> Number -> Number -> Number -> Array SimParticle
hashPosition :: Number -> Number -> Number -> Int
```

### Integration Methods

```purescript
integrateEuler :: Number -> SimParticle -> { fx :: Number, fy :: Number } -> SimParticle
integrateSemiImplicit :: Number -> SimParticle -> { fx :: Number, fy :: Number } -> SimParticle
integrateVerlet :: Number -> SimParticle -> { fx :: Number, fy :: Number } -> Point2D -> SimParticle
```

### Analysis

```purescript
totalKineticEnergy :: SimulationState -> Number
totalPotentialEnergy :: SimulationState -> Number
maxParticleSpeed :: SimulationState -> Number
averageParticleSpeed :: SimulationState -> Number
```

### Comparison

```purescript
configsEqual :: SimulationConfig -> SimulationConfig -> Boolean
configsDiffer :: SimulationConfig -> SimulationConfig -> Boolean
particlesEqual :: SimParticle -> SimParticle -> Boolean
particlesDiffer :: SimParticle -> SimParticle -> Boolean
```

### Stability Analysis

```purescript
isSimulationStable :: SimulationConfig -> SimulationState -> Boolean
isSimulationSettled :: Number -> Number -> SimulationState -> Boolean
hasHighPressure :: Number -> SimulationState -> Boolean
hasRunawayParticles :: Number -> SimulationState -> Boolean
countActiveParticles :: Number -> SimulationState -> Int
filterStableParticles :: Number -> Number -> SimulationState -> Array SimParticle
filterUnstableParticles :: Number -> Number -> SimulationState -> Array SimParticle
```

---

## Canvas.Physics.Gravity

Device orientation to gravity conversion.

```purescript
type GravityVector = { gx :: Number, gy :: Number }

fromDeviceOrientation :: Number -> Number -> GravityVector
defaultGravity :: GravityVector
zeroGravity :: GravityVector
applyGravityScale :: Number -> GravityVector -> GravityVector
```

---

## Canvas.Physics.Bounds

Boundary enforcement for particles.

```purescript
enforceBounds :: Bounds -> Number -> SimParticle -> SimParticle
reflectAtBoundary :: Bounds -> Number -> SimParticle -> SimParticle
containsPoint :: Bounds -> Point2D -> Boolean
expandBounds :: Number -> Bounds -> Bounds
```

---

## Canvas.Layer.Types

Layer data structures.

### Layer

```purescript
type Layer =
  { id :: LayerId
  , name :: String
  , visible :: Boolean
  , locked :: Boolean
  , opacity :: Number
  , blendMode :: BlendMode
  , content :: LayerContent
  }
```

### BlendMode

```purescript
data BlendMode
  = BlendNormal
  | BlendMultiply
  | BlendScreen
  | BlendOverlay
  | BlendDarken
  | BlendLighten
  | BlendColorDodge
  | BlendColorBurn
  | BlendSoftLight
  | BlendHardLight
  | BlendDifference
  | BlendExclusion
```

---

## Canvas.Layer.Render

Layer rendering pipeline.

```purescript
renderLayer :: Layer -> RenderOutput
renderLayerWithEffects :: Array Effect -> Layer -> RenderOutput
prepareLayerForComposite :: Layer -> CompositeInput
```

---

## Canvas.Layer.Composite

Layer compositing operations.

```purescript
compositeTwo :: Layer -> Layer -> Layer
compositeWithBlend :: BlendMode -> Layer -> Layer -> Layer
compositeStack :: Array Layer -> Layer
applyOpacity :: Number -> Layer -> Layer
flattenLayers :: Array Layer -> Layer
```

---

## Effect Types

Canvas uses graded monads for effect tracking. See `Canvas.Effect.Graded` for details.

```purescript
-- Pure computation (no effects)
type Pure a = Graded () a

-- GPU effects
type GPU a = Graded (gpu :: GPU_EFFECT) a

-- Device sensor effects
type Sensor a = Graded (sensor :: SENSOR_EFFECT) a

-- Combined effects
type App a = Graded (gpu :: GPU_EFFECT, sensor :: SENSOR_EFFECT, state :: STATE_EFFECT) a
```

---

## Examples

### Basic Stroke Recording

```purescript
import Canvas.Paint.Stroke
import Canvas.Types

-- Create a stroke
stroke = beginStroke (mkStrokeId 1) (mkLayerId 0) colorBlack 10.0 100.0 100.0 0.5 0.0

-- Add points
stroke1 = addPoint stroke 110.0 105.0 0.6 16.0
stroke2 = addPoint stroke1 120.0 110.0 0.7 32.0
stroke3 = addPoint stroke2 130.0 112.0 0.5 48.0

-- End stroke
final = endStroke stroke3 48.0

-- Generate particles
particles = generateParticleData 0.3 final
```

### Physics Simulation

```purescript
import Canvas.Physics.Simulation
import Canvas.Types

-- Create simulation
state = mkSimulationState (mkBounds 0.0 0.0 1920.0 1080.0)

-- Add gravity (tilted device)
stateWithGravity = state { gravityX = 2.0, gravityY = 8.0 }

-- Step simulation
state1 = step stateWithGravity
state10 = stepN 10 stateWithGravity

-- Check stability
stable = isSimulationStable defaultSimConfig state10
```

### Layer Compositing

```purescript
import Canvas.Layer.Composite
import Canvas.Layer.Types

-- Composite two layers
combined = compositeWithBlend BlendMultiply topLayer bottomLayer

-- Apply opacity
faded = applyOpacity 0.5 combined

-- Flatten entire stack
flattened = flattenLayers [layer1, layer2, layer3]
```

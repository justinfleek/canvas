# HYDROGEN REFERENCE

**Source**: `/home/justin/jpyxal/hydrogen/`
**Total Files**: 2,029 PureScript + 110 Lean4 proofs
**Dependency**: `path: ../hydrogen` in spago.yaml

---

## CORE ARCHITECTURE

### 1. Render.Element (UI as Pure Data)

**Path**: `src/Hydrogen/Render/Element.purs`

```purescript
import Hydrogen.Render.Element as E

-- Element constructors
E.div_ :: Array (Attribute msg) -> Array (Element msg) -> Element msg
E.button_ :: Array (Attribute msg) -> Array (Element msg) -> Element msg
E.span_ :: Array (Attribute msg) -> Array (Element msg) -> Element msg
E.text :: String -> Element msg

-- Attributes
E.class_ :: String -> Attribute msg
E.id_ :: String -> Attribute msg
E.style :: String -> String -> Attribute msg
E.disabled :: Boolean -> Attribute msg

-- Events
E.onClick :: msg -> Attribute msg
E.onMouseDown :: (MouseEvent -> msg) -> Attribute msg
E.onMouseMove :: (MouseEvent -> msg) -> Attribute msg
E.onMouseUp :: (MouseEvent -> msg) -> Attribute msg
E.onInput :: (String -> msg) -> Attribute msg
E.onKeyDown :: (KeyboardEvent -> msg) -> Attribute msg

-- SVG
E.svg_ :: Array (Attribute msg) -> Array (Element msg) -> Element msg
E.circle_ :: Array (Attribute msg) -> Array (Element msg) -> Element msg
E.rect_ :: Array (Attribute msg) -> Array (Element msg) -> Element msg
E.path_ :: Array (Attribute msg) -> Array (Element msg) -> Element msg
```

### 2. Element.Core (GPU-Native Elements)

**Path**: `src/Hydrogen/Element/Core.purs`

```purescript
import Hydrogen.Element.Core as Core

-- Pure GPU primitives (no DOM)
data Element msg
  = Rectangle RectangleSpec
  | Ellipse EllipseSpec
  | Path PathSpec
  | Text TextSpec
  | Image ImageSpec
  | Video VideoSpec
  | Audio AudioSpec
  | Model3D Model3DSpec
  | Group GroupSpec
  | Transform TransformSpec
  | Empty

-- Constructors
Core.rectangle :: RectangleSpec -> Element msg
Core.ellipse :: EllipseSpec -> Element msg
Core.path :: PathSpec -> Element msg
Core.text :: TextSpec -> Element msg
Core.group :: Array (Element msg) -> Element msg
Core.transform :: Transform2D -> Element msg -> Element msg
```

### 3. Target.DOM (Rendering to Browser)

**Path**: `src/Hydrogen/Target/DOM.purs`

```purescript
import Hydrogen.Target.DOM as TD

type RenderResult =
  { node :: Node
  , cleanup :: Effect Unit
  }

-- Render Element to DOM
TD.render :: Document -> (msg -> Effect Unit) -> Element msg -> Effect RenderResult

-- Render and append to parent
TD.renderTo :: Document -> Node -> (msg -> Effect Unit) -> Element msg -> Effect RenderResult
```

### 4. Runtime.App (Elm Architecture)

**Path**: `src/Hydrogen/Runtime/App.purs`

```purescript
import Hydrogen.Runtime.App as App

type App state msg element =
  { init :: Transition state msg
  , update :: msg -> state -> Transition state msg
  , view :: state -> element
  , subscriptions :: state -> Array (Sub msg)
  , triggers :: Array TriggerDef
  }

-- Subscriptions
data Sub msg
  = OnAnimationFrame (Number -> msg)
  | OnKeyDown (String -> msg)
  | OnKeyUp (String -> msg)
  | OnMouseMove (MousePos -> msg)
  | OnResize (Dimensions -> msg)
  | OnVisibilityChange (Boolean -> msg)
  | OnInterval Number msg

-- Helper
App.app :: { init, update, view } -> App state msg element
```

---

## SCHEMA (Design System Ontology)

### Schema.Physics.Fluid.Particle (SPH Simulation)

**Path**: `src/Hydrogen/Schema/Physics/Fluid/Particle.purs` (675 lines)

```purescript
import Hydrogen.Schema.Physics.Fluid.Particle as SPH

type Particle =
  { id :: Int
  , x :: Number, y :: Number
  , vx :: Number, vy :: Number
  , mass :: Number
  , density :: Number
  , pressure :: Number
  , viscosity :: Number
  }

type ParticleSystem =
  { particles :: Array Particle
  , smoothingRadius :: Number
  , restDensity :: Number
  , stiffness :: Number
  , viscosityCoeff :: Number
  , gravity :: { x :: Number, y :: Number }
  , nextId :: Int
  }

-- Kernels
SPH.kernelPoly6 :: Number -> Number -> Number       -- Density
SPH.kernelSpiky :: Number -> Number -> Number       -- Pressure  
SPH.kernelViscosity :: Number -> Number -> Number   -- Viscosity
SPH.kernelGradientSpiky :: Number -> Number -> Number
SPH.kernelLaplacianViscosity :: Number -> Number -> Number

-- Simulation
SPH.computeDensity :: ParticleSystem -> Particle -> Number
SPH.computeAllDensities :: ParticleSystem -> ParticleSystem
SPH.computePressure :: Number -> Number -> Number -> Number
SPH.computeAllPressures :: ParticleSystem -> ParticleSystem
SPH.computeTotalForce :: ParticleSystem -> Particle -> { fx :: Number, fy :: Number }
SPH.integrateParticle :: ParticleSystem -> Particle -> Number -> Particle
SPH.integrateSystem :: ParticleSystem -> Number -> ParticleSystem

-- Boundaries
data BoundaryType = ReflectBoundary | ClampBoundary | WrapBoundary
SPH.enforceBoundary :: BoundaryType -> Number -> Number -> Number -> Number -> Number -> Particle -> Particle
```

### Schema.Brush.WetMedia (Paint Properties)

**Path**: `src/Hydrogen/Schema/Brush/WetMedia/`

```purescript
import Hydrogen.Schema.Brush.WetMedia as WM
import Hydrogen.Schema.Brush.WetMedia.Atoms as WMA
import Hydrogen.Schema.Brush.WetMedia.Dynamics as WMD

-- Types (ADTs)
data WetMediaType = Watercolor | OilPaint | Acrylic | Gouache | Ink | WetIntoWet
data WetInteraction = WetOnDry | WetOnWet | WetInWet | DryBrush

-- Atoms (bounded values 0-1)
WMA.Wetness, WMA.Viscosity, WMA.Dilution, WMA.PigmentLoad
WMA.BleedRate, WMA.DryingRate, WMA.Granulation, WMA.Diffusion

-- Presets
WMA.wetnessDry, WMA.wetnessDamp, WMA.wetnessWet, WMA.wetnessSoaked
WMA.viscosityWatery, WMA.viscosityThin, WMA.viscosityMedium, WMA.viscosityThick

-- Dynamics (tilt → gravity → flow)
WMD.GravityDirection
WMD.FlowVelocity
WMD.tiltToGravity :: DeviceOrientation -> GravityDirection
WMD.calculateFlowVelocity :: GravityDirection -> Viscosity -> Wetness -> FlowVelocity
WMD.applyDrying :: DryingRate -> Number -> Wetness -> Wetness
WMD.canFlow :: Viscosity -> Wetness -> Boolean
```

### Schema.Canvas.Physics (Device Orientation)

**Path**: `src/Hydrogen/Schema/Canvas/Physics.purs` (494 lines)

```purescript
import Hydrogen.Schema.Canvas.Physics as CP

type DeviceOrientation =
  { alpha :: Number  -- Compass heading (0-360)
  , beta :: Number   -- Front-back tilt (-180 to 180)
  , gamma :: Number  -- Left-right tilt (-90 to 90)
  }

type GravityVector =
  { x :: Number, y :: Number, z :: Number }

type CanvasPhysics =
  { orientation :: DeviceOrientation
  , gravity :: GravityVector
  , gravityScale :: Number
  }

-- Constructors
CP.mkDeviceOrientation :: Number -> Number -> Number -> DeviceOrientation
CP.mkGravityVector :: Number -> Number -> Number -> GravityVector
CP.mkCanvasPhysics :: Number -> CanvasPhysics

-- Presets
CP.orientationFlat :: DeviceOrientation
CP.orientationPortrait :: DeviceOrientation
CP.orientationLandscapeLeft :: DeviceOrientation
CP.orientationLandscapeRight :: DeviceOrientation

-- Conversion
CP.orientationToGravity :: DeviceOrientation -> GravityVector
CP.getGravity2D :: CanvasPhysics -> { x :: Number, y :: Number }
CP.gravityMagnitude :: GravityVector -> Number
CP.gravityAngle :: GravityVector -> Number
CP.isGravitySignificant :: GravityVector -> Number -> Boolean

-- Updates
CP.updateOrientation :: DeviceOrientation -> CanvasPhysics -> CanvasPhysics
CP.updateAccelerometer :: AccelerometerData -> CanvasPhysics -> CanvasPhysics
```

---

## MOTION (Gestures & Animation)

### Motion.Gesture (Touch/Mouse Recognition)

**Path**: `src/Hydrogen/Motion/Gesture.purs` (779 lines)

```purescript
import Hydrogen.Motion.Gesture as G

-- Gesture state
data GestureState = Idle | Active | Ended

type Point = { x :: Number, y :: Number }
type Velocity = { vx :: Number, vy :: Number }

-- Pan gesture
type PanState = { state :: GestureState, start :: Point, current :: Point, delta :: Point, velocity :: Velocity }
type PanConfig = { onStart :: PanState -> Effect Unit, onMove :: ..., onEnd :: ..., threshold :: Number }
G.createPanGesture :: Element -> PanConfig -> Effect PanGesture

-- Pinch gesture
type PinchState = { state :: GestureState, scale :: Number, initialScale :: Number, center :: Point }
type PinchConfig = { onStart :: ..., onPinch :: ..., onEnd :: ..., minScale :: Number, maxScale :: Number }
G.createPinchGesture :: Element -> PinchConfig -> Effect PinchGesture

-- Rotate gesture
type RotateState = { state :: GestureState, rotation :: Number, center :: Point, velocity :: Number }
G.createRotateGesture :: Element -> RotateConfig -> Effect RotateGesture

-- Swipe gesture
data SwipeDirection = SwipeLeft | SwipeRight | SwipeUp | SwipeDown
G.createSwipeGesture :: Element -> SwipeConfig -> Effect SwipeGesture

-- Long press
G.createLongPressGesture :: Element -> LongPressConfig -> Effect LongPressGesture

-- Double tap
G.createDoubleTapGesture :: Element -> DoubleTapConfig -> Effect DoubleTapGesture

-- Pure geometry (no FFI)
G.pointDistance :: Point -> Point -> Number
G.pointCenter :: Point -> Point -> Point
G.pointAngle :: Point -> Point -> Number
G.detectSwipeDirection :: SwipeParams -> Maybe SwipeDirection
G.computePinchScale :: { initialScale, initialDistance, currentDistance } -> { minScale, maxScale } -> Number
```

### Motion.Spring (Physics Animation)

**Path**: `src/Hydrogen/Motion/Spring.purs`

```purescript
import Hydrogen.Motion.Spring as Spring

type SpringConfig = { stiffness :: Number, damping :: Number, mass :: Number }

Spring.defaultConfig :: SpringConfig
Spring.stiff :: SpringConfig
Spring.gentle :: SpringConfig
Spring.wobbly :: SpringConfig

Spring.animate :: SpringConfig -> Number -> Number -> (Number -> Effect Unit) -> Effect Unit
```

---

## EFFECT SYSTEM (Graded Monads)

### Effect.Grade (Type-Level Labels)

**Path**: `src/Hydrogen/Effect/Grade.purs` (220 lines)

```purescript
import Hydrogen.Effect.Grade

-- Effect label kind
data GradeLabel

-- Labels
foreign import data Net :: GradeLabel      -- Network I/O
foreign import data Auth :: GradeLabel     -- Authentication
foreign import data Config :: GradeLabel   -- Configuration
foreign import data Log :: GradeLabel      -- Logging
foreign import data Crypto :: GradeLabel   -- Cryptography
foreign import data Fs :: GradeLabel       -- Filesystem

-- Grade type (type-level list)
foreign import data Grade :: Type
foreign import data Pure :: Grade          -- No effects (bottom)
foreign import data NetOnly :: Grade       -- Just Net
foreign import data AuthOnly :: Grade      -- Just Auth
foreign import data NetAuth :: Grade       -- Net + Auth
foreign import data Full :: Grade          -- All effects (top)

-- Type classes
class GradeUnion f g result | f g -> result    -- Union of grades
class GradeMember l g                          -- Label in grade
class GradeSubset f g                          -- Subeffecting
```

### Effect.Graded (Graded Monad)

**Path**: `src/Hydrogen/Effect/Graded.purs` (208 lines)

```purescript
import Hydrogen.Effect.Graded

-- Value-level cost tracking
type HydrogenGrade =
  { latencyMs :: Int
  , inputTokens :: Int
  , outputTokens :: Int
  , providerCalls :: Int
  , retries :: Int
  , cacheHits :: Int
  , cacheMisses :: Int
  }

-- Value-level coeffects (what computation NEEDS)
type HydrogenCoEffect =
  { httpAccesses :: Array HttpAccess
  , authUsages :: Array AuthUsage
  , configAccesses :: Array ConfigAccess
  }

-- Result type
type HydrogenResult a =
  { result :: a
  , grade :: HydrogenGrade
  , coeffect :: HydrogenCoEffect
  , provenance :: HydrogenProvenance
  }

-- Graded monad
newtype HydrogenM :: Grade -> Type -> Type
newtype HydrogenM g a = HydrogenM (Effect (HydrogenResult a))

-- Running
runHydrogenM :: forall g a. HydrogenM g a -> Effect (HydrogenResult a)
runHydrogenMPure :: forall g a. HydrogenM g a -> Effect a

-- Helpers
emptyGrade :: HydrogenGrade
emptyCoEffect :: HydrogenCoEffect
combineGrades :: HydrogenGrade -> HydrogenGrade -> HydrogenGrade
```

---

## COMPOUNDS (95 UI Components)

### Element.Compound.Canvas (Infinite Canvas)

**Path**: `src/Hydrogen/Element/Compound/Canvas/`

```
Canvas/
├── Types.purs           # CanvasObject, CanvasTool, GridConfig
├── State.purs           # CanvasState management
│   ├── Core.purs        # InteractionMode, initialCanvasState
│   ├── Viewport.purs    # panBy, zoomIn, zoomOut, zoomToFit
│   ├── Tools.purs       # setTool, previousTool
│   ├── Selection.purs   # selectObject, deselectAll, selectInRect
│   ├── Objects.purs     # addObject, removeObject, bringToFront
│   ├── Gestures.purs    # getGestureState, updatePointerState
│   ├── Interaction.purs # setInteractionMode, setHoveredObject
│   ├── Keyboard.purs    # isCtrlHeld, isShiftHeld
│   ├── History.purs     # undo, redo, pushHistory
│   └── Queries.purs     # visibleObjects, screenToCanvas
├── Render.purs          # canvas → Element
│   ├── Types.purs       # CanvasMsg
│   ├── Objects.purs     # renderObject
│   ├── Selection.purs   # renderSelectionHandles
│   ├── Grid.purs        # renderGrid
│   ├── Guides.purs      # renderGuides
│   ├── Rulers.purs      # renderRulers
│   └── Layers.purs      # composeLayers
├── Selection.purs       # hitTestPoint, LassoPath
├── Transform.purs       # moveObject, scaleObject, rotateObject
├── Grid.purs            # GridSpacing, snapToGrid
└── Grid3D.purs          # 3D grid for motion graphics
```

### Element.Compound.ColorPicker

**Path**: `src/Hydrogen/Element/Compound/ColorPicker/`

### Element.Compound.Slider

**Path**: `src/Hydrogen/Element/Compound/Slider/`

### Element.Compound.Confetti

**Path**: `src/Hydrogen/Element/Compound/Confetti.purs`

---

## LEAN4 PROOFS (110 files)

### Math Proofs

| File | Key Theorems |
|------|--------------|
| `Vec2.lean` | `perp_orthogonal`, `perp_perp = -v` |
| `Vec3.lean` | `cross_perp_left`, `cross_perp_right`, `normalize_length = 1` |
| `Mat4.lean` | `mul_assoc` (critical for transforms) |
| `Force.lean` | `vortex_force_orthogonal` (vortex does no radial work) |
| `Integration.lean` | `verlet_time_reversible` (energy conservation) |
| `Quaternion.lean` | `det_toMat4_unit = 1` (unit quaternions are rotations) |

### Material Proofs

| File | Key Theorems |
|------|--------------|
| `BRDF.lean` | `fresnelSchlick_le_one`, `energy_conservation` (F + diffuse = 1) |
| `ISP.lean` | `exposureFactor_pos`, `vignetting_bounded` |

### WorldModel Proofs (Safety Critical)

| File | Key Theorems |
|------|--------------|
| `Rights.lean` | `temporal_safety`, `no_trapped_states`, `resource_floor` |
| `Consent.lean` | `default_deny`, `consent_sovereignty`, `can_always_revoke` |
| `ExitGuarantee.lean` | `exit_preempts_experience`, `termination_is_final` |
| `Temporal.lean` | `anti_torture_loop`, `one_hour_limit` (10 experiential hours max) |

### Scale Proofs

| File | Key Theorems |
|------|--------------|
| `HierarchicalAggregation.lean` | `hierarchical_comm_O_n`, `billion_agent_messages ≤ 2×10^9` |

---

## USAGE PATTERNS

### Basic App Setup

```purescript
module Main where

import Prelude
import Effect (Effect)
import Hydrogen.Runtime.App as App
import Hydrogen.Target.DOM as TD
import Hydrogen.Render.Element as E

type State = { count :: Int }
data Msg = Increment | Decrement

main :: Effect Unit
main = do
  doc <- window >>= document
  container <- getElementById "app" doc
  
  let app = App.app
        { init: { state: { count: 0 }, cmd: App.none }
        , update: \msg state -> case msg of
            Increment -> { state: state { count = state.count + 1 }, cmd: App.none }
            Decrement -> { state: state { count = state.count - 1 }, cmd: App.none }
        , view: \state ->
            E.div_ []
              [ E.button_ [ E.onClick Decrement ] [ E.text "-" ]
              , E.span_ [] [ E.text (show state.count) ]
              , E.button_ [ E.onClick Increment ] [ E.text "+" ]
              ]
        }
  
  -- Run with subscriptions
  runApp app container
```

### Animation Loop

```purescript
subscriptions :: State -> Array (App.Sub Msg)
subscriptions state =
  if state.isAnimating
    then [ App.OnAnimationFrame Tick ]
    else []

update :: Msg -> State -> App.Transition State Msg
update msg state = case msg of
  Tick timestamp ->
    let dt = timestamp - state.lastFrame
    in { state: state { lastFrame = timestamp, particles = simulate dt state.particles }
       , cmd: App.none
       }
```

### Gesture Handling

```purescript
import Hydrogen.Motion.Gesture as G

setupGestures :: Element -> Effect Unit
setupGestures el = do
  _ <- G.createPanGesture el
    { onStart: \s -> log "Pan started"
    , onMove: \s -> updatePan s.delta
    , onEnd: \s -> commitPan s.velocity
    , threshold: 5.0
    , lockAxis: false
    , preventScroll: true
    }
  
  _ <- G.createPinchGesture el
    { onStart: \s -> log "Pinch started"
    , onPinch: \s -> setZoom s.scale
    , onEnd: \s -> commitZoom s.scale
    , minScale: 0.1
    , maxScale: 10.0
    }
  
  pure unit
```

---

*Reference generated from hydrogen source at /home/justin/jpyxal/hydrogen/*

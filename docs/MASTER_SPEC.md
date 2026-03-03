# CANVAS MASTER SPEC

**Version**: 0.1.0
**Date**: 2026-03-03
**Status**: PLANNING

---

## VISION

Canvas is a **professional digital art application** where every paint particle is
a physics-simulated agent. When you tilt your phone, paint flows realistically
using SPH fluid dynamics. This is not a toy — it's a billion-agent system where
each pigment particle follows verified physics.

---

## WHAT WE'RE BUILDING

A universal rendering surface where:
1. **Paint is physics** — SPH fluid simulation with viscosity, density, pressure
2. **Tilt = gravity** — Device orientation controls paint flow direction
3. **Wet media** — Watercolor, oil, acrylic, ink with proper drying/blending
4. **Verified math** — Lean4 proofs guarantee physics correctness
5. **Billion-agent scale** — Same primitives work for one stroke or 10M particles

---

## HYDROGEN DEPENDENCIES

### Schema Atoms Required

| Pillar | Atoms | Purpose |
|--------|-------|---------|
| **Physics/Fluid** | Particle, ParticleSystem, SPH kernels | Core fluid simulation |
| **Physics/Force** | uniformForce, gravityForce, vortexForce | Force field effects |
| **Brush/WetMedia** | Wetness, Viscosity, Dilution, PigmentLoad | Paint material properties |
| **Brush/WetMedia/Dynamics** | tiltToGravity, calculateFlowVelocity | Device orientation → flow |
| **Brush/Tilt** | Tilt response for stylus/device | Tilt angle → brush behavior |
| **Brush/Pressure** | Pressure sensitivity | Pen pressure → opacity/size |
| **Brush/Dynamics** | Size, opacity, flow dynamics | Per-stroke dynamics |
| **Brush/ColorDynamics** | Hue/saturation jitter | Color variation |
| **Brush/Texture** | Brush tip texture | Surface texture |
| **Canvas/Bounds** | CanvasBounds, CoordinateSystem | Viewport bounds |
| **Canvas/Physics** | DeviceOrientation, GravityVector | Device → canvas gravity |
| **Canvas/Grid** | GridConfig, CellIndex | Spatial partitioning |
| **Canvas/Background** | BackgroundFill, PaperTexture | Surface material |
| **Color** | SRGB, OKLCH, Opacity, BlendMode | All color operations |
| **Geometry/Transform** | Scale, Translate, Rotate | Transform stack |
| **Gestural/Pointer** | Pressure, TiltX, TiltY, Twist | Stylus input |
| **Gestural/Touch** | TouchPoint, TouchState | Multi-touch |
| **Motion/Gesture** | Pan, Pinch, Rotate, Swipe | Gesture recognition |
| **Temporal/Duration** | Milliseconds, Frames | Animation timing |
| **Temporal/Easing** | CubicBezier, Spring | Animation curves |
| **Elevation/ZIndex** | ZIndex, DepthEffects | Layer ordering |
| **Haptic** | Intensity, Sharpness, Patterns | Tactile feedback |

### Lean4 Proofs Required

| Proof | File | Guarantee |
|-------|------|-----------|
| `vortex_force_orthogonal` | Math/Force.lean | Tangential force is perpendicular |
| `verlet_time_reversible` | Math/Integration.lean | Physics is reversible |
| `cross_perp_left/right` | Math/Vec3.lean | Cross product correctness |
| `normalize_length` | Math/Vec3.lean | Unit vectors are unit |
| `mul_assoc` (Mat4) | Math/Mat4.lean | Transform composition |
| `complement_involutive` | Schema/Color/Hue.lean | Color math correct |
| `fresnelSchlick_le_one` | Material/BRDF.lean | Energy conservation |

### Compounds Required

| Compound | Path | Purpose |
|----------|------|---------|
| Canvas | Element/Compound/Canvas | Infinite pan/zoom surface |
| Canvas.State | Canvas/State | Viewport, selection, history |
| Canvas.Grid | Canvas/Grid | Snap, spatial partitioning |
| Motion.Timeline | Compound/Motion/Timeline | Keyframe animation |
| Confetti | Element/Compound/Confetti | Particle effects |
| ColorPicker | Element/Compound/ColorPicker | Color selection |
| Slider | Element/Compound/Slider | Property sliders |
| Button | Element/Compound/Button | Tool buttons |

---

## LAYER SYSTEM (Z-Indexed)

Each layer is a window with isolated rendering. From bottom to top:

| Z | Layer | Type | Blend | Mask | Contents |
|---|-------|------|-------|------|----------|
| 0 | Background | Static | Normal | None | Paper texture, fill color |
| 1-99 | Paint Layers | Dynamic | User | Optional | Paint strokes, particles |
| 100 | Active Stroke | Dynamic | Normal | None | Current brush stroke |
| 101 | Selection | UI | Normal | None | Selection rectangle, handles |
| 102 | Guides | UI | Normal | None | Grid, rulers, guides |
| 103 | Tools | UI | Normal | None | Tool cursors |
| 104 | Overlays | UI | Normal | None | Tooltips, menus |
| 105 | Debug | UI | Normal | None | Debug visualization |

### Layer Properties (per layer)

```purescript
type Layer =
  { id :: LayerId
  , name :: String
  , zIndex :: ZIndex                  -- 0-999
  , visible :: Boolean
  , locked :: Boolean
  , opacity :: Opacity                -- 0-100
  , blendMode :: BlendMode            -- 28 modes
  , clipMask :: Maybe LayerId         -- Clip to another layer
  , particles :: ParticleSystem       -- SPH fluid system
  , strokes :: Array Stroke           -- Committed strokes
  , bounds :: CanvasBounds            -- Layer bounds
  }
```

### Diffusion/Noise Isolation

When a layer has a diffusion model noise property:
1. Noise renders ONLY within layer bounds (clipped)
2. No bleed to adjacent layers
3. Achieved via WebGL stencil buffer + framebuffer

```purescript
-- Per-layer framebuffer
type LayerFramebuffer =
  { colorTexture :: WebGLTexture
  , stencilBuffer :: WebGLRenderbuffer
  , width :: Int
  , height :: Int
  }

-- Composite layers with proper isolation
compositeLayers :: Array Layer -> WebGLTexture
```

---

## TRIGGERS & EVENTS

### Input Events (Atoms)

| Event | Source | Schema |
|-------|--------|--------|
| PointerDown | Mouse/Pen/Touch | Schema.Gestural.Pointer |
| PointerMove | Mouse/Pen/Touch | Schema.Gestural.Pointer |
| PointerUp | Mouse/Pen/Touch | Schema.Gestural.Pointer |
| Pressure | Pen | Schema.Gestural.Pointer.Pressure |
| Tilt | Pen/Device | Schema.Gestural.Pointer.Tilt |
| Twist | Pen | Schema.Gestural.Pointer.Twist |
| KeyDown | Keyboard | Schema.Gestural.Keyboard |
| KeyUp | Keyboard | Schema.Gestural.Keyboard |
| DeviceOrientation | Accelerometer | Schema.Canvas.Physics |
| Pinch | Multi-touch | Schema.Gestural.Gesture |
| Rotate | Multi-touch | Schema.Gestural.Gesture |
| Pan | Multi-touch | Schema.Gestural.Gesture |

### Gesture Recognition

From `Hydrogen.Motion.Gesture`:
- PanGesture — Canvas panning
- PinchGesture — Canvas zoom
- RotateGesture — Canvas rotation
- SwipeGesture — Tool shortcuts
- LongPressGesture — Context menu
- DoubleTapGesture — Zoom to fit

### Easter Eggs

| Trigger | Reward |
|---------|--------|
| Konami code | Confetti explosion |
| Shake 5x | Etch-a-sketch clear |
| Tap corners | Secret palette |

---

## PHYSICS SIMULATION

### SPH Fluid Dynamics

Each paint particle follows SPH:

```
ρ_i = Σ_j m_j * W(r_ij, h)           -- Density
p_i = k * (ρ_i - ρ_0)                 -- Pressure
F_pressure = -Σ_j m_j * (p_i + p_j) / (2ρ_j) * ∇W
F_viscosity = μ * Σ_j m_j * (v_j - v_i) / ρ_j * ∇²W
F_gravity = m_i * g                   -- Device tilt
```

### Integration (Verified in Lean4)

Using semi-implicit Euler (symplectic):
```purescript
-- From Physics/Fluid/Particle.purs
integrateParticle :: ParticleSystem -> Particle -> Number -> Particle
integrateParticle sys p dt =
  let
    force = computeTotalForce sys p
    ax = force.fx / p.mass
    ay = force.fy / p.mass
    newVx = p.vx + ax * dt
    newVy = p.vy + ay * dt
    newX = p.x + newVx * dt
    newY = p.y + newVy * dt
  in
    p { x = newX, y = newY, vx = newVx, vy = newVy }
```

### Device Orientation → Gravity

```purescript
-- From Brush/WetMedia/Dynamics.purs
tiltToGravity :: DeviceOrientation -> GravityVector
calculateFlowVelocity :: GravityDirection -> Viscosity -> Wetness -> FlowVelocity
```

### Wet Media Properties

| Property | Type | Range | Effect |
|----------|------|-------|--------|
| Wetness | Number | 0-1 | How liquid the paint is |
| Viscosity | Number | 0-1 | Resistance to flow |
| Dilution | Number | 0-1 | Water-to-pigment ratio |
| PigmentLoad | Number | 0-1 | Color intensity |
| BleedRate | Number | 0-1 | Edge diffusion speed |
| DryingRate | Number | 0-1 | How fast it dries |
| Granulation | Number | 0-1 | Pigment settling |

---

## RENDERING PIPELINE

### Per-Frame Update

```
1. Read device orientation → update gravity vector
2. For each active layer with particles:
   a. Compute densities (O(n²) with spatial hash)
   b. Compute pressures
   c. Compute forces (pressure + viscosity + gravity)
   d. Integrate particles (symplectic Euler)
   e. Apply boundary conditions
   f. Update drying state
3. Commit fully-dried particles to stroke cache
4. Render layers bottom-to-top:
   a. Bind layer framebuffer
   b. Set stencil for isolation
   c. Render particles as point sprites
   d. Render cached strokes
5. Composite all layers to screen
6. Render UI overlays
```

### Caching Strategy

| Content | Cache Type | Invalidation |
|---------|------------|--------------|
| Dried strokes | GPU texture | Layer edit |
| Static layers | Framebuffer | Property change |
| Grid | Vertex buffer | Zoom change |
| UI elements | Virtual DOM | State change |

### WebGL/WebGPU Specifics

- **Point sprites** for particles (1 vertex = 1 particle)
- **Instanced rendering** for large particle counts
- **Framebuffer per layer** for compositing
- **Stencil buffer** for clip masks
- **Compute shaders** (WebGPU) for physics when available

---

## STRAYLIGHT REPOS USED

| Repo | Component | Usage |
|------|-----------|-------|
| hydrogen | Schema/* | All atoms, proofs |
| hydrogen | Element/Compound/* | UI components |
| hydrogen | Motion/Gesture | Gesture recognition |
| hydrogen | proofs/Math/* | Physics verification |
| libevring | Evring/Event | Event loop pattern |
| straylight-web | Router, UI | Navigation pattern |

---

## FILE STRUCTURE

```
canvas/
├── spago.yaml                      # Depends on hydrogen
├── src/
│   ├── Main.purs                   # Entry point
│   ├── Canvas/
│   │   ├── App.purs                # Main application
│   │   ├── State.purs              # Global state
│   │   ├── Update.purs             # State transitions
│   │   ├── View.purs               # Root render
│   │   ├── Types.purs              # Shared types
│   │   │
│   │   ├── Layer/
│   │   │   ├── Types.purs          # Layer types
│   │   │   ├── Render.purs         # Layer rendering
│   │   │   ├── Composite.purs      # Layer compositing
│   │   │   └── Panel.purs          # Layer panel UI
│   │   │
│   │   ├── Paint/
│   │   │   ├── Stroke.purs         # Stroke recording
│   │   │   ├── Brush.purs          # Brush configuration
│   │   │   ├── Particle.purs       # Particle wrapper
│   │   │   └── Drying.purs         # Drying simulation
│   │   │
│   │   ├── Physics/
│   │   │   ├── Gravity.purs        # Device → gravity
│   │   │   ├── Simulation.purs     # SPH step wrapper
│   │   │   └── Bounds.purs         # Boundary handling
│   │   │
│   │   ├── Tool/
│   │   │   ├── Types.purs          # Tool enum
│   │   │   ├── Brush.purs          # Brush tool
│   │   │   ├── Eraser.purs         # Eraser tool
│   │   │   ├── Eyedropper.purs     # Color picker
│   │   │   ├── Pan.purs            # Hand/pan tool
│   │   │   └── Selection.purs      # Selection tool
│   │   │
│   │   ├── UI/
│   │   │   ├── Toolbar.purs        # Tool palette
│   │   │   ├── ColorPanel.purs     # Color selection
│   │   │   ├── BrushPanel.purs     # Brush settings
│   │   │   ├── LayerPanel.purs     # Layer stack
│   │   │   ├── Timeline.purs       # Animation timeline
│   │   │   └── Debug.purs          # Debug overlay
│   │   │
│   │   └── WebGL/
│   │       ├── Context.purs        # WebGL setup
│   │       ├── Shader.purs         # Shader programs
│   │       ├── Particle.purs       # Particle rendering
│   │       └── Composite.purs      # Layer compositing
│   │
│   └── Canvas.purs                 # Module exports
│
└── proofs/                         # Any canvas-specific proofs
    └── Canvas.lean
```

---

## IMMEDIATE NEXT STEPS

1. [ ] Set up spago with hydrogen dependency
2. [ ] Create Canvas/Types.purs with core types
3. [ ] Create Canvas/State.purs using Hydrogen Canvas.State
4. [ ] Create Canvas/Physics/Gravity.purs wrapping device orientation
5. [ ] Create Canvas/Paint/Particle.purs wrapping SPH system
6. [ ] Create Canvas/Layer/Types.purs with layer system
7. [ ] Create Canvas/View.purs with basic render
8. [ ] Wire to Hydrogen Render.Element

---

## SUCCESS CRITERIA

When complete, Canvas will:

1. **Render paint strokes** with realistic wet media behavior
2. **Respond to device tilt** by flowing paint in gravity direction
3. **Support multiple layers** with proper isolation and compositing
4. **Handle stylus input** with pressure, tilt, and twist
5. **Verify physics** via Lean4 proofs (energy conservation, reversibility)
6. **Scale to millions of particles** using spatial hashing + GPU
7. **Run at 60fps** on modern devices
8. **Export to static images** or animation sequences

---

*"Everyone."* — Norman Stansfield


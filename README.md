# Canvas

A professional digital art application with physics-simulated paint, built in pure PureScript.

When users tilt their device, paint flows realistically using SPH (Smoothed Particle Hydrodynamics) fluid dynamics. Canvas proves that functional programming can deliver real-time, interactive experiences with full type safety.

## Features

- **Physics-Simulated Paint**: SPH fluid dynamics for realistic paint flow
- **Device Integration**: Accelerometer-driven gravity, pressure-sensitive stylus support
- **Layer System**: Professional compositing with blend modes and opacity
- **Stroke Recording**: Full pressure/tilt capture for replay and analysis
- **Paint Drying**: Realistic wet-to-dry transitions with color shifts

## Quick Start

```bash
# Enter development shell (requires Nix)
nix develop

# Build the project
spago build

# Run tests (when available)
spago test
```

## Architecture

Canvas is built on [Hydrogen](https://github.com/straylight-software/hydrogen), a PureScript UI framework with graded monads for effect tracking.

```
src/
├── Main.purs                 # Application entry point
├── Canvas.purs               # Module re-exports
├── Canvas/
│   ├── Types.purs            # Core types (Point2D, Vec2D, Color, etc.)
│   ├── State.purs            # Application state management
│   ├── View.purs             # UI rendering
│   ├── Layer/
│   │   ├── Types.purs        # Layer data structures
│   │   ├── Render.purs       # Layer rendering pipeline
│   │   └── Composite.purs    # Layer compositing operations
│   ├── Paint/
│   │   ├── Particle.purs     # Paint particle system
│   │   ├── Stroke.purs       # Stroke recording and analysis
│   │   ├── Brush.purs        # Brush configuration
│   │   └── Drying.purs       # Paint drying simulation
│   ├── Physics/
│   │   ├── Gravity.purs      # Device orientation → gravity
│   │   ├── Simulation.purs   # SPH fluid simulation
│   │   └── Bounds.purs       # Boundary enforcement
│   └── Effect/
│       └── Graded.purs       # Graded monad effect types
```

## Core Concepts

### SPH Fluid Simulation

Canvas uses Smoothed Particle Hydrodynamics for paint physics:

1. **Density Calculation**: Each particle's density is computed from neighbors using the Poly6 kernel
2. **Pressure Forces**: Repulsive forces from the Spiky kernel gradient prevent compression
3. **Viscosity**: The Laplacian kernel smooths velocity differences between particles
4. **Integration**: Semi-implicit Euler (symplectic) for energy conservation

```purescript
-- Step the simulation
newState = Canvas.Physics.Simulation.step state

-- Check stability
stable = isSimulationStable config state
```

### Stroke Recording

Strokes capture full stylus/touch state at each point:

```purescript
-- Begin a stroke
stroke = beginStroke strokeId layerId color brushSize x y pressure timestamp

-- Add points as the user draws
stroke' = addPoint stroke x y pressure timestamp

-- End the stroke
finalStroke = endStroke stroke' endTimestamp

-- Generate particles for rendering
particles = generateParticleData 0.5 finalStroke
```

### Layer Compositing

Layers support professional blend modes and effects:

```purescript
-- Composite layers with blend mode
result = compositeWithBlend BlendMultiply topLayer bottomLayer

-- Apply opacity
faded = applyOpacity 0.7 layer
```

## Device Integration

Canvas responds to device sensors:

- **Accelerometer**: Tilting the device changes gravity direction, causing paint to flow
- **Pressure Sensitivity**: Stylus pressure affects brush size, opacity, and flow
- **Tilt Detection**: Stylus angle influences brush shape and texture

## Dependencies

- **PureScript 0.15+**
- **Hydrogen** - UI framework with graded effects
- **Nix** - Build system (flake-based)

## Development

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- Git

### Building

```bash
# Enter the development shell
nix develop

# Build
spago build

# Watch mode
spago build --watch
```

### Code Style

- **Zero warnings**: All imports must be used
- **Explicit imports**: No `(..)` patterns
- **500 lines max per file**: Split large modules
- **No stubs**: Every function must be complete

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Ensure `spago build` produces zero warnings
4. Submit a pull request

---

Built with PureScript + Hydrogen by [Straylight Software](https://straylight.software)

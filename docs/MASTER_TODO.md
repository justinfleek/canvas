# CANVAS MASTER TODO

**Generated**: 2026-03-03
**Status**: Comprehensive implementation plan based on hydrogen audit

---

## HYDROGEN INVENTORY (2,029 PureScript files + 110 Lean4 proofs)

### Core Architecture Available

| Category | Files | Key Modules |
|----------|-------|-------------|
| **Schema** | 1,107 | Complete design system ontology |
| **Element** | 449 | UI components (95 compounds including Canvas) |
| **GPU** | 167 | WebGPU, Scene3D, compute kernels |
| **Render** | 19 | DOM/SVG rendering pipeline |
| **Runtime** | 11 | App runtime, commands, animation |
| **Motion** | 5 | Gesture, spring, transitions |
| **Target** | 4 | DOM, Halogen, Static, HyperConsole |

### Lean4 Proofs Available (110 files)

| Domain | Files | Key Theorems |
|--------|-------|--------------|
| Math | 18 | vortex_force_orthogonal, verlet_time_reversible, mul_assoc |
| Material | 5 | fresnelSchlick_le_one, energy_conservation |
| WorldModel | 18 | temporal_safety, exit_guarantee, consent_sovereignty |
| Scale | 2 | billion_agent_messages ≤ 2×10^9, hierarchical_comm_O_n |

---

## CURRENT CANVAS STATUS

| File | Lines | Status | Notes |
|------|-------|--------|-------|
| `Main.purs` | 11 | STUB | Entry point only |
| `Canvas/Types.purs` | 665 | COMPLETE | All core types |
| `Canvas/View.purs` | 4 | STUB | Empty placeholder |
| `Canvas/State.purs` | 507 | COMPLETE | Full state management |
| `Canvas/Layer/Types.purs` | 555 | COMPLETE | Layer system |
| `Canvas/Paint/Particle.purs` | 664 | COMPLETE | SPH physics |
| `Canvas/Effect/Graded.purs` | 170 | PARTIAL | Types only, no impls |
| `Canvas/Physics/Gravity.purs` | 379 | COMPLETE | Device orientation |

**Total: ~2,955 lines across 8 files**

---

## HYDROGEN MODULES REQUIRED

### Already Referenced (CRITICAL - MUST EXIST)

These are imported by canvas files and MUST be available:

| Module | Required By | Status |
|--------|-------------|--------|
| `Hydrogen.Schema.Physics.Fluid.Particle` | Particle.purs | EXISTS |
| `Hydrogen.Schema.Physics.Fluid.Solver` | Particle.purs | EXISTS |
| `Hydrogen.Schema.Brush.WetMedia` | Particle.purs | EXISTS |
| `Hydrogen.Schema.Brush.WetMedia.Atoms` | Particle.purs, Gravity.purs | EXISTS |
| `Hydrogen.Schema.Brush.WetMedia.Dynamics` | Particle.purs, Gravity.purs | EXISTS |
| `Hydrogen.Schema.Canvas.Physics` | Gravity.purs | EXISTS |
| `Hydrogen.Effect.Grade` | Graded.purs | EXISTS |
| `Hydrogen.Effect.Graded` | Graded.purs | EXISTS |

### Needed for View Layer

| Module | Purpose |
|--------|---------|
| `Hydrogen.Render.Element` | div_, button_, onClick, etc. |
| `Hydrogen.Render.Element.HTML` | HTML element helpers |
| `Hydrogen.Render.Element.SVG` | SVG element helpers |
| `Hydrogen.Render.Element.Events` | Event handlers |
| `Hydrogen.Target.DOM` | Direct DOM rendering |
| `Hydrogen.Runtime.App` | App shell (init/update/view) |

### Needed for Canvas Compound Integration

| Module | Purpose |
|--------|---------|
| `Hydrogen.Element.Compound.Canvas` | Infinite canvas compound |
| `Hydrogen.Element.Compound.Canvas.State` | Canvas state management |
| `Hydrogen.Element.Compound.Canvas.Render` | Canvas rendering |
| `Hydrogen.Element.Compound.ColorPicker` | Color selection |
| `Hydrogen.Element.Compound.Slider` | Property sliders |
| `Hydrogen.Element.Compound.Button` | Tool buttons |
| `Hydrogen.Element.Compound.Confetti` | Easter egg particles |

### Needed for Gestures

| Module | Purpose |
|--------|---------|
| `Hydrogen.Motion.Gesture` | Pan, Pinch, Rotate, Swipe, LongPress |
| `Hydrogen.Motion.Spring` | Spring physics animation |
| `Hydrogen.Motion.Transition` | State transitions |

---

## PHASE 1: CRITICAL PATH (Week 1)

### 1.1 Verify Build
- [ ] Run `spago build` in canvas directory
- [ ] Verify hydrogen dependency resolves via `path: ../hydrogen`
- [ ] Fix any import errors

### 1.2 Complete View Layer (`Canvas/View.purs`)
- [ ] Import Hydrogen.Render.Element
- [ ] Define `Msg` ADT for all user actions
- [ ] Implement `view :: AppState -> Element Msg`
- [ ] Render canvas surface (SVG or Canvas2D)
- [ ] Render particles as circles
- [ ] Render toolbar (tool buttons)
- [ ] Render layer panel
- [ ] Wire event handlers (onClick, onMouseDown, onMouseMove, onMouseUp)

### 1.3 Complete Main Entry (`Main.purs`)
- [ ] Import Hydrogen.Runtime.App
- [ ] Import Hydrogen.Target.DOM
- [ ] Define `App AppState Msg (Element Msg)`
- [ ] Implement init (create initial state)
- [ ] Implement update (handle all Msg cases)
- [ ] Implement subscriptions (OnAnimationFrame for simulation)
- [ ] Wire device orientation API (FFI)
- [ ] Mount app to DOM

### 1.4 Device Orientation FFI
- [ ] Create `Canvas/FFI/DeviceOrientation.purs`
- [ ] Create `Canvas/FFI/DeviceOrientation.js`
- [ ] Bind `window.DeviceOrientationEvent`
- [ ] Handle permission request (iOS 13+)
- [ ] Convert to DeviceOrientation type

### 1.5 Animation Loop
- [ ] Request animation frame subscription
- [ ] Calculate delta time
- [ ] Call `simulatePaint` on each frame
- [ ] Update gravity from device orientation
- [ ] Render updated state

---

## PHASE 2: EXPERIENCE (Week 2)

### 2.1 Gesture Recognition
- [ ] Integrate Hydrogen.Motion.Gesture
- [ ] Add pan gesture for canvas navigation
- [ ] Add pinch gesture for zoom
- [ ] Add rotate gesture for canvas rotation
- [ ] Add swipe gesture for tool shortcuts

### 2.2 Touch/Stylus Input
- [ ] Handle pointer events for drawing
- [ ] Extract pressure from PointerEvent (stylus)
- [ ] Extract tilt from PointerEvent (stylus)
- [ ] Convert pointer position to canvas coordinates
- [ ] Add particles along stroke path

### 2.3 Haptic Feedback FFI
- [ ] Create `Canvas/FFI/Haptic.purs`
- [ ] Create `Canvas/FFI/Haptic.js`
- [ ] Bind `navigator.vibrate` (Web)
- [ ] Implement haptic patterns for brush feedback

### 2.4 Layer Panel UI
- [ ] Create `Canvas/UI/LayerPanel.purs`
- [ ] Render layer stack
- [ ] Layer visibility toggle
- [ ] Layer lock toggle
- [ ] Layer opacity slider
- [ ] Layer blend mode selector
- [ ] Drag to reorder layers

### 2.5 Properties Panel UI
- [ ] Create `Canvas/UI/PropertiesPanel.purs`
- [ ] Brush size slider
- [ ] Brush opacity slider
- [ ] Color picker (use Hydrogen.Element.Compound.ColorPicker)
- [ ] Paint preset selector

### 2.6 Toolbar UI
- [ ] Create `Canvas/UI/Toolbar.purs`
- [ ] Tool buttons with icons
- [ ] Current tool indicator
- [ ] Keyboard shortcuts display

---

## PHASE 3: DELIGHT (Week 3)

### 3.1 Easter Egg: Konami Code
- [ ] Create `Canvas/Easter/KonamiCode.purs`
- [ ] Track key sequence: ↑↑↓↓←→←→BA
- [ ] Trigger confetti explosion on success
- [ ] Play celebration sound

### 3.2 Easter Egg: Shake to Clear
- [ ] Create `Canvas/Easter/ShakeDetector.purs`
- [ ] Detect device shake via accelerometer
- [ ] Animate etch-a-sketch clear effect
- [ ] Reset canvas with satisfying animation

### 3.3 Confetti System
- [ ] Integrate Hydrogen.Element.Compound.Confetti
- [ ] Configure particle colors, count, physics
- [ ] Wire to easter egg triggers

### 3.4 Screen Effects
- [ ] Screen shake on heavy brush stroke
- [ ] Screen flash on layer merge
- [ ] Subtle glow on selection

### 3.5 Audio Visualizer (Optional)
- [ ] Create `Canvas/Audio/Visualizer.purs`
- [ ] Bind Web Audio API
- [ ] Render waveform/spectrum
- [ ] Sync paint particles to music

### 3.6 Debug Overlay
- [ ] Create `Canvas/Debug/Overlay.purs`
- [ ] Show FPS counter
- [ ] Show particle count
- [ ] Show gravity vector
- [ ] Show memory usage
- [ ] Show render regions
- [ ] Toggle with keyboard shortcut

---

## PHASE 4: POLISH (Week 4)

### 4.1 Undo/Redo Enhancement
- [ ] Compress history entries
- [ ] Add undo keyboard shortcut (Ctrl+Z)
- [ ] Add redo keyboard shortcut (Ctrl+Shift+Z)
- [ ] Visual undo stack indicator

### 4.2 Performance Optimization
- [ ] Spatial hashing for particle neighbors
- [ ] Dirty region tracking
- [ ] Layer caching (static layers to texture)
- [ ] Frame budgeting (skip low-priority particles)

### 4.3 WebGL Renderer (Optional)
- [ ] Create `Canvas/Render/WebGL.purs`
- [ ] Particle point sprites
- [ ] Layer compositing via framebuffers
- [ ] GPU-accelerated blur/effects

### 4.4 3D Layer Support (Optional)
- [ ] Integrate Hydrogen.GPU.Scene3D
- [ ] Add camera to canvas
- [ ] Add lights to canvas
- [ ] Render 3D objects in layers

### 4.5 Accessibility
- [ ] ARIA labels on all interactive elements
- [ ] Keyboard navigation
- [ ] Screen reader announcements
- [ ] High contrast mode
- [ ] Reduced motion mode

### 4.6 Export
- [ ] Export to PNG
- [ ] Export to SVG
- [ ] Export animation to GIF
- [ ] Export animation to MP4

---

## FILE STRUCTURE (TARGET)

```
canvas/
├── spago.yaml
├── flake.nix
├── CLAUDE.md
├── docs/
│   ├── MASTER_TODO.md          # This file
│   ├── MASTER_SPEC.md
│   ├── CHECKLIST.md
│   └── CANVAS_BUILDER_COUNCIL.md
├── src/
│   ├── Main.purs               # App entry point
│   ├── Canvas.purs             # Module re-exports
│   └── Canvas/
│       ├── Types.purs          # ✅ Core types
│       ├── State.purs          # ✅ App state
│       ├── View.purs           # 🔄 Main view
│       ├── Update.purs         # Message handling
│       ├── Layer/
│       │   ├── Types.purs      # ✅ Layer types
│       │   ├── Render.purs     # Layer rendering
│       │   └── Composite.purs  # Layer compositing
│       ├── Paint/
│       │   ├── Particle.purs   # ✅ SPH particles
│       │   ├── Stroke.purs     # Stroke recording
│       │   ├── Brush.purs      # Brush configuration
│       │   └── Drying.purs     # Drying simulation
│       ├── Physics/
│       │   ├── Gravity.purs    # ✅ Device orientation
│       │   ├── Simulation.purs # SPH step wrapper
│       │   └── Bounds.purs     # Boundary handling
│       ├── Effect/
│       │   └── Graded.purs     # 🔄 Canvas effects
│       ├── UI/
│       │   ├── Toolbar.purs    # Tool palette
│       │   ├── LayerPanel.purs # Layer stack
│       │   ├── PropertiesPanel.purs
│       │   ├── ColorPanel.purs
│       │   ├── BrushPanel.purs
│       │   └── Timeline.purs   # Animation timeline
│       ├── Tool/
│       │   ├── Types.purs      # Tool ADT
│       │   ├── Brush.purs      # Brush tool
│       │   ├── Eraser.purs     # Eraser tool
│       │   ├── Eyedropper.purs # Color picker tool
│       │   ├── Pan.purs        # Hand/pan tool
│       │   └── Selection.purs  # Selection tool
│       ├── FFI/
│       │   ├── DeviceOrientation.purs
│       │   ├── DeviceOrientation.js
│       │   ├── Haptic.purs
│       │   └── Haptic.js
│       ├── Easter/
│       │   ├── KonamiCode.purs
│       │   ├── ShakeDetector.purs
│       │   └── Rewards.purs
│       ├── Debug/
│       │   └── Overlay.purs
│       └── Render/
│           ├── Canvas2D.purs   # Canvas2D target
│           ├── WebGL.purs      # WebGL target (optional)
│           └── Particle.purs   # Particle rendering
└── test/
    └── Test/
        └── Main.purs
```

---

## VERIFICATION CHECKLIST

Before each commit, verify:

- [ ] `spago build` passes with no errors
- [ ] No `TODO`, `FIXME`, or stub comments
- [ ] No `undefined`, `unsafePartial`, `unsafeCoerce`
- [ ] All imports are explicit (no `(..)`)
- [ ] File is under 500 lines
- [ ] Module documentation is complete
- [ ] Functions have type signatures

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

## NOTES

- **Hydrogen dependency**: Canvas depends on `../hydrogen` via spago.yaml
- **No FFI in pure logic**: FFI only at boundaries (DeviceOrientation, Haptic, DOM)
- **Incremental edits**: Create headers first, then add functionality
- **Read before write**: Always read existing files before editing

---

*"Everyone."* — Norman Stansfield

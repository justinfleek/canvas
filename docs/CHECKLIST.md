# CANVAS VERIFICATION CHECKLIST

**Status**: Proof of concept that PureScript Hydrogen works with straylight-web

---

## CURRENT AUDIT STATE

```
CURRENT FILE: [NOT SET] — Set file path before each audit cycle
```

---

## CHECKLIST

[ ] **DEPENDENCIES**: Trace all imports, verify each dependency exists and is complete
[ ] **BOUNDS**: Every atom has min/max defined, behavior (clamp/wrap/finite) specified
[ ] **SCALING**: Bounded transforms that CLAMP not multiply — no exponential compounding
[ ] **TRIGGERS**: All input events defined (keyboard, mouse, gestural, haptic)
[ ] **UI ELEMENTS**: Components needed to display this to a human are defined
[ ] **DEBUG FLAGS**: 2D and 3D debug visualization modes defined
[ ] **SYSTEM F OMEGA**: Higher-kinded types, type operators correct
[ ] **MOLECULE/COMPOUND**: Classification clear, notated in SCHEMA.md
[ ] **ELEVATION**: Z-layering relationships to other elements defined
[ ] **UUID5**: Deterministic identity from content, namespace correct
[ ] **AST EDITS**: All transformations preserve structure, edits traceable
[ ] **GRADED MONADS**: Category/set identified for dependency chain filtering
[ ] **FPGA**: Hardware synthesis requirements identified if applicable
[ ] **WASM**: Clean translation path, no JS jank
[ ] **HASKELL BACKEND**: Compatible as pure data accepted by Haskell
[ ] **PURE MATH**: Verifiable pure functions, no side effects in core logic
[ ] **LOAD TIME**: Performance characteristics documented
[ ] **PRESBURGER/ILP**: Integer linear programming applied where needed
[ ] **ZMQ4**: Message passing patterns correct if applicable
[ ] **TEST SUITE**: Unit, property, security, browser, integration, e2e, hyperconsole
[ ] **GESTURAL EVENTS**: Mouse, keyboard, gestural events defined for each atom
[ ] **SYSTEM ARCHITECTURE**: Full tracing, ADT graphs, Lean4 mappings, optimizations
[ ] **SYSTEM GRAPH**: Mermaid chart, atom→molecule→compound paths clear
[ ] **COMPOSITING**: Layer behavior, matte/map requirements, obscure under
[ ] **WORLD MODEL**: Can render ANYTHING on screen at ANY time with bounds
[ ] **LEAN4**: Maps to proof, invariants documented
[ ] **IMMEDIATE UPDATES**: List ALL files that must be updated NOW
[ ] **INDUSTRY STANDARD**: What would a HUMAN professional expect?
[ ] **ACCURATE GESTURAL MAPPING**: UI entries for all properties, slow flag tweakable
[ ] **ACCURATE Z-INDEXING**: Noise/diffusion layers clip properly, no bleed
[ ] **CACHING**: WebGL/WASM/WebGPU caching for full trajectory motion
[ ] **TRIGGERS END**: No constant looping, no compounding, no time dilation
[ ] **NO JAVASCRIPT**: ZERO FFIs. All FFIs replaced with proper PureScript
[ ] **COHESION**: Effects not siloed, symbols consistent, show_debug_convention
[ ] **PROPER SYMBOLS**: Billion agents at 1000 tok/s — widen roads, keep options
[ ] **FULL FEATURES**: Can recreate Amazon to Youtube from basic primitives

---

## CANVAS-SPECIFIC ITEMS

[ ] **INFINITE CANVAS**: Pan/zoom works at any scale without precision loss
[ ] **LAYER SYSTEM**: Professional motion graphics-style layer stack
[ ] **BACKGROUND LAYER**: Device-aware bounds, material, haptic surface
[ ] **ADD ELEMENT DROPDOWN**: Every primitive accessible via right-click
[ ] **PROPERTIES PANEL**: Per-selection inspector with all properties
[ ] **TIMELINE**: Horizontal keyframe editor with playhead
[ ] **EASTER EGGS**: Konami code, shake detection, rewards system
[ ] **DEBUG OVERLAY**: Hit areas, z-index, render regions, gesture state, perf

---

## FILE AUDIT LOG

| File | Status | Last Audited | Notes |
|------|--------|--------------|-------|
| src/Main.purs | STUB | 2026-03-03 | Entry point only, needs full implementation |
| src/Canvas/Types.purs | COMPLETE | 2026-03-03 | 665 lines, all core types |
| src/Canvas/View.purs | STUB | 2026-03-03 | 4 lines, empty placeholder |
| src/Canvas/State.purs | COMPLETE | 2026-03-03 | 507 lines, full state management |
| src/Canvas/Layer/Types.purs | COMPLETE | 2026-03-03 | 555 lines, layer system |
| src/Canvas/Paint/Particle.purs | COMPLETE | 2026-03-03 | 664 lines, SPH physics |
| src/Canvas/Effect/Graded.purs | PARTIAL | 2026-03-03 | 170 lines, types only |
| src/Canvas/Physics/Gravity.purs | COMPLETE | 2026-03-03 | 379 lines, device orientation |

---

## HYDROGEN DEPENDENCY VERIFICATION

| Module | Required By | Verified |
|--------|-------------|----------|
| Hydrogen.Schema.Physics.Fluid.Particle | Particle.purs | ✅ EXISTS |
| Hydrogen.Schema.Physics.Fluid.Solver | Particle.purs | ✅ EXISTS |
| Hydrogen.Schema.Brush.WetMedia | Particle.purs | ✅ EXISTS |
| Hydrogen.Schema.Brush.WetMedia.Atoms | Particle.purs, Gravity.purs | ✅ EXISTS |
| Hydrogen.Schema.Brush.WetMedia.Dynamics | Particle.purs, Gravity.purs | ✅ EXISTS |
| Hydrogen.Schema.Canvas.Physics | Gravity.purs | ✅ EXISTS |
| Hydrogen.Effect.Grade | Graded.purs | ✅ EXISTS |
| Hydrogen.Effect.Graded | Graded.purs | ✅ EXISTS |
| Hydrogen.Render.Element | View.purs (needed) | ✅ EXISTS |
| Hydrogen.Target.DOM | Main.purs (needed) | ✅ EXISTS |
| Hydrogen.Runtime.App | Main.purs (needed) | ✅ EXISTS |
| Hydrogen.Motion.Gesture | (needed) | ✅ EXISTS |
| Hydrogen.Element.Compound.Canvas | (integration) | ✅ EXISTS |

---

## LEAN4 PROOFS APPLICABLE TO CANVAS

| Proof | File | Relevance |
|-------|------|-----------|
| vortex_force_orthogonal | Math/Force.lean | Paint swirl physics |
| verlet_time_reversible | Math/Integration.lean | Particle simulation |
| cross_perp_left/right | Math/Vec3.lean | 3D layer transforms |
| normalize_length = 1 | Math/Vec3.lean | Direction vectors |
| fresnelSchlick_le_one | Material/BRDF.lean | Material rendering |


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                                                         // CANVAS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CANVAS - Universal Canvas Builder
# PureScript Hydrogen | Haskell Backend | Lean4 Proofs

## PROJECT VISION

Canvas = Device Display. A universal rendering surface where:

1. **Same brand schema** renders correctly on phone, tablet, desktop, TV, billboard
2. **Every visual element** is a composable layer with full professional-level controls
3. **Steady state = cheap** (static gradients, text don't burn GPU)
4. **Dynamic regions = smart** (only animated pixels get computed)
5. **Interactions are SICK** (shake to etch-a-sketch, particle explosions, etc.)

---

## ABSOLUTE RULE #0: NEVER DISABLE WARNINGS

**DISABLING WARNINGS IS FORBIDDEN. NO EXCEPTIONS. EVER.**

## ABSOLUTE RULE #1: NEVER DELETE CODE TO FIX WARNINGS

**DELETING "UNUSED" CODE IS FORBIDDEN. NO EXCEPTIONS. EVER.**

"Unused" code exists for a reason. It was written with intent. When you see an
"unused import" or "unused variable" warning:

1. **The code is INCOMPLETE** - Someone started work that wasn't finished
2. **The import IS needed** - Find WHERE it should be used and IMPLEMENT it
3. **Deleting is LAZY** - It hides incompleteness instead of completing work

---

## PROJECT STRUCTURE

```
canvas/
├── CLAUDE.md                    # This file - AI assistant instructions
├── .gitignore                   # Ignores IMPLEMENTATION/ folder
├── docs/                        # Planning and architecture documents
│   └── CANVAS_BUILDER_COUNCIL.md  # Complete architecture spec (733 lines)
│
├── IMPLEMENTATION/              # Reference repos (NEVER PUSHED)
│   ├── hydrogen/               # PureScript UI framework - OUTDATED CLONE
│   │                           # USE ../hydrogen/ INSTEAD (sibling dir)
│   ├── libevring/              # Verified event ring infrastructure
│   ├── straylight-llm/         # LLM gateway with discharge proofs
│   ├── weapon-server-hs/       # Haskell agent server
│   ├── weapon-cli/             # TypeScript CLI
│   ├── weapon/                 # TypeScript weapon core
│   ├── strayforge/             # Haskell tooling
│   ├── haskemathesis/          # Property testing for APIs
│   ├── hyperconsole/           # Diff-based terminal TUI
│   ├── straylight-web/         # PureScript web components
│   ├── straylight/             # C++ monorepo
│   ├── sigil-trtllm/           # TensorRT-LLM integration
│   ├── sensenet/               # Starlark config
│   ├── nix/                    # Nix package manager fork
│   ├── nix-compile/            # Nix compilation tools
│   ├── hs-blake3/              # BLAKE3 Haskell bindings
│   ├── converge/               # Haskell convergence tools
│   ├── aleph/                  # Haskell tooling
│   ├── modern/                 # Modern Nix Haskell tooling
│   ├── veves/                  # Haskell utilities
│   └── .github/                # GitHub org config
│
└── src/                        # Canvas implementation (TO BE BUILT)
    ├── purescript/             # PureScript/Hydrogen UI
    └── haskell/                # Haskell backend
```

---

## KEY REFERENCE DOCUMENTS

### Primary Planning Doc
- `docs/CANVAS_BUILDER_COUNCIL.md` - Complete 733-line architecture spec including:
  - Schema inventory (550+ files across 16 pillars)
  - Element system (170+ files)
  - Adversarial failure analysis (10 attacks)
  - Gap analysis (Critical, High, Medium, Low priority)
  - Complete specs for Background Layer, Layer System, Add Element Dropdown,
    Event Handlers, Easter Eggs, Debug Overlay
  - 4-week implementation roadmap

### Key Implementation References
- `../hydrogen/` - **PRIMARY** - The real Hydrogen (1,467 PureScript + 110 Lean4 proofs)
- `IMPLEMENTATION/` - Reference repos (cloned, read-only, for patterns)

---

## IMPLEMENTATION PHASES (from Council doc)

### PHASE 1: CRITICAL PATH (Week 1)
- [ ] Image Element — Add Image variant to Element.Core
- [ ] Audit WebGL renderer — Verify Target.WebGL exists and works
- [ ] Gesture attributes — Add onPinch/onSwipe/onLongPress to Render.Element
- [ ] Effects in Flatten — Apply blur/glow during flattening
- [ ] Responsive resolver — Viewport → Brand → computed values

**NOTE**: Much of this already exists in ../hydrogen/:
- Canvas compound with full state management (undo/redo, viewport, selection)
- Gesture system (Pan, Pinch, Rotate, Swipe, LongPress) in Motion/Gesture.purs
- 92 UI compounds in Element/Compound/

### PHASE 2: EXPERIENCE (Week 2)
- [ ] Haptic FFI — Implement navigator.vibrate binding
- [ ] Device motion FFI — Implement DeviceMotionEvent binding
- [ ] Layer panel compound — Motion/Layer/LayerPanel.purs
- [ ] Properties panel — Motion/Panel/Properties.purs
- [ ] Dirty region tracking — Optimize render pipeline

### PHASE 3: DELIGHT (Week 3)
- [ ] Easter egg runtime — KeySequence + ShakeDetector + Rewards
- [ ] Confetti compound — Particle explosion effect
- [ ] Screen effects — Shake, flash, glitch implementations
- [ ] Audio visualizer — Waveform/spectrum compound
- [ ] Debug overlay — Full diagnostic panel

### PHASE 4: POLISH (Week 4)
- [ ] Undo/redo — Canvas.State history management
- [ ] 3D layer support — Camera/light in canvas
- [ ] Accessibility audit — ARIA compliance check
- [ ] Performance profiler — Detailed timing breakdown
- [ ] Documentation — Complete API docs

---

## STRAYLIGHT STANDARDS

### Language Stack
- **Lean4 4.26+** - Calculus of Inductive Constructions, invariants defined FIRST
- **Haskell** - Backend, GHC 9.12, StrictData everywhere
- **PureScript Hydrogen** - Frontend framework, pure functional UI

### Code Quality (NON-NEGOTIABLE)
- **ZERO stubs or TODOs** - If you write code, it must be COMPLETE
- **ZERO dummy code** - No placeholders, no "implement later"
- **ZERO escapes** - No unsafePerformIO, unsafeCoerce, undefined, error
- **500 lines maximum per file** - Split into modules if needed
- **Explicit imports on EVERYTHING** - No `(..)` patterns

### Forbidden Patterns
```
❌ undefined        ❌ error "msg"      ❌ throw e
❌ head             ❌ tail             ❌ !! index
❌ fromJust         ❌ unsafePerformIO  ❌ unsafeCoerce
❌ trace/traceShow  ❌ Debug.Trace.*
```

---

## BUILD COMMANDS

```bash
# Enter canvas directory
cd /home/justin/jpyxal/canvas

# Reference implementations are in IMPLEMENTATION/
# They are cloned repos, NEVER modify them directly
# Use them as reference for patterns and APIs

# When building canvas itself:
# PureScript
cd src/purescript && spago build

# Haskell
cd src/haskell && cabal build all
```

---

## AI ASSISTANT RULES

### Hard Rules - NEVER VIOLATE

1. **Trace errors to root cause** - Never delete to fix
2. **ADD functionality, don't remove** - Swiss cheese holes mean incomplete work
3. **Ask before deletion** - 0.00001% chance code doesn't belong
4. **Read ENTIRE file before editing** - No partial reads
5. **One file at a time** - Read, edit, rebuild, verify, then move on
6. **IMPLEMENTATION/ is READ-ONLY** - Never modify reference repos

### Reference Usage

The IMPLEMENTATION/ folder contains production code from straylight-software.
Use these as **reference only**:

1. **Pattern extraction** - See how things are done in production
2. **API discovery** - Find existing functions/types to use
3. **Architecture guidance** - Understand system design
4. **DO NOT COPY WHOLESALE** - Understand and adapt patterns

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                                                // canvas // claude
                                                              // straylight/2026
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                                      // canvas
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas — Module re-exports for the paint application.
-- |
-- | ## Overview
-- |
-- | Canvas is a professional digital art application with physics-simulated paint.
-- | When you tilt your phone, paint flows realistically using SPH fluid dynamics.
-- |
-- | ## Module Structure
-- |
-- | ```
-- | Canvas
-- | ├── Types          Core types (LayerId, Tool, Bounds, Color, etc.)
-- | ├── State          Application state management
-- | ├── View           Pure view rendering
-- | ├── Layer/
-- | │   ├── Types      Layer and LayerStack types
-- | │   ├── Render     Layer rendering to elements
-- | │   └── Composite  Layer compositing with blend modes
-- | ├── Paint/
-- | │   ├── Particle   SPH paint particle system
-- | │   ├── Stroke     Brush stroke recording
-- | │   ├── Brush      Brush configuration
-- | │   └── Drying     Paint drying simulation
-- | ├── Physics/
-- | │   ├── Gravity    Device orientation → gravity
-- | │   ├── Simulation SPH simulation wrapper
-- | │   └── Bounds     Boundary handling
-- | └── Effect/
-- |     └── Graded     Effect tracking for canvas operations
-- | ```
-- |
-- | ## Quick Start
-- |
-- | ```purescript
-- | import Canvas (initialAppState, Tool(..), addPaintParticle)
-- |
-- | -- Create initial state
-- | state = initialAppState
-- |
-- | -- Add a paint particle
-- | state' = addPaintParticle 100.0 200.0 state
-- | ```

module Canvas
  ( -- * Re-exports: Types
    module Canvas.Types
    
  -- * Re-exports: State
  , module Canvas.State
  
  -- * Re-exports: View
  , module Canvas.View
  
  -- * Re-exports: Layer
  , module Canvas.Layer.Types
  , module Canvas.Layer.Render
  , module Canvas.Layer.Composite
  
  -- * Re-exports: Paint
  , module Canvas.Paint.Particle
  , module Canvas.Paint.Stroke
  , module Canvas.Paint.Brush
  , module Canvas.Paint.Drying
  
  -- * Re-exports: Physics
  , module Canvas.Physics.Gravity
  , module Canvas.Physics.Simulation
  , module Canvas.Physics.Bounds
  
  -- * Re-exports: Effects
  , module Canvas.Effect.Graded
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

-- Core Types
import Canvas.Types
  ( LayerId
  , mkLayerId
  , unwrapLayerId
  , defaultLayerId
  , backgroundLayerId
  , StrokeId
  , mkStrokeId
  , ParticleId
  , mkParticleId
  , Tool(BrushTool, EraserTool, EyedropperTool, PanTool, ZoomTool, SelectionTool, FillTool)
  , allTools
  , toolName
  , toolShortcut
  , isPaintingTool
  , Point2D
  , mkPoint2D
  , Vec2D
  , mkVec2D
  , vecZero
  , vecAdd
  , vecSub
  , vecScale
  , vecMagnitude
  , vecNormalize
  , Bounds
  , mkBounds
  , boundsContains
  , boundsIntersects
  , ZIndex
  , mkZIndex
  , Color
  , mkColor
  , colorBlack
  , colorWhite
  , BlendMode(BlendNormal, BlendMultiply, BlendScreen, BlendOverlay)
  , allBlendModes
  )

-- State Management
import Canvas.State
  ( AppState
  , mkAppState
  , initialAppState
  , BrushConfig
  , mkBrushConfig
  , defaultBrushConfig
  , currentTool
  , paintSystem
  , gravityState
  , layerStack
  , brushConfig
  , activeLayerId
  , isPlaying
  , setTool
  , setBrushSize
  , setBrushOpacity
  , setBrushColor
  , addPaintParticle
  , clearActiveLayer
  , simulatePaint
  , updateGravity
  , setGravityEnabled
  , addLayer
  , removeLayer
  , layerCount
  , canUndo
  , canRedo
  , undo
  , redo
  , pushHistory
  )

-- View
import Canvas.View
  ( view
  , Msg
      ( ToolSelected
      , BrushPresetSelected
      , MediaTypeSelected
      , ColorChanged
      , CanvasTouched
      , CanvasMoved
      , CanvasReleased
      , OrientationChanged
      , ToggleGravity
      , TogglePlaying
      , ClearCanvas
      , Undo
      , Redo
      , Tick
      , LayerSelected
      , AddLayer
      )
  , renderToolbar
  , renderCanvas
  , renderStatusBar
  )

-- Layer Types
import Canvas.Layer.Types
  ( Layer
  , mkLayer
  , layerId
  , layerName
  , layerZIndex
  , layerVisible
  , layerLocked
  , layerOpacity
  , layerBlendMode
  , LayerStack
  , mkLayerStack
  , emptyLayerStack
  , sortedLayers
  , Background
  , BackgroundType(SolidBackground, GradientBackground, TextureBackground, TransparentBackground)
  , mkBackground
  , defaultBackground
  )

-- Layer Rendering
import Canvas.Layer.Render
  ( renderLayer
  , renderLayerContent
  , renderLayerBackground
  , renderLayerParticles
  , DirtyRegion
  , mkDirtyRegion
  , isDirty
  , markDirty
  , clearDirty
  , LayerCache
  , mkLayerCache
  , isCached
  , invalidateCache
  )

-- Layer Compositing
import Canvas.Layer.Composite
  ( compositeLayer
  , compositeLayers
  , compositeAll
  , blendPixel
  , blendNormal
  , blendMultiply
  , blendScreen
  , alphaComposite
  , CompositeResult
  , mkCompositeResult
  , applyClipMask
  , LayerGroup
  , mkLayerGroup
  )

-- Paint Particles
import Canvas.Paint.Particle
  ( PaintParticle
  , Particle
  , mkPaintParticle
  , particlePosition
  , particleVelocity
  , particleColor
  , particleColorHex
  , particleWetness
  , particleViscosity
  , particleRadius
  , PaintSystem
  , mkPaintSystem
  , emptyPaintSystem
  , allParticles
  , addParticle
  , clearParticles
  , particleCount
  , PaintPreset(Watercolor, OilPaint, Acrylic, Gouache, Ink, Honey)
  , allPaintPresets
  , presetName
  , simulateStep
  , applyGravity
  , applyDrying
  , systemEnergy
  )

-- Stroke Recording
import Canvas.Paint.Stroke
  ( StrokePoint
  , mkStrokePoint
  , pointX
  , pointY
  , pointPressure
  , Stroke
  , mkStroke
  , emptyStroke
  , strokeId
  , strokeLayerId
  , strokeColor
  , strokePoints
  , strokeBounds
  , beginStroke
  , addPoint
  , endStroke
  , isStrokeActive
  , strokeLength
  , strokeAveragePressure
  , generateParticlePositions
  )

-- Brush Configuration
import Canvas.Paint.Brush
  ( BrushShape(RoundBrush, FlatBrush, FanBrush, KnifeBrush, AirBrush)
  , allBrushShapes
  , shapeName
  , DynamicSource(ConstantSource, PressureSource, TiltXSource, SpeedSource)
  , DynamicCurve
  , mkDynamicCurve
  , constantCurve
  , linearPressureCurve
  , evaluateDynamic
  , defaultBrush
  , watercolorBrush
  , oilBrush
  , inkBrush
  , airbrush
  , computeSize
  , computeOpacity
  )

-- Drying Simulation
import Canvas.Paint.Drying
  ( DryingState(FullyWet, Tacky, TouchDry, FullyCured)
  , getDryingState
  , DryingConfig
  , mkDryingConfig
  , defaultDryingConfig
  , fastDryingConfig
  , slowDryingConfig
  , simulateDrying
  , computeNewWetness
  , timeToDry
  , EnvironmentFactors
  , mkEnvironmentFactors
  , defaultEnvironment
  , isParticleDried
  , isParticleWet
  , computeGranulation
  )

-- Gravity / Device Orientation
import Canvas.Physics.Gravity
  ( GravityState
  , mkGravityState
  , initialGravityState
  , gravityEnabled
  , gravityScale
  , currentGravity
  , currentOrientation
  , updateFromOrientation
  , updateFromAccelerometer
  , getGravity2D
  , getGravityMagnitude
  , isGravityActive
  , isDeviceFlat
  , calculatePaintFlow
  , shouldPaintFlow
  , gravityStatePortrait
  , gravityStateFlat
  )

-- SPH Simulation
import Canvas.Physics.Simulation
  ( SimulationConfig
  , mkSimulationConfig
  , defaultSimConfig
  , highQualitySimConfig
  , fastSimConfig
  , SimulationState
  , mkSimulationState
  , emptySimState
  , simParticleCount
  , simEnergy
  , step
  , stepN
  , stepWithConfig
  , computeAllForces
  , SpatialHash
  , buildSpatialHash
  , findNeighbors
  , totalKineticEnergy
  , maxParticleSpeed
  )

-- Boundary Handling
import Canvas.Physics.Bounds
  ( BoundaryType(HardReflect, SoftRepel, StickyAbsorb, Wraparound, Open)
  , BoundaryConfig
  , mkBoundaryConfig
  , defaultBoundaryConfig
  , stickyBoundaryConfig
  , EdgeConfig
  , mkEdgeConfig
  , uniformEdges
  , enforceBoundary
  , enforceWithConfig
  , isOutOfBounds
  , distanceToBoundary
  , closestEdge
  , Edge(Top, Bottom, Left, Right)
  , computeBoundaryForce
  , clampToViewport
  , wrapAroundViewport
  )

-- Graded Effects
import Canvas.Effect.Graded
  ( Sensor
  , GPU
  , Timer
  , Haptic
  , CanvasPure
  , SensorOnly
  , GPUOnly
  , RenderGrade
  , FullCanvas
  , CanvasCoEffect
  , emptyCanvasCoEffect
  , SensorAccess
  , GPUAccess
  , HapticAccess
  )

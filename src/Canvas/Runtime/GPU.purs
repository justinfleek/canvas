-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                    // canvas // runtime // gpu
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | GPU Runtime for Canvas Paint Application
-- |
-- | This module provides GPU-accelerated rendering for paint particles.
-- | It uses Hydrogen's GPU target with automatic fallback:
-- |
-- | ```
-- | WebGPU (100K+ particles)
-- |    ↓ fallback
-- | WebGL2 (10K+ particles)
-- |    ↓ fallback
-- | Canvas2D (1K particles)
-- | ```
-- |
-- | ## Architecture
-- |
-- | The Canvas app uses a hybrid rendering approach:
-- | - **UI elements**: Rendered via Halogen (buttons, panels, etc.)
-- | - **Paint particles**: Rendered via GPU (this module)
-- |
-- | The main canvas area uses a `<canvas>` element that we render
-- | particles to using DrawCommands.
-- |
-- | ## Usage
-- |
-- | ```purescript
-- | import Canvas.Runtime.GPU as GPU
-- |
-- | main :: Effect Unit
-- | main = do
-- |   GPU.initialize "paint-canvas" >>= case _ of
-- |     Left err -> Console.log $ "GPU init failed: " <> err
-- |     Right runtime -> do
-- |       -- In animation loop:
-- |       GPU.renderParticles runtime particles
-- | ```

module Canvas.Runtime.GPU
  ( -- * Runtime
    GPURuntime
  , initialize
  , dispose
  
  -- * Rendering
  , renderParticles
  , renderFrame
  , renderScene3D
  , clear
  
  -- * Info
  , getBackendName
  , getGPUInfo
  , getParticleCount
  
  -- * Particle conversion
  , particlesToCommands
  ) where

import Prelude
  ( Unit
  , Void
  , bind
  , discard
  , map
  , pure
  , ($)
  , (*)
  , (-)
  , (<)
  , (<>)
  )

import Data.Array (length) as Array
import Data.Either (Either(Left, Right))
import Data.Int (floor) as Int
import Data.Maybe (Maybe(Nothing))
import Effect (Effect)
import Effect.Class.Console as Console

import Hydrogen.Target.GPU as GPU
import Hydrogen.GPU.DrawCommand.Types
  ( DrawCommand(DrawParticle, DrawScene3D)
  , ParticleParams
  , PickId
  )
import Hydrogen.GPU.Coordinates as Coord
import Hydrogen.GPU.Coordinates (depthValue)
import Hydrogen.Schema.Color.RGB as RGB
import Hydrogen.Schema.Dimension.Device as Device

import Canvas.Paint.Particle as Paint
import Canvas.Types as Types
import Canvas.Layer.Layer3D as Layer3D

-- ═══════════════════════════════════════════════════════════════════════════
--                                                                // runtime
-- ═══════════════════════════════════════════════════════════════════════════

-- | GPU runtime state.
type GPURuntime =
  { renderer :: GPU.Renderer
  , canvasId :: String
  , backend :: GPU.Backend
  }

-- | Initialize GPU runtime for the given canvas element.
-- |
-- | Automatically selects the best available backend.
-- | Returns Left with error message if initialization fails.
initialize :: String -> Effect (Either String GPURuntime)
initialize canvasId = do
  Console.log $ "Initializing GPU runtime for canvas: " <> canvasId
  
  -- Detect capabilities first
  caps <- GPU.detectCapabilities
  Console.log $ "GPU Capabilities:"
  Console.log $ "  WebGPU: " <> show caps.webgpu
  Console.log $ "  WebGL2: " <> show caps.webgl2
  Console.log $ "  Canvas2D: " <> show caps.canvas2d
  Console.log $ "  Best backend: " <> backendToString caps.bestBackend
  
  -- Create renderer
  result <- GPU.createRenderer canvasId
  case result of
    Left err -> do
      Console.log $ "GPU initialization failed: " <> err
      pure $ Left err
    Right renderer -> do
      let backend = GPU.getBackend renderer
      Console.log $ "Using backend: " <> backendToString backend
      pure $ Right { renderer, canvasId, backend }

-- | Dispose GPU runtime and release resources.
dispose :: GPURuntime -> Effect Unit
dispose runtime = GPU.dispose runtime.renderer

-- ═══════════════════════════════════════════════════════════════════════════
--                                                              // rendering
-- ═══════════════════════════════════════════════════════════════════════════

-- | Render paint particles to the canvas.
-- |
-- | This is the main render function called each frame.
-- | Converts particles to DrawCommands and renders via GPU.
-- |
-- | Note: Particles don't have click handlers, so we use Void as the msg type.
renderParticles :: GPURuntime -> Array Paint.Particle -> Effect Unit
renderParticles runtime particles = do
  let commands :: Array (DrawCommand Void)
      commands = particlesToCommands particles
  GPU.render runtime.renderer commands

-- | Render a complete frame with background clear and particles.
renderFrame 
  :: GPURuntime 
  -> { r :: Number, g :: Number, b :: Number, a :: Number }
  -> Array Paint.Particle 
  -> Effect Unit
renderFrame runtime bgColor particles = do
  -- Clear background
  GPU.clear runtime.renderer bgColor
  -- Render particles
  renderParticles runtime particles

-- | Clear the canvas with a color.
clear :: GPURuntime -> { r :: Number, g :: Number, b :: Number, a :: Number } -> Effect Unit
clear runtime color = GPU.clear runtime.renderer color

-- ═══════════════════════════════════════════════════════════════════════════
--                                                                   // info
-- ═══════════════════════════════════════════════════════════════════════════

-- | Get the name of the active backend.
getBackendName :: GPURuntime -> String
getBackendName runtime = backendToString runtime.backend

-- | Get detailed GPU information.
getGPUInfo :: GPURuntime -> Effect GPU.GPUInfo
getGPUInfo runtime = GPU.getGPUInfo runtime.renderer

-- | Get the count of particles in an array.
-- |
-- | Useful for performance monitoring and debugging.
-- | Returns the number of particles that would be rendered.
getParticleCount :: Array Paint.Particle -> Int
getParticleCount particles = Array.length particles

-- | Convert Backend to display string.
backendToString :: GPU.Backend -> String
backendToString backend = case backend of
  GPU.WebGPU -> "WebGPU"
  GPU.WebGL2 -> "WebGL2"
  GPU.Canvas2D -> "Canvas2D"

-- ═══════════════════════════════════════════════════════════════════════════
--                                                     // particle conversion
-- ═══════════════════════════════════════════════════════════════════════════

-- | Convert paint particles to GPU DrawCommands.
-- |
-- | Each particle becomes a DrawParticle command with:
-- | - Position (x, y) in screen coordinates
-- | - Size (radius) in pixels
-- | - Color (RGBA)
-- |
-- | Uses Void as the message type since particles don't have click handlers.
particlesToCommands :: Array Paint.Particle -> Array (DrawCommand Void)
particlesToCommands particles = map particleToCommand particles

-- | Convert a single paint particle to a DrawCommand.
-- |
-- | Uses particle height for z-ordering (impasto effect).
-- | Height 0.0 maps to depth 0.5 (middle), height 1.0+ maps toward 0.0 (near/top).
-- | This ensures thicker paint renders on top of thinner paint.
particleToCommand :: Paint.Particle -> DrawCommand Void
particleToCommand p =
  let
    pos = Paint.particlePosition p
    radius = Paint.particleRadius p
    color = Paint.particleColor p
    height = Paint.particleHeight p
    
    -- Convert Canvas.Types.Color (0-1 floats) to RGB.RGBA (0-255 ints)
    rgbaColor = colorToRGBA color
    
    -- Map height to depth value for impasto z-ordering:
    -- - height 0.0 -> depth 0.5 (middle, flat paint)
    -- - height 1.0 -> depth 0.25 (nearer, raised paint)
    -- - height 2.0+ -> depth 0.0 (nearest, thick impasto)
    -- Lower depth values render on top (near plane).
    -- Clamp height contribution to avoid going negative.
    depthFromHeight = 0.5 - (height * 0.25)
    clampedDepth = if depthFromHeight < 0.0 then 0.0 else depthFromHeight
    
    -- Convert to DrawParticle params
    params :: ParticleParams Void
    params =
      { x: Coord.screenX pos.x
      , y: Coord.screenY pos.y
      , z: depthValue clampedDepth  -- Height-based depth for impasto
      , size: Device.px radius
      , color: rgbaColor
      , pickId: Nothing :: Maybe PickId
      , onClick: Nothing :: Maybe Void
      }
  in
    DrawParticle params

-- | Convert Canvas.Types.Color (0-1 floats) to RGB.RGBA (0-255 ints).
colorToRGBA :: Types.Color -> RGB.RGBA
colorToRGBA c = RGB.rgba
  (Int.floor (c.r * 255.0))
  (Int.floor (c.g * 255.0))
  (Int.floor (c.b * 255.0))
  (Int.floor (c.a * 100.0))  -- Alpha is 0-100 percentage

-- | Render-optimized: Show helper for Boolean
show :: Boolean -> String
show true = "true"
show false = "false"

-- ═══════════════════════════════════════════════════════════════════════════
--                                                             // 3d rendering
-- ═══════════════════════════════════════════════════════════════════════════

-- | Render a 3D layer to the canvas.
-- |
-- | Converts Layer3DContent to DrawScene3D command and renders via GPU.
-- | This integrates 3D content (meshes, lights, camera) with the
-- | existing 2D paint system.
renderScene3D 
  :: forall msg
   . GPURuntime 
  -> Layer3D.Layer3DContent msg 
  -> { x :: Number, y :: Number, width :: Number, height :: Number }
  -> Effect Unit
renderScene3D runtime content viewport = do
  let 
    -- Build the Scene3D from layer content
    scene = Layer3D.buildScene3D content
    
    -- Create DrawScene3D command with viewport
    command :: DrawCommand msg
    command = DrawScene3D
      { camera: scene.camera
      , background: scene.background
      , lights: scene.lights
      , meshes: scene.meshes
      , x: Coord.screenX viewport.x
      , y: Coord.screenY viewport.y
      , width: Coord.pixelWidth viewport.width
      , height: Coord.pixelHeight viewport.height
      , depth: depthValue 0.0  -- 3D scenes render at back
      , pickId: Nothing
      }
  
  GPU.render runtime.renderer [command]

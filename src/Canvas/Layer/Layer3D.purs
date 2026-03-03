-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                  // canvas // layer // layer3d
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | 3D Layer Support — Adds 3D content to canvas layers.
-- |
-- | ## Design Philosophy
-- |
-- | 3D layers extend the paint layer system with:
-- | - 3D scenes using Hydrogen.GPU.Scene3D
-- | - Camera control (perspective, orthographic)
-- | - Lighting (ambient, directional, point, spot)
-- | - 3D meshes rendered via WebGL
-- |
-- | ## Integration
-- |
-- | 3D layers are composited with 2D paint layers:
-- | - 3D content renders to a framebuffer
-- | - Framebuffer is composited as a layer
-- | - Depth buffer allows paint-in-3D effects
-- |
-- | ## Use Cases
-- |
-- | - 3D text/logos with paint effects
-- | - 3D models as painting references
-- | - Particle effects in 3D space
-- | - Z-depth for impasto paint simulation
-- |
-- | ## Dependencies
-- | - Hydrogen.GPU.Scene3D
-- | - Canvas.Types
-- | - Canvas.Layer.Types

module Canvas.Layer.Layer3D
  ( -- * 3D Layer Content
    Layer3DContent
  , emptyLayer3DContent
  , layer3DCamera
  , layer3DLights
  , layer3DMeshes
  , layer3DBackground
  
  -- * Camera
  , setLayer3DCamera
  , defaultPerspectiveCamera
  , defaultOrthographicCamera
  
  -- * Lighting
  , addLight3D
  , removeLight3D
  , clearLights3D
  , defaultAmbientLight
  , defaultDirectionalLight
  , defaultPointLight
  , defaultSpotLight
  , defaultHemisphereLight
  
  -- * Meshes
  , addMesh3D
  , removeMesh3D
  , clearMeshes3D
  , updateMeshAt
  , getMeshAt
  
  -- * Mesh Factories
  , createBoxMesh
  , createSphereMesh
  , createPlaneMesh
  , createTorusMesh
  
  -- * Background
  , setLayer3DBackground
  
  -- * Scene Construction
  , buildScene3D
  
  -- * Camera Presets
  , topDownCamera
  , isometricCamera
  , frontCamera
  
  -- * Layer Modification
  , modifyLayer3D
  , mapMeshes
  , countMeshes
  , countLights
  
  -- * Coordinate Helpers
  , metersTopm
  
  -- * Mesh Transform
  , translateMesh
  , setMeshPosition
  , scaleMeshUniform
  , scaleMesh
  , estimateMeshRadius
  
  -- * Layer Info
  , describeLayer3D
  , hasContent
  , sameCounts
  
  -- * Geometry Queries
  , isBoxMesh
  , isSphereMesh
  , isPlaneMesh
  , isTorusMesh
  , geometryTypeName
  
  -- * Picometer Helpers
  , addPicometers
  , subtractPicometers
  , scalePicometers
  
  -- * Position Helpers
  , meshPosition
  , meshDistanceSquared
  , meshesOverlap
  
  -- * Animation Support
  , lerpMeshPosition
  , lerpPicometer
  , setMeshPositionFrom
  , directionBetweenMeshes
  
  -- * Effectful Helpers
  , OnSceneReady
  , buildScene3DWith
  , validateMeshScale
  , clampNumber
  , clampMeshToBounds
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( Unit
  , ($)
  , (#)
  , (+)
  , (-)
  , (*)
  , (/)
  , (<>)
  , (==)
  , (/=)
  , (<)
  , (>)
  , (&&)
  , map
  , negate
  , otherwise
  )

import Data.Array (snoc, filter, mapWithIndex, index, length, updateAt) as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Data.Foldable (foldl)

-- Hydrogen Scene3D
import Hydrogen.GPU.Scene3D.Camera
  ( Camera3D
  , PerspectiveCameraParams
  , perspectiveCamera
  , OrthographicCameraParams
  , orthographicCamera
  )
import Hydrogen.GPU.Scene3D.Background
  ( Background3D
  , solidBackground
  )
import Hydrogen.GPU.Scene3D.Light
  ( Light3D
  , AmbientLightParams
  , ambientLight3D
  , DirectionalLightParams
  , directionalLight3D
  , PointLightParams
  , pointLight3D
  , SpotLightParams
  , spotLight3D
  , HemisphereLightParams
  , hemisphereLight3D
  )
import Hydrogen.GPU.Scene3D.Mesh
  ( MeshParams
  , Mesh3D
      ( BoxMesh3D
      , SphereMesh3D
      , CylinderMesh3D
      , ConeMesh3D
      , PlaneMesh3D
      , TorusMesh3D
      , TorusKnotMesh3D
      , RingMesh3D
      , CircleMesh3D
      , CapsuleMesh3D
      , IcosahedronMesh3D
      , OctahedronMesh3D
      , TetrahedronMesh3D
      , DodecahedronMesh3D
      , LatheMesh3D
      , ExtrudeMesh3D
      , BufferGeometry3D
      )
  , BoxMeshParams
  , boxMesh3D
  , SphereMeshParams
  , sphereMesh3D
  , PlaneMeshParams
  , planeMesh3D
  , TorusMeshParams
  , torusMesh3D
  )
import Hydrogen.GPU.Scene3D.Material
  ( Material3D
  , StandardMaterialParams
  , standardMaterial3D
  )
import Hydrogen.Schema.Dimension.Rotation.Quaternion (quaternionIdentity)
import Hydrogen.Schema.Dimension.Vector.Vec3 (Vec3, vec3, getX3, getY3, getZ3)
import Hydrogen.GPU.Scene3D.Position
  ( Position3D
  , position3D
  , direction3D
  , getPositionX
  , getPositionY
  , getPositionZ
  )

import Hydrogen.Schema.Dimension.Physical.Atomic (Picometer, picometer, unwrapPicometer)
import Hydrogen.Schema.Dimension.Physical.SI (meter)
import Hydrogen.Schema.Geometry.Angle (degrees)
import Hydrogen.GPU.Scene3D.Core
  ( Scene3D
  , emptyScene
  , withCamera
  , withBackground
  , withLight
  , withMesh
  )

import Hydrogen.Schema.Color.RGB as RGB

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // 3d layer content
-- ═════════════════════════════════════════════════════════════════════════════

-- | Content for a 3D layer.
-- |
-- | Contains the scene description that will be rendered to a framebuffer
-- | and composited with the 2D paint layers.
type Layer3DContent msg =
  { camera :: Camera3D
  , lights :: Array Light3D
  , meshes :: Array (MeshParams msg)
  , background :: Background3D
  }

-- | Create empty 3D layer content with default camera.
emptyLayer3DContent :: forall msg. Layer3DContent msg
emptyLayer3DContent =
  { camera: defaultPerspectiveCamera
  , lights: [ defaultAmbientLight, defaultDirectionalLight ]
  , meshes: []
  , background: defaultBackground3D
  }

-- | Get the camera from 3D layer content.
layer3DCamera :: forall msg. Layer3DContent msg -> Camera3D
layer3DCamera content = content.camera

-- | Get lights from 3D layer content.
layer3DLights :: forall msg. Layer3DContent msg -> Array Light3D
layer3DLights content = content.lights

-- | Get meshes from 3D layer content.
layer3DMeshes :: forall msg. Layer3DContent msg -> Array (MeshParams msg)
layer3DMeshes content = content.meshes

-- | Get background from 3D layer content.
layer3DBackground :: forall msg. Layer3DContent msg -> Background3D
layer3DBackground content = content.background

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // camera
-- ═════════════════════════════════════════════════════════════════════════════

-- | Set the camera for 3D layer content.
setLayer3DCamera :: forall msg. Camera3D -> Layer3DContent msg -> Layer3DContent msg
setLayer3DCamera cam content = content { camera = cam }

-- | Default perspective camera looking at origin from (0, 5, 10).
-- |
-- | Good for typical 3D object viewing.
-- | Positions use meters scale (1e12 picometers per meter).
defaultPerspectiveCamera :: Camera3D
defaultPerspectiveCamera =
  let
    -- Convert meters to picometers (1 meter = 1e12 picometers)
    pm = metersTopm
    params :: PerspectiveCameraParams
    params =
      { position: position3D (pm 0.0) (pm 5.0) (pm 10.0)
      , target: position3D (pm 0.0) (pm 0.0) (pm 0.0)
      , up: direction3D 0.0 1.0 0.0
      , fov: degrees 60.0
      , aspect: 1.0
      , near: meter 0.1
      , far: meter 1000.0
      }
  in perspectiveCamera params

-- | Default orthographic camera for 2D-like 3D rendering.
defaultOrthographicCamera :: Camera3D
defaultOrthographicCamera =
  let
    pm = metersTopm
    params :: OrthographicCameraParams
    params =
      { position: position3D (pm 0.0) (pm 0.0) (pm 10.0)
      , target: position3D (pm 0.0) (pm 0.0) (pm 0.0)
      , up: direction3D 0.0 1.0 0.0
      , left: meter (negate 10.0)
      , right: meter 10.0
      , top: meter 10.0
      , bottom: meter (negate 10.0)
      , near: meter 0.1
      , far: meter 1000.0
      , zoom: 1.0
      }
  in orthographicCamera params

-- | Top-down camera looking straight down (good for 2D games).
-- | Height parameter is in meters.
topDownCamera :: Number -> Camera3D
topDownCamera height =
  let
    pm = metersTopm
    params :: PerspectiveCameraParams
    params =
      { position: position3D (pm 0.0) (pm height) (pm 0.0)
      , target: position3D (pm 0.0) (pm 0.0) (pm 0.0)
      , up: direction3D 0.0 0.0 (negate 1.0)  -- Forward is -Z
      , fov: degrees 60.0
      , aspect: 1.0
      , near: meter 0.1
      , far: meter 1000.0
      }
  in perspectiveCamera params

-- | Isometric camera (45° angle, common in strategy games).
isometricCamera :: Camera3D
isometricCamera =
  let
    -- Isometric angle: 35.264° (arctan(1/sqrt(2)))
    pm = metersTopm
    dist = 20.0
    params :: PerspectiveCameraParams
    params =
      { position: position3D (pm dist) (pm dist) (pm dist)
      , target: position3D (pm 0.0) (pm 0.0) (pm 0.0)
      , up: direction3D 0.0 1.0 0.0
      , fov: degrees 45.0
      , aspect: 1.0
      , near: meter 0.1
      , far: meter 1000.0
      }
  in perspectiveCamera params

-- | Front-facing camera (good for character viewing).
-- | Distance parameter is in meters.
frontCamera :: Number -> Camera3D
frontCamera distance =
  let
    pm = metersTopm
    params :: PerspectiveCameraParams
    params =
      { position: position3D (pm 0.0) (pm 1.0) (pm distance)
      , target: position3D (pm 0.0) (pm 1.0) (pm 0.0)
      , up: direction3D 0.0 1.0 0.0
      , fov: degrees 50.0
      , aspect: 1.0
      , near: meter 0.1
      , far: meter 1000.0
      }
  in perspectiveCamera params

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // helpers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Convert meters to picometers for position coordinates.
-- |
-- | 1 meter = 1e12 picometers
-- | This helper makes camera setup more intuitive.
metersTopm :: Number -> Picometer
metersTopm m = picometer (m * 1.0e12)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                   // lighting
-- ═════════════════════════════════════════════════════════════════════════════

-- | Add a light to 3D layer content.
addLight3D :: forall msg. Light3D -> Layer3DContent msg -> Layer3DContent msg
addLight3D light content = content { lights = Array.snoc content.lights light }

-- | Remove a light from 3D layer content (by index).
removeLight3D :: forall msg. Int -> Layer3DContent msg -> Layer3DContent msg
removeLight3D idx content = 
  let
    -- Filter out the light at the given index
    newLights = Array.mapWithIndex Tuple content.lights
      # Array.filter (\(Tuple i _) -> i /= idx)
      # map (\(Tuple _ light) -> light)
  in
    content { lights = newLights }

-- | Clear all lights from 3D layer content.
clearLights3D :: forall msg. Layer3DContent msg -> Layer3DContent msg
clearLights3D content = content { lights = [] }

-- | Default ambient light (soft overall illumination).
defaultAmbientLight :: Light3D
defaultAmbientLight =
  let
    params :: AmbientLightParams
    params =
      { color: RGB.rgba 100 100 100 100  -- Soft gray
      , intensity: 0.4
      }
  in ambientLight3D params

-- | Default directional light (sun-like).
defaultDirectionalLight :: Light3D
defaultDirectionalLight =
  let
    params :: DirectionalLightParams
    params =
      { color: RGB.rgba 255 255 255 100  -- White
      , intensity: 0.8
      , direction: direction3D (negate 1.0) (negate 1.0) (negate 1.0)
      , castShadow: false
      , shadowMapSize: 1024
      , shadowBias: 0.0001
      }
  in directionalLight3D params

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // meshes
-- ═════════════════════════════════════════════════════════════════════════════

-- | Add a mesh to 3D layer content.
addMesh3D :: forall msg. MeshParams msg -> Layer3DContent msg -> Layer3DContent msg
addMesh3D mesh content = content { meshes = Array.snoc content.meshes mesh }

-- | Remove a mesh from 3D layer content (by index).
removeMesh3D :: forall msg. Int -> Layer3DContent msg -> Layer3DContent msg
removeMesh3D idx content =
  let
    -- Filter out the mesh at the given index
    newMeshes = Array.mapWithIndex Tuple content.meshes
      # Array.filter (\(Tuple i _) -> i /= idx)
      # map (\(Tuple _ mesh) -> mesh)
  in
    content { meshes = newMeshes }

-- | Clear all meshes from 3D layer content.
clearMeshes3D :: forall msg. Layer3DContent msg -> Layer3DContent msg
clearMeshes3D content = content { meshes = [] }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                 // background
-- ═════════════════════════════════════════════════════════════════════════════

-- | Set the background for 3D layer content.
setLayer3DBackground :: forall msg. Background3D -> Layer3DContent msg -> Layer3DContent msg
setLayer3DBackground bg content = content { background = bg }

-- | Default transparent background (allows compositing with 2D).
defaultBackground3D :: Background3D
defaultBackground3D = solidBackground (RGB.rgba 0 0 0 0)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // scene construction
-- ═════════════════════════════════════════════════════════════════════════════

-- | Build a Scene3D from Layer3DContent.
-- |
-- | This creates the command list that will be rendered by the GPU.
buildScene3D :: forall msg. Layer3DContent msg -> Scene3D msg
buildScene3D content =
  let
    -- Start with empty scene
    baseScene = emptyScene
    
    -- Add camera
    withCam = withCamera content.camera baseScene
    
    -- Add background
    withBg = withBackground content.background withCam
    
    -- Add all lights
    withLights = addAllLights content.lights withBg
    
    -- Add all meshes
    withMeshes = addAllMeshes content.meshes withLights
  in
    withMeshes

-- | Helper to add all lights to a scene.
addAllLights :: forall msg. Array Light3D -> Scene3D msg -> Scene3D msg
addAllLights lights scene = foldl (\s l -> withLight l s) scene lights

-- | Helper to add all meshes to a scene.
addAllMeshes :: forall msg. Array (MeshParams msg) -> Scene3D msg -> Scene3D msg
addAllMeshes meshes scene = foldl (\s m -> withMesh m s) scene meshes

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // more light types
-- ═════════════════════════════════════════════════════════════════════════════

-- | Default point light (omnidirectional from a point).
-- |
-- | Positioned at (2, 3, 2) meters, good for indoor scenes.
defaultPointLight :: Light3D
defaultPointLight =
  let
    pm = metersTopm
    params :: PointLightParams
    params =
      { color: RGB.rgba 255 255 200 100  -- Warm white
      , intensity: 1.0
      , position: position3D (pm 2.0) (pm 3.0) (pm 2.0)
      , distance: meter 50.0
      , decay: 2.0  -- Physically correct inverse square
      , castShadow: true
      }
  in pointLight3D params

-- | Default spot light (cone of light).
-- |
-- | Positioned above and in front, pointing at origin.
defaultSpotLight :: Light3D
defaultSpotLight =
  let
    pm = metersTopm
    params :: SpotLightParams
    params =
      { color: RGB.rgba 255 255 255 100
      , intensity: 1.0
      , position: position3D (pm 0.0) (pm 5.0) (pm 5.0)
      , target: position3D (pm 0.0) (pm 0.0) (pm 0.0)
      , distance: meter 100.0
      , angle: degrees 30.0
      , penumbra: 0.5  -- Soft edge
      , decay: 2.0
      , castShadow: true
      }
  in spotLight3D params

-- | Default hemisphere light (sky + ground ambient).
-- |
-- | Blue sky above, green-brown ground below.
defaultHemisphereLight :: Light3D
defaultHemisphereLight =
  let
    params :: HemisphereLightParams
    params =
      { skyColor: RGB.rgba 135 206 235 100    -- Sky blue
      , groundColor: RGB.rgba 139 119 101 100  -- Earth brown
      , intensity: 0.6
      }
  in hemisphereLight3D params

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // mesh operations
-- ═════════════════════════════════════════════════════════════════════════════

-- | Get mesh at index (safe).
getMeshAt :: forall msg. Int -> Layer3DContent msg -> Maybe (MeshParams msg)
getMeshAt idx content = Array.index content.meshes idx

-- | Update mesh at index.
-- |
-- | Returns the layer unchanged if index is out of bounds.
updateMeshAt :: forall msg. Int -> (MeshParams msg -> MeshParams msg) -> Layer3DContent msg -> Layer3DContent msg
updateMeshAt idx f content =
  case Array.index content.meshes idx of
    Nothing -> content
    Just mesh ->
      let
        updated = f mesh
        newMeshes = fromMaybe content.meshes $ Array.updateAt idx updated content.meshes
      in
        content { meshes = newMeshes }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // mesh factories
-- ═════════════════════════════════════════════════════════════════════════════

-- | Create a box mesh with default material at origin.
-- |
-- | Width, height, depth in meters.
createBoxMesh :: forall msg. Number -> Number -> Number -> MeshParams msg
createBoxMesh w h d =
  let
    pm = metersTopm
    geom :: BoxMeshParams
    geom =
      { width: meter w
      , height: meter h
      , depth: meter d
      , widthSegments: 1
      , heightSegments: 1
      , depthSegments: 1
      }
  in
    { geometry: boxMesh3D geom
    , material: defaultMaterial
    , position: position3D (pm 0.0) (pm 0.0) (pm 0.0)
    , rotation: quaternionIdentity
    , scale: vec3 1.0 1.0 1.0
    , castShadow: true
    , receiveShadow: true
    , pickId: Nothing
    , onClick: Nothing
    , onHover: Nothing
    }

-- | Create a sphere mesh with default material at origin.
-- |
-- | Radius in meters.
createSphereMesh :: forall msg. Number -> MeshParams msg
createSphereMesh radius =
  let
    pm = metersTopm
    geom :: SphereMeshParams
    geom =
      { radius: meter radius
      , widthSegments: 32
      , heightSegments: 16
      , phiStart: degrees 0.0
      , phiLength: degrees 360.0
      , thetaStart: degrees 0.0
      , thetaLength: degrees 180.0
      }
  in
    { geometry: sphereMesh3D geom
    , material: defaultMaterial
    , position: position3D (pm 0.0) (pm 0.0) (pm 0.0)
    , rotation: quaternionIdentity
    , scale: vec3 1.0 1.0 1.0
    , castShadow: true
    , receiveShadow: true
    , pickId: Nothing
    , onClick: Nothing
    , onHover: Nothing
    }

-- | Create a plane mesh with default material at origin.
-- |
-- | Width and height in meters.
createPlaneMesh :: forall msg. Number -> Number -> MeshParams msg
createPlaneMesh w h =
  let
    pm = metersTopm
    geom :: PlaneMeshParams
    geom =
      { width: meter w
      , height: meter h
      , widthSegments: 1
      , heightSegments: 1
      }
  in
    { geometry: planeMesh3D geom
    , material: defaultMaterial
    , position: position3D (pm 0.0) (pm 0.0) (pm 0.0)
    , rotation: quaternionIdentity
    , scale: vec3 1.0 1.0 1.0
    , castShadow: false
    , receiveShadow: true
    , pickId: Nothing
    , onClick: Nothing
    , onHover: Nothing
    }

-- | Create a torus mesh with default material at origin.
-- |
-- | Major radius and tube radius in meters.
createTorusMesh :: forall msg. Number -> Number -> MeshParams msg
createTorusMesh majorRadius tubeRadius =
  let
    pm = metersTopm
    geom :: TorusMeshParams
    geom =
      { radius: meter majorRadius
      , tube: meter tubeRadius
      , radialSegments: 16
      , tubularSegments: 48
      , arc: degrees 360.0
      }
  in
    { geometry: torusMesh3D geom
    , material: defaultMaterial
    , position: position3D (pm 0.0) (pm 0.0) (pm 0.0)
    , rotation: quaternionIdentity
    , scale: vec3 1.0 1.0 1.0
    , castShadow: true
    , receiveShadow: true
    , pickId: Nothing
    , onClick: Nothing
    , onHover: Nothing
    }

-- | Default standard PBR material.
-- |
-- | Gray color, moderate roughness and metalness.
defaultMaterial :: Material3D
defaultMaterial =
  let
    params :: StandardMaterialParams
    params =
      { color: RGB.rgba 180 180 180 255  -- Light gray
      , roughness: 0.5
      , metalness: 0.0
      , emissive: RGB.rgba 0 0 0 0
      , emissiveIntensity: 0.0
      , opacity: 1.0
      , transparent: false
      , wireframe: false
      }
  in standardMaterial3D params

-- ═════════════════════════════════════════════════════════════════════════════
--                                                       // layer modification
-- ═════════════════════════════════════════════════════════════════════════════

-- | Modify layer content with a function.
modifyLayer3D :: forall msg. (Layer3DContent msg -> Layer3DContent msg) -> Layer3DContent msg -> Layer3DContent msg
modifyLayer3D f content = f content

-- | Map over all meshes in the layer.
mapMeshes :: forall msg. (MeshParams msg -> MeshParams msg) -> Layer3DContent msg -> Layer3DContent msg
mapMeshes f content = content { meshes = map f content.meshes }

-- | Count meshes in the layer.
countMeshes :: forall msg. Layer3DContent msg -> Int
countMeshes content = Array.length content.meshes

-- | Count lights in the layer.
countLights :: forall msg. Layer3DContent msg -> Int
countLights content = Array.length content.lights

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // mesh positioning
-- ═════════════════════════════════════════════════════════════════════════════

-- | Move a mesh by offset (in meters).
translateMesh :: forall msg. Number -> Number -> Number -> MeshParams msg -> MeshParams msg
translateMesh dx dy dz mesh =
  let
    -- Get current position and add offset
    pm = metersTopm
    newPos = position3D 
      (addPicometers (getPositionX mesh.position) (pm dx))
      (addPicometers (getPositionY mesh.position) (pm dy))
      (addPicometers (getPositionZ mesh.position) (pm dz))
  in
    mesh { position = newPos }

-- | Set mesh position (in meters).
setMeshPosition :: forall msg. Number -> Number -> Number -> MeshParams msg -> MeshParams msg
setMeshPosition x y z mesh =
  let
    pm = metersTopm
    newPos = position3D (pm x) (pm y) (pm z)
  in
    mesh { position = newPos }

-- | Scale mesh uniformly.
scaleMeshUniform :: forall msg. Number -> MeshParams msg -> MeshParams msg
scaleMeshUniform s mesh =
  mesh { scale = vec3 s s s }

-- | Scale mesh non-uniformly.
scaleMesh :: forall msg. Number -> Number -> Number -> MeshParams msg -> MeshParams msg
scaleMesh sx sy sz mesh =
  mesh { scale = vec3 sx sy sz }

-- | Get mesh bounding sphere radius estimate (assumes unit geometry scaled).
-- |
-- | This is an approximation for collision detection / culling.
estimateMeshRadius :: forall msg. MeshParams msg -> Number
estimateMeshRadius mesh =
  let
    -- Get the maximum scale component
    sx = getScaleX mesh.scale
    sy = getScaleY mesh.scale
    sz = getScaleZ mesh.scale
    maxScale = maxNum sx (maxNum sy sz)
  in
    -- Assume base geometry fits in unit sphere
    maxScale

-- ═════════════════════════════════════════════════════════════════════════════
--                                                              // layer info
-- ═════════════════════════════════════════════════════════════════════════════

-- | Get a debug description of the layer content.
describeLayer3D :: forall msg. Layer3DContent msg -> String
describeLayer3D content =
  "Layer3D { meshes: " <> showInt (countMeshes content) 
    <> ", lights: " <> showInt (countLights content) 
    <> " }"

-- | Check if layer has any content.
hasContent :: forall msg. Layer3DContent msg -> Boolean
hasContent content =
  countMeshes content + countLights content > 0

-- | Check if two layers have the same counts (quick equality check).
sameCounts :: forall msg. Layer3DContent msg -> Layer3DContent msg -> Boolean
sameCounts a b =
  countMeshes a == countMeshes b && countLights a == countLights b

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // geometry queries
-- ═════════════════════════════════════════════════════════════════════════════

-- | Check if mesh uses box geometry.
isBoxMesh :: forall msg. MeshParams msg -> Boolean
isBoxMesh mesh = case mesh.geometry of
  BoxMesh3D _ -> true
  _ -> false

-- | Check if mesh uses sphere geometry.
isSphereMesh :: forall msg. MeshParams msg -> Boolean
isSphereMesh mesh = case mesh.geometry of
  SphereMesh3D _ -> true
  _ -> false

-- | Check if mesh uses plane geometry.
isPlaneMesh :: forall msg. MeshParams msg -> Boolean
isPlaneMesh mesh = case mesh.geometry of
  PlaneMesh3D _ -> true
  _ -> false

-- | Check if mesh uses torus geometry.
isTorusMesh :: forall msg. MeshParams msg -> Boolean
isTorusMesh mesh = case mesh.geometry of
  TorusMesh3D _ -> true
  _ -> false

-- | Get geometry type name.
geometryTypeName :: Mesh3D -> String
geometryTypeName geom = case geom of
  BoxMesh3D _ -> "Box"
  SphereMesh3D _ -> "Sphere"
  CylinderMesh3D _ -> "Cylinder"
  ConeMesh3D _ -> "Cone"
  PlaneMesh3D _ -> "Plane"
  TorusMesh3D _ -> "Torus"
  TorusKnotMesh3D _ -> "TorusKnot"
  RingMesh3D _ -> "Ring"
  CircleMesh3D _ -> "Circle"
  CapsuleMesh3D _ -> "Capsule"
  IcosahedronMesh3D _ -> "Icosahedron"
  OctahedronMesh3D _ -> "Octahedron"
  TetrahedronMesh3D _ -> "Tetrahedron"
  DodecahedronMesh3D _ -> "Dodecahedron"
  LatheMesh3D _ -> "Lathe"
  ExtrudeMesh3D _ -> "Extrude"
  BufferGeometry3D _ -> "BufferGeometry"

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // internal helpers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Add two picometer values.
addPicometers :: Picometer -> Picometer -> Picometer
addPicometers a b = picometer (unwrapPicometer a + unwrapPicometer b)

-- | Subtract two picometer values.
subtractPicometers :: Picometer -> Picometer -> Picometer
subtractPicometers a b = picometer (unwrapPicometer a - unwrapPicometer b)

-- | Scale picometer value.
scalePicometers :: Number -> Picometer -> Picometer
scalePicometers s pm = picometer (unwrapPicometer pm * s)

-- | Get X component of Vec3 scale.
getScaleX :: Vec3 Number -> Number
getScaleX = getX3

-- | Get Y component of Vec3 scale.
getScaleY :: Vec3 Number -> Number
getScaleY = getY3

-- | Get Z component of Vec3 scale.
getScaleZ :: Vec3 Number -> Number
getScaleZ = getZ3

-- | Max of two numbers.
maxNum :: Number -> Number -> Number
maxNum a b = if a > b then a else b

-- | Show Int as String.
showInt :: Int -> String
showInt n = showIntImpl n

-- | Foreign implementation for showInt.
foreign import showIntImpl :: Int -> String

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // position helpers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Get mesh position as Position3D.
meshPosition :: forall msg. MeshParams msg -> Position3D
meshPosition mesh = mesh.position

-- | Calculate squared distance between two mesh positions (in picometers squared).
-- |
-- | Uses squared distance to avoid sqrt for comparison operations.
meshDistanceSquared :: forall msg. MeshParams msg -> MeshParams msg -> Number
meshDistanceSquared meshA meshB =
  let
    -- Get positions
    posA = meshA.position
    posB = meshB.position
    -- Calculate deltas
    dx = subtractPicometers (getPositionX posB) (getPositionX posA)
    dy = subtractPicometers (getPositionY posB) (getPositionY posA)
    dz = subtractPicometers (getPositionZ posB) (getPositionZ posA)
    -- Convert to numbers for arithmetic
    dxN = unwrapPicometer dx
    dyN = unwrapPicometer dy
    dzN = unwrapPicometer dz
  in
    dxN * dxN + dyN * dyN + dzN * dzN

-- | Check if two meshes overlap (bounding sphere intersection).
-- |
-- | Uses estimated radius from scale and checks if distance < sum of radii.
meshesOverlap :: forall msg. MeshParams msg -> MeshParams msg -> Boolean
meshesOverlap meshA meshB =
  let
    radiusA = estimateMeshRadius meshA
    radiusB = estimateMeshRadius meshB
    -- Convert radii to picometers (assuming meters scale)
    radiusSumPm = (radiusA + radiusB) * 1.0e12
    radiusSumSq = radiusSumPm * radiusSumPm
    distSq = meshDistanceSquared meshA meshB
  in
    distSq < radiusSumSq

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // animation support
-- ═════════════════════════════════════════════════════════════════════════════

-- | Interpolate mesh position (linear).
-- |
-- | t = 0.0 returns position A, t = 1.0 returns position B.
lerpMeshPosition :: forall msg. Number -> MeshParams msg -> MeshParams msg -> Position3D
lerpMeshPosition t meshA meshB =
  let
    posA = meshA.position
    posB = meshB.position
    -- Interpolate each component
    x = lerpPicometer t (getPositionX posA) (getPositionX posB)
    y = lerpPicometer t (getPositionY posA) (getPositionY posB)
    z = lerpPicometer t (getPositionZ posA) (getPositionZ posB)
  in
    position3D x y z

-- | Linear interpolation of picometer values.
lerpPicometer :: Number -> Picometer -> Picometer -> Picometer
lerpPicometer t a b =
  let
    aVal = unwrapPicometer a
    bVal = unwrapPicometer b
    result = aVal + t * (bVal - aVal)
  in
    picometer result

-- | Apply position from interpolation to a mesh.
setMeshPositionFrom :: forall msg. Position3D -> MeshParams msg -> MeshParams msg
setMeshPositionFrom pos mesh = mesh { position = pos }

-- | Normalized direction from mesh A to mesh B (for physics/AI).
-- |
-- | Returns unit vector, or zero vector if positions are equal.
directionBetweenMeshes :: forall msg. MeshParams msg -> MeshParams msg -> { x :: Number, y :: Number, z :: Number }
directionBetweenMeshes meshA meshB =
  let
    posA = meshA.position
    posB = meshB.position
    dx = unwrapPicometer (subtractPicometers (getPositionX posB) (getPositionX posA))
    dy = unwrapPicometer (subtractPicometers (getPositionY posB) (getPositionY posA))
    dz = unwrapPicometer (subtractPicometers (getPositionZ posB) (getPositionZ posA))
    lenSq = dx * dx + dy * dy + dz * dz
  in
    if lenSq == 0.0
      then { x: 0.0, y: 0.0, z: 0.0 }
      else
        let
          len = sqrt lenSq
          invLen = 1.0 / len
        in
          { x: dx * invLen, y: dy * invLen, z: dz * invLen }

-- | Square root (imported from Math).
foreign import sqrt :: Number -> Number

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // effectful helpers
-- ═════════════════════════════════════════════════════════════════════════════

-- | Callback type for scene ready notification.
type OnSceneReady msg = Scene3D msg -> Unit

-- | Create scene with callback (for integration with render loop).
-- |
-- | This pattern allows effectful handling of scene construction.
buildScene3DWith :: forall msg. Layer3DContent msg -> OnSceneReady msg -> Unit
buildScene3DWith content callback =
  callback (buildScene3D content)

-- | Validate mesh scale (all components must be positive).
-- |
-- | Uses guards with otherwise for comprehensive checking.
validateMeshScale :: forall msg. MeshParams msg -> Boolean
validateMeshScale mesh
  | getScaleX mesh.scale > 0.0 && getScaleY mesh.scale > 0.0 && getScaleZ mesh.scale > 0.0 = true
  | otherwise = false

-- | Clamp a number to a range.
clampNumber :: Number -> Number -> Number -> Number
clampNumber minVal maxVal n
  | n < minVal = minVal
  | n > maxVal = maxVal
  | otherwise = n

-- | Clamp mesh position to bounds (in meters).
-- |
-- | Useful for keeping objects within a play area.
clampMeshToBounds :: forall msg. Number -> Number -> Number -> Number -> Number -> Number -> MeshParams msg -> MeshParams msg
clampMeshToBounds minX maxX minY maxY minZ maxZ mesh =
  let
    pm = metersTopm
    posX = unwrapPicometer (getPositionX mesh.position) / 1.0e12
    posY = unwrapPicometer (getPositionY mesh.position) / 1.0e12
    posZ = unwrapPicometer (getPositionZ mesh.position) / 1.0e12
    clampedX = clampNumber minX maxX posX
    clampedY = clampNumber minY maxY posY
    clampedZ = clampNumber minZ maxZ posZ
    newPos = position3D (pm clampedX) (pm clampedY) (pm clampedZ)
  in
    mesh { position = newPos }

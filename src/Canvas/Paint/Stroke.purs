-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                  // canvas // paint // stroke
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Paint Stroke — Recording and playback of brush strokes.
-- |
-- | ## Design Philosophy
-- |
-- | A stroke is a sequence of input events (touch/stylus points) that
-- | generates paint particles. When the stroke is committed (pen lifted),
-- | the particles dry and become a permanent part of the layer.
-- |
-- | ## Stroke Lifecycle
-- |
-- | 1. **Begin**: Pen/touch down → create stroke, add first point
-- | 2. **Continue**: Pen/touch move → add points, generate particles
-- | 3. **End**: Pen/touch up → finalize stroke, begin drying
-- | 4. **Commit**: Fully dried → stroke becomes static geometry
-- |
-- | ## Input Data
-- |
-- | Each point captures full stylus/touch state:
-- | - Position (x, y)
-- | - Pressure (0-1)
-- | - Tilt (altitude, azimuth)
-- | - Timestamp
-- |
-- | ## Dependencies
-- | - Prelude
-- | - Canvas.Types

module Canvas.Paint.Stroke
  ( -- * Stroke Point
    StrokePoint
  , mkStrokePoint
  , pointX
  , pointY
  , pointPressure
  , pointTiltX
  , pointTiltY
  , pointTimestamp
  
  -- * Stroke Segment
  , StrokeSegment
  , mkStrokeSegment
  , segmentStart
  , segmentEnd
  , segmentLength
  , segmentAveragePressure
  , computeStrokeSegments
  
  -- * Stroke
  , Stroke
  , mkStroke
  , emptyStroke
  , strokeId
  , strokeLayerId
  , strokeColor
  , strokeBrushSize
  , strokePoints
  , strokeBounds
  , strokeStartTime
  , strokeEndTime
  , strokeDuration
  
  -- * Stroke Building
  , beginStroke
  , addPoint
  , endStroke
  , isStrokeActive
  , isStrokeEmpty
  
  -- * Stroke Analysis
  , strokeLength
  , strokeAverageSpeed
  , strokeAveragePressure
  , strokePointCount
  
  -- * Stroke Transforms
  , mirrorStrokeX
  , mirrorStrokeY
  , translateStroke
  , segmentVelocity
  
  -- * Particle Generation
  , generateParticlePositions
  , generateParticleData
  , ParticleSpawnData
  , interpolatePoints
  , interpolatePointsWithPressure
  
  -- * Display
  , displayStroke
  , displayStrokePoint
  , displayStrokeSegment
  ) where

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // imports
-- ═════════════════════════════════════════════════════════════════════════════

import Prelude
  ( class Eq
  , class Show
  , show
  , (==)
  , (/=)
  , (&&)
  , (||)
  , (>=)
  , (<=)
  , (<)
  , (>)
  , (+)
  , (-)
  , (*)
  , (/)
  , (<>)
  , map
  , max
  , min
  , negate
  )

import Data.Array (length, head, last, snoc, zipWith, foldl, index) as Array
import Data.Maybe (Maybe(Just, Nothing), fromMaybe)
import Data.Number (sqrt) as Num
import Data.Int (toNumber, floor) as Int

import Canvas.Types
  ( StrokeId
  , mkStrokeId
  , unwrapStrokeId
  , LayerId
  , mkLayerId
  , Point2D
  , mkPoint2D
  , Bounds
  , mkBounds
  , Color
  , colorBlack
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                               // stroke point
-- ═════════════════════════════════════════════════════════════════════════════

-- | A single point in a stroke with full input state.
type StrokePoint =
  { x :: Number              -- ^ X position in canvas coords
  , y :: Number              -- ^ Y position in canvas coords
  , pressure :: Number       -- ^ Pen pressure (0-1, 0.5 for touch)
  , tiltX :: Number          -- ^ Pen tilt X (-90 to 90 degrees)
  , tiltY :: Number          -- ^ Pen tilt Y (-90 to 90 degrees)
  , timestamp :: Number      -- ^ Time since stroke start (ms)
  }

-- | Create a stroke point with validation.
mkStrokePoint 
  :: Number   -- ^ X
  -> Number   -- ^ Y
  -> Number   -- ^ Pressure (clamped to 0-1)
  -> Number   -- ^ Tilt X
  -> Number   -- ^ Tilt Y
  -> Number   -- ^ Timestamp
  -> StrokePoint
mkStrokePoint px py press tx ty ts =
  { x: px
  , y: py
  , pressure: max 0.0 (min 1.0 press)
  , tiltX: max (-90.0) (min 90.0 tx)
  , tiltY: max (-90.0) (min 90.0 ty)
  , timestamp: max 0.0 ts
  }

-- | Get X coordinate.
pointX :: StrokePoint -> Number
pointX p = p.x

-- | Get Y coordinate.
pointY :: StrokePoint -> Number
pointY p = p.y

-- | Get pressure.
pointPressure :: StrokePoint -> Number
pointPressure p = p.pressure

-- | Get tilt X.
pointTiltX :: StrokePoint -> Number
pointTiltX p = p.tiltX

-- | Get tilt Y.
pointTiltY :: StrokePoint -> Number
pointTiltY p = p.tiltY

-- | Get timestamp.
pointTimestamp :: StrokePoint -> Number
pointTimestamp p = p.timestamp

-- ═════════════════════════════════════════════════════════════════════════════
--                                                             // stroke segment
-- ═════════════════════════════════════════════════════════════════════════════

-- | A segment between two consecutive stroke points.
-- |
-- | Segments are created by pairing consecutive points using zipWith.
-- | They capture the transition between two input samples, enabling:
-- | - Smooth pressure interpolation along the segment
-- | - Velocity calculation (distance / time delta)
-- | - Proper particle spawning with varying properties
type StrokeSegment =
  { start :: StrokePoint       -- ^ Starting point
  , end :: StrokePoint         -- ^ Ending point
  }

-- | Create a stroke segment from two points.
mkStrokeSegment :: StrokePoint -> StrokePoint -> StrokeSegment
mkStrokeSegment startPt endPt =
  { start: startPt
  , end: endPt
  }

-- | Get segment start point.
segmentStart :: StrokeSegment -> StrokePoint
segmentStart seg = seg.start

-- | Get segment end point.
segmentEnd :: StrokeSegment -> StrokePoint
segmentEnd seg = seg.end

-- | Calculate segment length (distance between points).
segmentLength :: StrokeSegment -> Number
segmentLength seg =
  let
    dx = seg.end.x - seg.start.x
    dy = seg.end.y - seg.start.y
  in
    Num.sqrt (dx * dx + dy * dy)

-- | Calculate average pressure across segment.
segmentAveragePressure :: StrokeSegment -> Number
segmentAveragePressure seg = (seg.start.pressure + seg.end.pressure) / 2.0

-- | Compute all segments from stroke points using zipWith.
-- |
-- | This pairs consecutive points: [p0,p1,p2,p3] -> [seg(p0,p1), seg(p1,p2), seg(p2,p3)]
-- | The zipWith function is used to combine points[0..n-2] with points[1..n-1].
computeStrokeSegments :: Stroke -> Array StrokeSegment
computeStrokeSegments stroke =
  let
    pts = stroke.points
    n = Array.length pts
  in
    if n < 2
      then []
      else
        -- zipWith pairs each point with the next point
        -- points[0..n-2] paired with points[1..n-1]
        let
          startPoints = takeInit pts
          endPoints = dropFirst pts
        in
          Array.zipWith mkStrokeSegment startPoints endPoints

-- | Take all elements except the last.
takeInit :: forall a. Array a -> Array a
takeInit arr =
  let n = Array.length arr
  in if n <= 1 then [] else takeN (n - 1) arr

-- | Drop the first element.
dropFirst :: forall a. Array a -> Array a
dropFirst arr =
  case Array.index arr 0 of
    Nothing -> []
    Just _ -> dropN 1 arr

-- | Take first N elements.
takeN :: forall a. Int -> Array a -> Array a
takeN n arr =
  Array.foldl (\acc i ->
    case Array.index arr i of
      Just x -> Array.snoc acc x
      Nothing -> acc
  ) [] (range 0 (n - 1))

-- | Drop first N elements.
dropN :: forall a. Int -> Array a -> Array a
dropN n arr =
  let len = Array.length arr
  in Array.foldl (\acc i ->
    case Array.index arr i of
      Just x -> Array.snoc acc x
      Nothing -> acc
  ) [] (range n (len - 1))

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                     // stroke
-- ═════════════════════════════════════════════════════════════════════════════

-- | A complete brush stroke (sequence of input points).
type Stroke =
  { id :: StrokeId           -- ^ Unique identifier
  , layerId :: LayerId       -- ^ Layer this stroke belongs to
  , color :: Color           -- ^ Stroke color
  , brushSize :: Number      -- ^ Brush size at stroke start
  , points :: Array StrokePoint
  , active :: Boolean        -- ^ Is stroke still being drawn?
  , startTime :: Number      -- ^ Absolute timestamp of first point
  , endTime :: Number        -- ^ Absolute timestamp of last point (0 if active)
  }

-- | Create a stroke.
mkStroke :: StrokeId -> LayerId -> Color -> Number -> Stroke
mkStroke sid lid col bsize =
  { id: sid
  , layerId: lid
  , color: col
  , brushSize: max 1.0 bsize
  , points: []
  , active: true
  , startTime: 0.0
  , endTime: 0.0
  }

-- | Empty stroke (placeholder).
emptyStroke :: Stroke
emptyStroke = mkStroke (mkStrokeId 0) (mkLayerId 0) colorBlack 10.0

-- | Get stroke ID.
strokeId :: Stroke -> StrokeId
strokeId s = s.id

-- | Get layer ID.
strokeLayerId :: Stroke -> LayerId
strokeLayerId s = s.layerId

-- | Get stroke color.
strokeColor :: Stroke -> Color
strokeColor s = s.color

-- | Get brush size.
strokeBrushSize :: Stroke -> Number
strokeBrushSize s = s.brushSize

-- | Get all points.
strokePoints :: Stroke -> Array StrokePoint
strokePoints s = s.points

-- | Get start time.
strokeStartTime :: Stroke -> Number
strokeStartTime s = s.startTime

-- | Get end time.
strokeEndTime :: Stroke -> Number
strokeEndTime s = s.endTime

-- | Get stroke duration (ms).
strokeDuration :: Stroke -> Number
strokeDuration s =
  if s.active
    then case Array.last s.points of
      Just p -> p.timestamp
      Nothing -> 0.0
    else s.endTime - s.startTime

-- | Calculate stroke bounding box.
strokeBounds :: Stroke -> Bounds
strokeBounds s =
  case Array.head s.points of
    Nothing -> mkBounds 0.0 0.0 0.0 0.0
    Just firstPt ->
      let
        initial = 
          { minX: firstPt.x
          , minY: firstPt.y
          , maxX: firstPt.x
          , maxY: firstPt.y
          }
        result = Array.foldl (\acc pt ->
          { minX: min acc.minX pt.x
          , minY: min acc.minY pt.y
          , maxX: max acc.maxX pt.x
          , maxY: max acc.maxY pt.y
          }
        ) initial s.points
      in
        mkBounds result.minX result.minY 
          (result.maxX - result.minX) 
          (result.maxY - result.minY)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // stroke building
-- ═════════════════════════════════════════════════════════════════════════════

-- | Begin a new stroke with first point.
beginStroke 
  :: StrokeId 
  -> LayerId 
  -> Color 
  -> Number        -- ^ Brush size
  -> Number        -- ^ X
  -> Number        -- ^ Y
  -> Number        -- ^ Pressure
  -> Number        -- ^ Absolute timestamp
  -> Stroke
beginStroke sid lid col bsize px py press absTime =
  let
    stroke = mkStroke sid lid col bsize
    firstPoint = mkStrokePoint px py press 0.0 0.0 0.0  -- relative time = 0
  in
    stroke 
      { points = [firstPoint]
      , startTime = absTime
      }

-- | Add a point to an active stroke.
addPoint :: Stroke -> Number -> Number -> Number -> Number -> Stroke
addPoint stroke px py press absTime =
  if stroke.active
    then
      let
        relTime = absTime - stroke.startTime
        newPoint = mkStrokePoint px py press 0.0 0.0 relTime
      in
        stroke { points = Array.snoc stroke.points newPoint }
    else stroke

-- | End the stroke (mark as complete).
endStroke :: Stroke -> Number -> Stroke
endStroke stroke absTime =
  stroke 
    { active = false
    , endTime = absTime
    }

-- | Check if stroke is still being drawn.
isStrokeActive :: Stroke -> Boolean
isStrokeActive s = s.active

-- | Check if stroke has no points.
isStrokeEmpty :: Stroke -> Boolean
isStrokeEmpty s = Array.length s.points == 0

-- ═════════════════════════════════════════════════════════════════════════════
--                                                            // stroke analysis
-- ═════════════════════════════════════════════════════════════════════════════

-- | Get number of points.
strokePointCount :: Stroke -> Int
strokePointCount s = Array.length s.points

-- | Calculate total stroke length (sum of segment distances).
strokeLength :: Stroke -> Number
strokeLength s =
  let
    pts = s.points
    n = Array.length pts
  in
    if n < 2
      then 0.0
      else
        Array.foldl (\acc i ->
          case { prev: Array.index pts i, curr: Array.index pts (i + 1) } of
            { prev: Just p1, curr: Just p2 } ->
              let
                dx = p2.x - p1.x
                dy = p2.y - p1.y
              in
                acc + Num.sqrt (dx * dx + dy * dy)
            _ -> acc
        ) 0.0 (range 0 (n - 2))

-- | Calculate average drawing speed (px/ms).
strokeAverageSpeed :: Stroke -> Number
strokeAverageSpeed s =
  let
    len = strokeLength s
    dur = strokeDuration s
  in
    if dur > 0.0 then len / dur else 0.0

-- | Calculate average pressure.
strokeAveragePressure :: Stroke -> Number
strokeAveragePressure s =
  let
    pts = s.points
    n = Array.length pts
    total = Array.foldl (\acc p -> acc + p.pressure) 0.0 pts
  in
    if n > 0 then total / Int.toNumber n else 0.0

-- | Generate integer range [start..end] inclusive.
range :: Int -> Int -> Array Int
range start end =
  if start > end
    then []
    else rangeHelper start end []

rangeHelper :: Int -> Int -> Array Int -> Array Int
rangeHelper current end acc =
  if current > end
    then acc
    else rangeHelper (current + 1) end (Array.snoc acc current)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                          // stroke transforms
-- ═════════════════════════════════════════════════════════════════════════════

-- | Mirror stroke around X axis (negate Y coordinates).
-- |
-- | Useful for creating symmetric patterns or correcting
-- | strokes drawn in the wrong vertical direction.
mirrorStrokeX :: Number -> Stroke -> Stroke
mirrorStrokeX centerY stroke =
  let
    mirrorPoint :: StrokePoint -> StrokePoint
    mirrorPoint p =
      let
        -- Distance from center
        distFromCenter = p.y - centerY
        -- Negate the distance to mirror
        newY = centerY + negate distFromCenter
      in
        p { y = newY }
  in
    stroke { points = map mirrorPoint stroke.points }

-- | Mirror stroke around Y axis (negate X coordinates).
-- |
-- | Useful for creating symmetric patterns or correcting
-- | strokes drawn in the wrong horizontal direction.
mirrorStrokeY :: Number -> Stroke -> Stroke
mirrorStrokeY centerX stroke =
  let
    mirrorPoint :: StrokePoint -> StrokePoint
    mirrorPoint p =
      let
        -- Distance from center
        distFromCenter = p.x - centerX
        -- Negate the distance to mirror
        newX = centerX + negate distFromCenter
      in
        p { x = newX }
  in
    stroke { points = map mirrorPoint stroke.points }

-- | Translate stroke by offset.
translateStroke :: Number -> Number -> Stroke -> Stroke
translateStroke dx dy stroke =
  let
    translatePoint :: StrokePoint -> StrokePoint
    translatePoint p = p { x = p.x + dx, y = p.y + dy }
  in
    stroke { points = map translatePoint stroke.points }

-- | Calculate velocity vector for a segment (px/ms).
-- |
-- | Returns both components which may be negative depending on direction.
segmentVelocity :: StrokeSegment -> { vx :: Number, vy :: Number }
segmentVelocity seg =
  let
    dx = seg.end.x - seg.start.x
    dy = seg.end.y - seg.start.y
    dt = seg.end.timestamp - seg.start.timestamp
  in
    if dt > 0.0
      then { vx: dx / dt, vy: dy / dt }
      else { vx: 0.0, vy: 0.0 }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // particle generation
-- ═════════════════════════════════════════════════════════════════════════════

-- | Generate positions for particle spawning along the stroke.
-- |
-- | Takes spacing (fraction of brush size) and returns positions
-- | interpolated along the stroke path.
generateParticlePositions :: Number -> Stroke -> Array Point2D
generateParticlePositions spacing s =
  let
    pts = s.points
    n = Array.length pts
    particleSpacing = s.brushSize * spacing
  in
    if n < 2
      then map (\p -> mkPoint2D p.x p.y) pts
      else
        Array.foldl (\acc i ->
          case { prev: Array.index pts i, curr: Array.index pts (i + 1) } of
            { prev: Just p1, curr: Just p2 } ->
              let
                segmentPositions = interpolatePoints p1 p2 particleSpacing
              in
                acc <> segmentPositions
            _ -> acc
        ) [] (range 0 (n - 2))

-- | Interpolate between two points at given spacing.
interpolatePoints :: StrokePoint -> StrokePoint -> Number -> Array Point2D
interpolatePoints p1 p2 spacing =
  let
    dx = p2.x - p1.x
    dy = p2.y - p1.y
    dist = Num.sqrt (dx * dx + dy * dy)
    steps = max 1 (Int.floor (dist / spacing))
    stepCount = Int.toNumber steps
  in
    map (\i ->
      let
        t = Int.toNumber i / stepCount
        x = p1.x + dx * t
        y = p1.y + dy * t
      in
        mkPoint2D x y
    ) (range 0 steps)
  where
    floor :: Number -> Int
    floor = Int.floor

-- | Data for spawning a paint particle with full interpolated properties.
-- |
-- | Unlike Point2D which only has position, ParticleSpawnData includes
-- | the interpolated pressure value, enabling realistic paint simulation
-- | where pressure affects particle size, opacity, and behavior.
type ParticleSpawnData =
  { position :: Point2D        -- ^ Spawn position
  , pressure :: Number         -- ^ Interpolated pressure (0-1)
  , tiltX :: Number            -- ^ Interpolated tilt X
  , tiltY :: Number            -- ^ Interpolated tilt Y
  }

-- | Generate full particle data including interpolated pressure.
-- |
-- | This is the primary function for particle spawning as it preserves
-- | pressure information that affects paint behavior (size, opacity, flow).
generateParticleData :: Number -> Stroke -> Array ParticleSpawnData
generateParticleData spacing stroke =
  let
    segments = computeStrokeSegments stroke
    particleSpacing = stroke.brushSize * spacing
  in
    Array.foldl (\acc seg ->
      acc <> interpolatePointsWithPressure seg.start seg.end particleSpacing
    ) [] segments

-- | Interpolate between two points, preserving pressure.
-- |
-- | Uses linear interpolation for both position and pressure.
-- | Returns full ParticleSpawnData suitable for particle spawning.
interpolatePointsWithPressure :: StrokePoint -> StrokePoint -> Number -> Array ParticleSpawnData
interpolatePointsWithPressure p1 p2 spacing =
  let
    dx = p2.x - p1.x
    dy = p2.y - p1.y
    dPressure = p2.pressure - p1.pressure
    dTiltX = p2.tiltX - p1.tiltX
    dTiltY = p2.tiltY - p1.tiltY
    dist = Num.sqrt (dx * dx + dy * dy)
    steps = max 1 (Int.floor (dist / spacing))
    stepCount = Int.toNumber steps
  in
    map (\i ->
      let
        t = Int.toNumber i / stepCount
        x = p1.x + dx * t
        y = p1.y + dy * t
        pressure = p1.pressure + dPressure * t
        tiltX = p1.tiltX + dTiltX * t
        tiltY = p1.tiltY + dTiltY * t
      in
        { position: mkPoint2D x y
        , pressure: pressure
        , tiltX: tiltX
        , tiltY: tiltY
        }
    ) (range 0 steps)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                                    // display
-- ═════════════════════════════════════════════════════════════════════════════

-- | Display stroke info.
displayStroke :: Stroke -> String
displayStroke s =
  "Stroke[" <> show (unwrapStrokeId s.id) <> "] " <>
  show (strokePointCount s) <> " points, " <>
  "length=" <> show (strokeLength s) <> "px, " <>
  (if s.active then "active" else "complete")

-- | Display stroke point.
displayStrokePoint :: StrokePoint -> String
displayStrokePoint p =
  "(" <> show p.x <> ", " <> show p.y <> ") " <>
  "p=" <> show p.pressure <> " " <>
  "t=" <> show p.timestamp <> "ms"

-- | Display stroke segment.
displayStrokeSegment :: StrokeSegment -> String
displayStrokeSegment seg =
  "Segment[" <>
  "(" <> show seg.start.x <> "," <> show seg.start.y <> ")" <>
  " -> " <>
  "(" <> show seg.end.x <> "," <> show seg.end.y <> ")" <>
  "] len=" <> show (segmentLength seg) <>
  " avgP=" <> show (segmentAveragePressure seg)

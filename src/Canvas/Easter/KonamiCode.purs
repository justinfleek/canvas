-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                               // canvas // easter // konami
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Konami Code Easter Egg
-- |
-- | Detects the classic Konami code sequence: ↑↑↓↓←→←→BA
-- | Triggers a confetti explosion when the sequence is completed.
-- |
-- | ## Usage
-- |
-- | ```purescript
-- | import Canvas.Easter.KonamiCode as Konami
-- |
-- | -- In your update function:
-- | OnKeyDown key ->
-- |   let konamiState = Konami.processKey key state.konamiState
-- |   in if Konami.isTriggered konamiState
-- |      then triggerConfetti state { konamiState = Konami.reset konamiState }
-- |      else noCmd state { konamiState = konamiState }
-- | ```
-- |
-- | ## The Sequence
-- |
-- | ```
-- | ↑ ↑ ↓ ↓ ← → ← → B A
-- | ```
-- |
-- | Originally from Contra (1988) - grants 30 extra lives!

module Canvas.Easter.KonamiCode
  ( -- * State
    KonamiState
  , initialState
  , reset
  
  -- * Processing
  , processKey
  , processKeyCode
  
  -- * Queries
  , isTriggered
  , progress
  , progressPercent
  , currentIndex
  
  -- * Constants
  , konamiSequence
  , sequenceLength
  ) where

import Prelude
  ( class Eq
  , class Show
  , show
  , (+)
  , (-)
  , (==)
  , (>=)
  , (/)
  , (*)
  , (<>)
  , (||)
  )

import Data.Array (index, length)
import Data.Maybe (Maybe(Just, Nothing))
import Data.Int (toNumber)

-- ═════════════════════════════════════════════════════════════════════════════
--                                                           // konami // state
-- ═════════════════════════════════════════════════════════════════════════════

-- | State for tracking Konami code input
type KonamiState =
  { index :: Int          -- ^ Current position in sequence (0-9)
  , triggered :: Boolean  -- ^ Has the full sequence been entered?
  , lastKeyTime :: Number -- ^ Timestamp of last key (for timeout)
  }

-- | Initial state (no keys pressed)
initialState :: KonamiState
initialState =
  { index: 0
  , triggered: false
  , lastKeyTime: 0.0
  }

-- | Reset after triggering or timeout
reset :: KonamiState -> KonamiState
reset _ = initialState

-- ═════════════════════════════════════════════════════════════════════════════
--                                                        // konami // sequence
-- ═════════════════════════════════════════════════════════════════════════════

-- | The Konami code key sequence
-- |
-- | ↑ ↑ ↓ ↓ ← → ← → B A
-- |
-- | Using standard DOM KeyboardEvent key values
konamiSequence :: Array String
konamiSequence =
  [ "ArrowUp"
  , "ArrowUp"
  , "ArrowDown"
  , "ArrowDown"
  , "ArrowLeft"
  , "ArrowRight"
  , "ArrowLeft"
  , "ArrowRight"
  , "b"
  , "a"
  ]

-- | Length of the sequence (10 keys)
sequenceLength :: Int
sequenceLength = length konamiSequence

-- ═════════════════════════════════════════════════════════════════════════════
--                                                      // konami // processing
-- ═════════════════════════════════════════════════════════════════════════════

-- | Process a key press event
-- |
-- | Takes the key value from a KeyboardEvent (e.key or e.code)
-- | Updates the state based on whether it matches the next expected key.
processKey :: String -> KonamiState -> KonamiState
processKey key state =
  -- If already triggered, stay triggered until reset
  if state.triggered
    then state
    else checkKey key state

-- | Process using key code (alternative for case-insensitive matching)
processKeyCode :: String -> KonamiState -> KonamiState
processKeyCode keyCode state =
  -- Convert common key codes to key values
  let key = keyCodeToKey keyCode
  in processKey key state

-- | Check if key matches next expected key
checkKey :: String -> KonamiState -> KonamiState
checkKey key state =
  case index konamiSequence state.index of
    Nothing -> 
      -- Past the end (shouldn't happen)
      state
    
    Just expectedKey ->
      if keyMatches key expectedKey
        then advanceSequence state
        else resetIfWrong key state

-- | Advance to next position in sequence
advanceSequence :: KonamiState -> KonamiState
advanceSequence state =
  let newIndex = state.index + 1
  in if newIndex >= sequenceLength
     then state { index = newIndex, triggered = true }
     else state { index = newIndex }

-- | Reset if wrong key, unless it's the start of a new sequence
resetIfWrong :: String -> KonamiState -> KonamiState
resetIfWrong key state =
  -- Check if this key starts a new sequence
  case index konamiSequence 0 of
    Just firstKey ->
      if keyMatches key firstKey
        then state { index = 1 }  -- Start fresh at position 1
        else state { index = 0 }  -- Full reset
    Nothing -> 
      state { index = 0 }

-- | Case-insensitive key matching
keyMatches :: String -> String -> Boolean
keyMatches input expected =
  input == expected || toLowerCase input == toLowerCase expected

-- | Convert key code to key value
keyCodeToKey :: String -> String
keyCodeToKey code = case code of
  "KeyA" -> "a"
  "KeyB" -> "b"
  "ArrowUp" -> "ArrowUp"
  "ArrowDown" -> "ArrowDown"
  "ArrowLeft" -> "ArrowLeft"
  "ArrowRight" -> "ArrowRight"
  _ -> code

-- | Simple lowercase for ASCII letters
toLowerCase :: String -> String
toLowerCase s = case s of
  "A" -> "a"
  "B" -> "b"
  _ -> s

-- ═════════════════════════════════════════════════════════════════════════════
--                                                         // konami // queries
-- ═════════════════════════════════════════════════════════════════════════════

-- | Has the Konami code been triggered?
isTriggered :: KonamiState -> Boolean
isTriggered state = state.triggered

-- | How many keys have been matched so far?
progress :: KonamiState -> Int
progress state = state.index

-- | Progress as a percentage (0.0 to 1.0)
progressPercent :: KonamiState -> Number
progressPercent state =
  toNumber state.index / toNumber sequenceLength

-- | Current index in sequence (for debugging/display)
currentIndex :: KonamiState -> Int
currentIndex state = state.index

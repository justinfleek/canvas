-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                        // canvas // easter
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- | Canvas Easter Eggs — Hidden delights for users to discover
-- |
-- | ## Available Easter Eggs
-- |
-- | 1. **Konami Code** (↑↑↓↓←→←→BA) — Triggers confetti explosion
-- | 2. **Shake to Clear** — Shake device to clear canvas etch-a-sketch style
-- |
-- | ## Integration
-- |
-- | Add to your app state:
-- |
-- | ```purescript
-- | type AppState =
-- |   { -- ... other fields
-- |   , easterEggs :: Easter.EasterEggState
-- |   }
-- | ```
-- |
-- | Handle events:
-- |
-- | ```purescript
-- | update msg state = case msg of
-- |   KeyDown key ->
-- |     let newEE = Easter.processKey key state.easterEggs
-- |     in handleEasterEggTriggers newEE state
-- |   DeviceMotion motion ->
-- |     let newEE = Easter.processMotion motion state.easterEggs
-- |     in handleEasterEggTriggers newEE state
-- | ```

module Canvas.Easter
  ( -- * Unified State
    EasterEggState
  , initialState
  , reset
  
  -- * Event Processing
  , processKey
  , processMotion
  
  -- * Trigger Queries
  , konamiTriggered
  , shakeTriggered
  , anyTriggered
  
  -- * Confetti Integration
  , updateConfetti
  , renderConfetti
  , triggerConfetti
  , isConfettiActive
  
  -- * Sub-module Re-exports
  , module Canvas.Easter.KonamiCode
  , module Canvas.Easter.ShakeDetector
  , module Canvas.Easter.Confetti
  ) where

import Prelude
  ( (||)
  )

import Hydrogen.Render.Element (Element)

import Canvas.Easter.KonamiCode as Konami
import Canvas.Easter.KonamiCode 
  ( KonamiState
  , konamiSequence
  , sequenceLength
  )

import Canvas.Easter.ShakeDetector as Shake
import Canvas.Easter.ShakeDetector 
  ( ShakeState
  , ShakeConfig
  , defaultConfig
  )

import Canvas.Easter.Confetti as Confetti
import Canvas.Easter.Confetti 
  ( ConfettiState
  , ConfettiConfig
  , ConfettiParticle
  )

-- ═════════════════════════════════════════════════════════════════════════════
--                                                      // easter egg // state
-- ═════════════════════════════════════════════════════════════════════════════

-- | Combined state for all easter eggs
type EasterEggState =
  { konami :: Konami.KonamiState
  , shake :: Shake.ShakeState
  , confetti :: Confetti.ConfettiState
  }

-- | Initial state with all easter eggs ready to detect
initialState :: EasterEggState
initialState =
  { konami: Konami.initialState
  , shake: Shake.initialState
  , confetti: Confetti.noConfetti
  }

-- | Reset all easter egg states (after handling triggers)
reset :: EasterEggState -> EasterEggState
reset state =
  { konami: Konami.reset state.konami
  , shake: Shake.reset state.shake
  , confetti: state.confetti  -- Don't reset confetti, let it play out
  }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                    // event // processing
-- ═════════════════════════════════════════════════════════════════════════════

-- | Process a keyboard event
processKey :: String -> EasterEggState -> EasterEggState
processKey key state =
  state { konami = Konami.processKey key state.konami }

-- | Process a device motion event
processMotion 
  :: { accelerationX :: Number
     , accelerationY :: Number
     , accelerationZ :: Number
     , timestamp :: Number
     }
  -> EasterEggState 
  -> EasterEggState
processMotion motion state =
  state { shake = Shake.processMotion motion state.shake }

-- ═════════════════════════════════════════════════════════════════════════════
--                                                     // trigger // queries
-- ═════════════════════════════════════════════════════════════════════════════

-- | Was Konami code triggered?
konamiTriggered :: EasterEggState -> Boolean
konamiTriggered state = Konami.isTriggered state.konami

-- | Was shake triggered?
shakeTriggered :: EasterEggState -> Boolean
shakeTriggered state = Shake.isTriggered state.shake

-- | Was any easter egg triggered?
anyTriggered :: EasterEggState -> Boolean
anyTriggered state = konamiTriggered state || shakeTriggered state

-- ═════════════════════════════════════════════════════════════════════════════
--                                                   // confetti // integration
-- ═════════════════════════════════════════════════════════════════════════════

-- | Update confetti animation (call each frame)
updateConfetti :: Number -> EasterEggState -> EasterEggState
updateConfetti dt state =
  state { confetti = Confetti.update dt state.confetti }

-- | Render confetti particles
renderConfetti :: forall msg. EasterEggState -> Element msg
renderConfetti state = Confetti.render state.confetti

-- | Trigger confetti explosion at position
triggerConfetti :: Number -> Number -> EasterEggState -> EasterEggState
triggerConfetti x y state =
  state { confetti = Confetti.explodeAt x y Confetti.defaultConfig }

-- | Is confetti currently active?
isConfettiActive :: EasterEggState -> Boolean
isConfettiActive state = Confetti.isActive state.confetti

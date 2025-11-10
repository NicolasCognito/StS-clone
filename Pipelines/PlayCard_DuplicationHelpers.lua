-- PLAY CARD DUPLICATION HELPERS
-- Centralized logic for all card duplication mechanics
--
-- Duplication sources (in priority order):
-- 1. Duplication Potion - next N cards (any type)
-- 2. Double Tap - next N Attacks
-- 3. Burst - next N Skills
-- 4. Amplify - next N Powers
-- 5. Echo Form - first N cards each turn (any type)
-- 6. Necronomicon - first Attack each turn that costs 2+
--
-- All sources tracked in player.status:
--   - doubleTap: counter (consumed when used)
--   - burst: counter (consumed when used)
--   - amplify: counter (consumed when used)
--   - duplicationPotion: counter (consumed when used)
--   - echoFormThisTurn: counter (reset each turn based on Echo Form power stacks)
--   - necronomiconThisTurn: boolean flag (reset each turn)

local DuplicationHelpers = {}

local Utils = require("utils")

-- CHECK IF CARD SHOULD BE PLAYED AGAIN
-- Called after each card execution to determine if duplication applies
-- Returns: (shouldReplay: boolean, sourceName: string or nil)
--
-- Priority order ensures most specific effects trigger first:
-- 1. Duplication Potion (any card)
-- 2. Type-specific effects (Double Tap/Burst/Amplify)
-- 3. Echo Form (any card, turn-limited)
-- 4. Necronomicon (cost-limited, turn-limited)
function DuplicationHelpers.shouldBePlayedAgain(world, player, card)
    player.status = player.status or {}

    -- PRIORITY 1: Duplication Potion (any card)
    if player.status.duplicationPotion and player.status.duplicationPotion > 0 then
        player.status.duplicationPotion = player.status.duplicationPotion - 1
        return true, "Duplication Potion"
    end

    -- PRIORITY 2: Type-specific effects

    -- Double Tap (Attacks only)
    if card.type == "ATTACK" and player.status.doubleTap and player.status.doubleTap > 0 then
        player.status.doubleTap = player.status.doubleTap - 1
        return true, "Double Tap"
    end

    -- Burst (Skills only)
    if card.type == "SKILL" and player.status.burst and player.status.burst > 0 then
        player.status.burst = player.status.burst - 1
        return true, "Burst"
    end

    -- Amplify (Powers only)
    if card.type == "POWER" and player.status.amplify and player.status.amplify > 0 then
        player.status.amplify = player.status.amplify - 1
        return true, "Amplify"
    end

    -- PRIORITY 3: Echo Form (any card, first N cards each turn)
    if player.status.echoFormThisTurn and player.status.echoFormThisTurn > 0 then
        player.status.echoFormThisTurn = player.status.echoFormThisTurn - 1
        return true, "Echo Form"
    end

    -- PRIORITY 4: Necronomicon (Attacks costing 2+, once per turn)
    if card.type == "ATTACK"
        and card.costWhenPlayed
        and card.costWhenPlayed >= 2
        and Utils.hasRelic(player, "Necronomicon")
        and not player.status.necronomiconThisTurn then

        player.status.necronomiconThisTurn = true
        return true, "Necronomicon"
    end

    -- No duplication sources apply
    return false, nil
end

return DuplicationHelpers

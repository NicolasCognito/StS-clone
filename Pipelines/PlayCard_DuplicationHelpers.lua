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

local function ensureStatus(player)
    player.status = player.status or {}
    return player.status
end

-- BUILD REPLAY PLAN
-- Returns an ordered array of source names that should replay the card once each.
-- Sources are consumed immediately to make sequencing deterministic.
function DuplicationHelpers.buildReplayPlan(world, player, card)
    local plan = {}
    local status = ensureStatus(player)

    -- Forced replays are queued externally and should always run first
    if card._forcedReplays and #card._forcedReplays > 0 then
        for _, sourceName in ipairs(card._forcedReplays) do
            table.insert(plan, sourceName or "Forced Replay")
        end
        card._forcedReplays = nil
    end

    -- Helper to append a source name to the plan
    local function add(sourceName)
        table.insert(plan, sourceName)
    end

    -- PRIORITY 1: Duplication Potion (any card, one trigger per stack)
    if status.duplicationPotion and status.duplicationPotion > 0 then
        status.duplicationPotion = status.duplicationPotion - 1
        add("Duplication Potion")
    end

    -- PRIORITY 2: Type-specific effects

    -- Double Tap (Attacks only)
    if card.type == "ATTACK" and status.doubleTap and status.doubleTap > 0 then
        status.doubleTap = status.doubleTap - 1
        add("Double Tap")
    end

    -- Burst (Skills only)
    if card.type == "SKILL" and status.burst and status.burst > 0 then
        status.burst = status.burst - 1
        add("Burst")
    end

    -- Amplify (Powers only)
    if card.type == "POWER" and status.amplify and status.amplify > 0 then
        status.amplify = status.amplify - 1
        add("Amplify")
    end

    -- PRIORITY 3: Echo Form (any card, first N cards each turn)
    if status.echoFormThisTurn and status.echoFormThisTurn > 0 and not card._echoFormApplied then
        status.echoFormThisTurn = status.echoFormThisTurn - 1
        card._echoFormApplied = true
        add("Echo Form")
    end

    -- PRIORITY 4: Necronomicon (Attacks costing 2+, once per turn)
    if card.type == "ATTACK"
        and card.costWhenPlayed
        and card.costWhenPlayed >= 2
        and Utils.hasRelic(player, "Necronomicon")
        and not status.necronomiconThisTurn then

        status.necronomiconThisTurn = true
        add("Necronomicon")
    end

    return plan
end

return DuplicationHelpers

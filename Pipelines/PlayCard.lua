-- PLAY CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card from hand to play
-- target: target of the card (can be nil for cards without targets)
--
-- Handles:
-- - Pay energy cost
-- - Call card.onPlay to generate events
-- - Process effect queue
-- - Remove card from hand
-- - Add to discard pile (or exhaust if Corruption + Skill)
-- - Combat logging

local PlayCard = {}

local ProcessEffectQueue = require("Pipelines.ProcessEffectQueue")
local GetCost = require("Pipelines.GetCost")

-- Helper to check if player has a power
local function hasPower(player, powerId)
    if not player.powers then return false end
    for _, power in ipairs(player.powers) do
        if power.id == powerId then
            return true
        end
    end
    return false
end

function PlayCard.execute(world, player, card, target)
    -- Get the current cost of the card (allows for dynamic cost calculation)
    local cardCost = GetCost.execute(world, player, card)

    -- Check if player has enough energy
    if player.energy < cardCost then
        table.insert(world.log, "Not enough energy to play " .. card.name)
        return false
    end

    -- Check if card requires a target but none provided
    if card.Targeted == 1 and not target then
        table.insert(world.log, "Card " .. card.name .. " requires a target")
        return false
    end

    -- Pay energy cost
    player.energy = player.energy - cardCost
    table.insert(world.log, player.id .. " played " .. card.name .. " (cost: " .. cardCost .. ")")

    -- Call card's onPlay function to push events to queue
    if card.onPlay then
        card:onPlay(world, player, target)
    end

    -- Process all events from the queue
    ProcessEffectQueue.execute(world)

    -- Determine where card goes after being played
    -- Corruption: Skills are exhausted
    if hasPower(player, "Corruption") and card.type == "SKILL" then
        card.state = "EXHAUSTED_PILE"
        table.insert(world.log, card.name .. " was exhausted (Corruption)")
    else
        card.state = "DISCARD_PILE"
    end

    return true
end

return PlayCard

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
-- - Add to discard pile
-- - Combat logging

local PlayCard = {}

local ProcessEffectQueue = require("Pipelines.ProcessEffectQueue")
local GetCost = require("Pipelines.GetCost")

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

    -- Remove card from hand and add to discard
    for i, handCard in ipairs(player.hand) do
        if handCard == card then
            table.remove(player.hand, i)
            break
        end
    end
    table.insert(player.discard, card)

    return true
end

return PlayCard

-- ACQUIRE CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- cardTemplate: the card template to create a copy from
-- tags: optional array of tags (e.g., {"costsZeroThisTurn"})
--
-- Handles:
-- - Create a copy of the card template
-- - Apply tags to the card (costsZeroThisTurn, etc.)
-- - Add card to player's hand (state = HAND)
-- - Add to player.cards[] table
-- - Combat logging
--
-- This is the centralized place for acquiring new cards mid-combat
-- Used by: Infernal Blade, White Noise, Distraction, potions, etc.

local AcquireCard = {}

local Utils = require("utils")

function AcquireCard.execute(world, player, cardTemplate, tags)
    tags = tags or {}

    -- Create a copy of the card template
    local newCard = {}
    for k, v in pairs(cardTemplate) do
        newCard[k] = v
    end

    -- Set initial state to HAND
    newCard.state = "HAND"

    -- Apply tags
    if Utils.hasTag(tags, "costsZeroThisTurn") then
        newCard.costsZeroThisTurn = 1
    end

    -- Add to player's cards table
    table.insert(player.cards, newCard)

    -- Log
    local costInfo = newCard.costsZeroThisTurn == 1 and " (costs 0 this turn)" or ""
    table.insert(world.log, "Added " .. newCard.name .. " to hand" .. costInfo)

    return newCard
end

return AcquireCard

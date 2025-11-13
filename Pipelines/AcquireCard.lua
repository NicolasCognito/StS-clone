-- ACQUIRE CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- cardTemplate: the card template to create a copy from
-- tags: optional array of tags (e.g., {"costsZeroThisTurn"})
-- targetDeck: optional - "combat" or "master" (defaults to "combat" if in combat, "master" otherwise)
--
-- Handles:
-- - Create a copy of the card template
-- - Apply tags to the card (costsZeroThisTurn, etc.)
-- - Add to appropriate deck:
--   - combatDeck: temporary cards during combat (potions, Infernal Blade, etc.)
--   - masterDeck: permanent cards (card rewards, shop purchases, etc.)
-- - Combat logging
--
-- This is the centralized place for acquiring new cards
-- Used by: Infernal Blade, White Noise, Distraction, potions, card rewards, etc.

local AcquireCard = {}

local Utils = require("utils")

function AcquireCard.execute(world, player, cardTemplate, tags, targetDeck)
    tags = tags or {}

    -- Create a copy of the card template
    local newCard = {}
    for k, v in pairs(cardTemplate) do
        newCard[k] = v
    end

    -- Check for Master Reality power: auto-upgrade created cards
    if Utils.hasPower(player, "MasterReality") then
        if not newCard.upgraded and type(newCard.onUpgrade) == "function" then
            newCard:onUpgrade()
            newCard.upgraded = true
        end
    end

    -- Determine target deck: default to combat if in combat, otherwise master
    local inCombat = player.combatDeck ~= nil
    if not targetDeck then
        targetDeck = inCombat and "combat" or "master"
    end

    -- Add to appropriate deck
    if targetDeck == "combat" and inCombat then
        -- Add to combatDeck (temporary, only exists during combat)
        newCard.state = "HAND"

        -- Apply tags
        if Utils.hasTag(tags, "costsZeroThisTurn") then
            newCard.costsZeroThisTurn = 1
        end

        table.insert(player.combatDeck, newCard)

        -- Log
        local costInfo = newCard.costsZeroThisTurn == 1 and " (costs 0 this turn)" or ""
        table.insert(world.log, "Added " .. newCard.name .. " to hand" .. costInfo)
    else
        -- Add to masterDeck (permanent)
        -- Don't set state or apply combat tags for master deck
        table.insert(player.masterDeck, newCard)

        -- Log (different message for master deck)
        if world.log then
            table.insert(world.log, "Added " .. newCard.name .. " to deck")
        end
    end

    return newCard
end

return AcquireCard

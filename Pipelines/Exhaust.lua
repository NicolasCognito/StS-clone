-- EXHAUST PIPELINE
-- world: the complete game state
-- event: event with card to exhaust
--
-- Event should have:
-- - card: the card to exhaust
-- - source: optional source (e.g., "Corruption", "SelfExhaust", etc.)
--
-- Handles:
-- - Strange Spoon (50% chance to not exhaust - INDEPENDENT per card!)
-- - Move card to EXHAUSTED_PILE state
-- - Combat logging
-- - Trigger exhaust-related effects (Dead Branch, Dark Embrace, Feel No Pain)
--
-- This is the centralized place for all exhaust mechanics

local Exhaust = {}
local Utils = require("utils")

function Exhaust.execute(world, event)
    local card = event.card
    local source = event.source or "Exhaust"
    local player = world.player

    -- Strange Spoon: 50% chance to prevent exhaust (INDEPENDENT roll per card, including shadows!)
    if Utils.hasRelic(player, "Strange_Spoon") and math.random() < 0.5 then
        local cardName = card.isShadow and card.originalCardName or card.name
        table.insert(world.log, "Strange Spoon saved " .. cardName .. " from being exhausted!")

        -- Move to discard instead of exhaust
        if not card.isShadow then
            card.state = "DISCARD_PILE"  -- Real card goes to real discard pile
        else
            card.state = "DISCARD_PILE"  -- Shadow marked as discarded (not in combatDeck)
        end

        return  -- Card not exhausted
    end

    -- Move card to exhausted pile
    if not card.isShadow then
        card.state = "EXHAUSTED_PILE"  -- Real card goes to real exhausted pile
    else
        card.state = "EXHAUSTED_PILE"  -- Shadow marked as exhausted (not in combatDeck)
    end

    -- Log
    local cardName = card.isShadow and card.originalCardName or card.name
    local sourceInfo = source ~= "Exhaust" and (" (" .. source .. ")") or ""
    table.insert(world.log, cardName .. " was exhausted" .. sourceInfo)

    -- Trigger card's onExhaust hook (if it has one)
    if card.onExhaust then
        card:onExhaust(world, player)
    end

    -- TODO: Trigger exhaust-related relics
    -- - Dead Branch: Add random card to hand
    -- - Dark Embrace: Draw a card
    -- - Feel No Pain: Gain block
end

return Exhaust

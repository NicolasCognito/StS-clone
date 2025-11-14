-- EXHAUST PIPELINE
-- world: the complete game state
-- event: event with card to exhaust
--
-- Event should have:
-- - card: the card to exhaust
-- - source: optional source (e.g., "Corruption", "SelfExhaust", etc.)
--
-- Handles:
-- - Move card to EXHAUSTED_PILE state
-- - Combat logging
-- - Future: Trigger exhaust-related effects
--   - Dead Branch (add random card when you exhaust)
--   - Dark Embrace (draw card when you exhaust)
--   - Feel No Pain (gain block when you exhaust)
--   - Strange Spoon (50% chance to not exhaust)
--
-- This is the centralized place for all exhaust mechanics

local Exhaust = {}

function Exhaust.execute(world, event)
    local card = event.card
    local source = event.source or "Exhaust"

    -- Strange Spoon: Check if this self-exhausting card was saved
    -- Tag is set in PlayCard.lua when currentExecutingCard is created
    -- Only self-exhausting cards (card.exhausts = true) get the tag
    if world.combat and world.combat.currentExecutingCard and world.combat.currentExecutingCard.affectedBySpoon then
        -- Card saved! Send to discard pile instead of exhausting
        card.state = "DISCARD_PILE"
        table.insert(world.log, card.name .. " saved by Strange Spoon! (not exhausted)")

        -- Return early - skip exhaust hooks (Dead Branch, Dark Embrace, etc.)
        return
    end

    -- Move card to exhausted pile
    card.state = "EXHAUSTED_PILE"

    -- Log
    local sourceInfo = source ~= "Exhaust" and (" (" .. source .. ")") or ""
    table.insert(world.log, card.name .. " was exhausted" .. sourceInfo)

    -- TODO: Trigger exhaust-related powers/relics
    -- - Dead Branch: Add random card to hand
    -- - Dark Embrace: Draw a card
    -- - Feel No Pain: Gain block
end

return Exhaust

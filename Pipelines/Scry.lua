-- SCRY PIPELINE
-- world: the complete game state
-- event: the scry event (no additional parameters needed)
--
-- Handles:
-- - Move cards from tempContext to discard pile
-- - Combat logging
--
-- Usage Pattern (in card onPlay):
-- 1. Push COLLECT_CONTEXT with scry parameter (shows top N deck cards)
-- 2. Push ON_SCRY (moves selected cards to discard)
--
-- Example:
--   world.queue:push({
--       type = "COLLECT_CONTEXT",
--       card = self,
--       contextProvider = {
--           type = "cards",
--           stability = "temp",
--           scry = 3,  -- Show top 3 cards
--           count = {min = 0, max = 3}  -- Can discard 0-3
--       }
--   }, "FIRST")
--   world.queue:push({type = "ON_SCRY"})

local Scry = {}
local Utils = require("utils")

function Scry.execute(world, event)
    local cardsToDiscard = world.combat.tempContext or {}

    if #cardsToDiscard == 0 then
        table.insert(world.log, "No cards discarded from scry")
    else
        -- Move selected cards to discard pile
        for _, card in ipairs(cardsToDiscard) do
            card.state = "DISCARD_PILE"
            table.insert(world.log, "Scried: " .. card.name .. " discarded")
        end
    end

    -- After any Scry action, return Weave cards from discard pile if possible
    local player = world.player
    if not player or not player.combatDeck then
        return
    end

    local maxHandSize = player.maxHandSize or 10
    local currentHandSize = Utils.getCardCountByState(player.combatDeck, "HAND")

    for _, card in ipairs(player.combatDeck) do
        if card.id == "Weave" and card.state == "DISCARD_PILE" then
            if currentHandSize < maxHandSize then
                card.state = "HAND"
                currentHandSize = currentHandSize + 1
                table.insert(world.log, "Weave returns to hand after scrying")
            else
                break  -- Hand is full; stop returning additional Weaves
            end
        end
    end
end

return Scry

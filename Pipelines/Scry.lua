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

function Scry.execute(world, event)
    local cardsToDiscard = world.combat.tempContext or {}

    if #cardsToDiscard == 0 then
        table.insert(world.log, "No cards discarded from scry")
        return
    end

    -- Move selected cards to discard pile
    for _, card in ipairs(cardsToDiscard) do
        card.state = "DISCARD_PILE"
        table.insert(world.log, "Scried: " .. card.name .. " discarded")
    end
end

return Scry

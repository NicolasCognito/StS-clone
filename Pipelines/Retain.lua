-- RETAIN PIPELINE
-- Processes ON_RETAIN events from the queue
--
-- Event should have:
-- - card: the card that was retained
-- - player: the player who retained the card
--
-- Handles:
-- - Calling card.onRetained hook (if present)
-- - Logging retention effects
-- - Future: Relic hooks for retention-reactive effects
--
-- This pipeline is called at end of turn for each card that stays in hand
-- (has retain = true or player has Runic Pyramid)

local Retain = {}

function Retain.execute(world, event)
    local card = event.card
    local player = event.player

    -- Validate event has required fields
    if not card or not player then
        table.insert(world.log, "ERROR: ON_RETAIN event missing card or player")
        return
    end

    -- Call card's onRetained hook if it exists
    if card.onRetained then
        card:onRetained(world, player)
    end

    -- Future: Relic hooks for retention-reactive effects
    -- for _, relic in ipairs(player.relics) do
    --     if relic.onCardRetained then
    --         relic:onCardRetained(world, player, card)
    --     end
    -- end
end

return Retain

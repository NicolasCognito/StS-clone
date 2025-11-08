-- END TURN PIPELINE
-- world: the complete game state
-- player: the player whose turn is ending
--
-- Handles:
-- - Trigger relics' onEndCombat effects
-- - Process effect queue
-- - Discard remaining hand
-- - Reset energy
-- - Combat logging

local EndTurn = {}

local ProcessEffectQueue = require("Pipelines.ProcessEffectQueue")

function EndTurn.execute(world, player)
    table.insert(world.log, "--- End of Player Turn ---")

    -- Trigger all relics' onEndCombat effects
    for _, relic in ipairs(player.relics) do
        if relic.onEndCombat then
            relic:onEndCombat(world, player)
        end
    end

    -- Process all queued events from relics
    ProcessEffectQueue.execute(world)

    -- Discard remaining hand
    for _, card in ipairs(player.hand) do
        table.insert(player.discard, card)
    end
    player.hand = {}

    -- Reset energy for next turn
    player.energy = player.maxEnergy

    table.insert(world.log, player.id .. " ended turn")
end

return EndTurn

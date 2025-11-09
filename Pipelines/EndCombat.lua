-- END COMBAT PIPELINE
-- world: the complete game state
-- victory: boolean indicating if player won
--
-- Handles:
-- - Update persistent HP
-- - Remove card states
-- - Clear combat-specific player state
-- - Clear enemies
-- - Remove combat context (queue, log, counters)
-- - Handle rewards (future)
-- - Apply relic end-of-combat effects (future)

local EndCombat = {}

function EndCombat.execute(world, victory)
    -- Update persistent HP from combat HP
    world.player.currentHp = world.player.hp

    -- Remove card states (cards go back to templates)
    for _, card in ipairs(world.player.cards) do
        card.state = nil
    end

    -- Clear combat-specific player state
    world.player.block = 0
    world.player.status = nil
    world.player.powers = nil

    -- Clear enemies
    world.enemies = nil

    -- Apply relic end-of-combat effects
    for _, relic in ipairs(world.player.relics) do
        if relic.onCombatEnd then
            relic:onCombatEnd(world, victory)
        end
    end

    -- Remove combat context
    world.combat = nil
    world.queue = nil
    world.log = nil

    -- TODO: Handle rewards if victory
    -- TODO: Handle death if not victory
end

return EndCombat

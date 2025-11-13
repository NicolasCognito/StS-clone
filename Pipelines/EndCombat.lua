-- END COMBAT PIPELINE
-- Cleans up combat-only context and persists results back onto the world

local EndCombat = {}

function EndCombat.execute(world, victory)
    world.player.currentHp = math.max(0, math.min(world.player.hp, world.player.maxHp))

    -- Discard combatDeck (it was a temporary copy for combat only)
    -- The masterDeck remains unchanged and persists outside combat
    world.player.combatDeck = nil

    world.player.block = 0
    world.player.status = nil

    world.enemies = nil

    for _, relic in ipairs(world.player.relics or {}) do
        if relic.onCombatEnd then
            relic:onCombatEnd(world, victory)
        end
    end

    world.combat = nil
    world.queue = nil
    world.log = nil
end

return EndCombat


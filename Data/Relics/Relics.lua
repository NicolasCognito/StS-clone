-- RELICS DATA
-- Relic definitions with their effects
-- Each relic has:
-- - Data parameters (healAmount, triggerFlags, etc)
-- - onEndCombat: pushes event to queue at end of combat

local Relics = {
    BurningBlood = {
        id = "Burning_Blood",
        name = "Burning Blood",
        rarity = "STARTER",
        description = "At the end of combat, heal 6 HP.",
        healAmount = 6,

        onEndCombat = function(self, world, player)
            world.queue:push({
                type = "ON_HEAL",
                target = player,
                relic = self
            })
        end
    }
}

return Relics

-- MIRACLE
-- Watcher Special Skill
-- Cost: 0. Gain 1 Energy. Retain. Exhaust.
-- This is a generated card (from Deus Ex Machina, etc.)

return {
    Miracle = {
        id = "Miracle",
        name = "Miracle",
        cost = 0,
        type = "SKILL",
        character = "WATCHER",
        rarity = "SPECIAL",
        retain = 1,
        exhausts = true,
        upgraded = false,
        description = "Gain 1 Energy. Retain. Exhaust.",

        onPlay = function(self, world, player)
            -- Gain 1 energy
            player.energy = player.energy + 1
            table.insert(world.log, player.id .. " gained 1 energy from Miracle")
        end,

        onUpgrade = function(self)
            -- Miracle doesn't upgrade in the base game, but we include the function
            self.upgraded = true
        end
    }
}

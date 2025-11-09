return {
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

return {
    StrengthPotion = {
        id = "StrengthPotion",
        name = "Strength Potion",
        description = "Gain 2 Strength.",

        onUse = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "strength",
                amount = 2,
                source = self
            })
        end
    }
}

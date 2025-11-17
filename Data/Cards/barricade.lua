return {
    Barricade = {
        id = "Barricade",
        name = "Barricade",
        cost = 3,
        type = "POWER",
        character = "IRONCLAD",
        rarity = "RARE",
        description = "Block is not removed at the start of your turn.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "barricade",
                amount = 1,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.cost = 2
            self.description = "Block is not removed at the start of your turn."
        end
    }
}

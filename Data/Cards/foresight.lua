return {
    Foresight = {
        id = "Foresight",
        name = "Foresight",
        cost = 1,
        type = "POWER",
        character = "WATCHER",
        rarity = "UNCOMMON",
        scryAmount = 3,
        description = "At the start of your turn, Scry 3.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "foresight",
                amount = self.scryAmount
            })
        end,

        onUpgrade = function(self)
            self.scryAmount = 4
            self.description = "At the start of your turn, Scry 4."
        end
    }
}

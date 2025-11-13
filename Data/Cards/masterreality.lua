return {
    MasterReality = {
        id = "MasterReality",
        name = "Master Reality",
        cost = 1,
        type = "POWER",
        character = "WATCHER",
        rarity = "RARE",
        description = "Whenever a card is created during combat, Upgrade it.",

        onPlay = function(self, world, player)
            local Powers = require("Data.powers")
            world.queue:push({
                type = "ON_APPLY_POWER",
                target = player,
                powerTemplate = Powers.MasterReality
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Whenever a card is created during combat, Upgrade it."
        end
    }
}

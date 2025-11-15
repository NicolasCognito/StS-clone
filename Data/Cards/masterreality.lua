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
            -- Apply Master Reality status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "master_reality",
                amount = 1
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Whenever a card is created during combat, Upgrade it."
        end
    }
}

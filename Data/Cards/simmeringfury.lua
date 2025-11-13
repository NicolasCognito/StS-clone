return {
    SimmeringFury = {
        id = "SimmeringFury",
        name = "Simmering Fury",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "At the start of your next turn, enter Wrath and draw 2 cards.",

        onPlay = function(self, world, player)
            -- Set simmering_fury status
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "simmering_fury",
                amount = 1
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "At the start of your next turn, enter Wrath and draw 2 cards."
            self.upgraded = true
        end
    }
}

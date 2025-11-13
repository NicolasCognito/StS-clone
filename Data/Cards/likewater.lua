return {
    LikeWater = {
        id = "LikeWater",
        name = "Like Water",
        cost = 1,
        type = "POWER",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "At the end of your turn, if you are in Calm, gain 5 Block.",
        blockGain = 5,

        onPlay = function(self, world, player)
            -- Apply Like Water status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "like_water",
                amount = self.blockGain
            })
        end,

        onUpgrade = function(self)
            self.blockGain = 7
            self.description = "At the end of your turn, if you are in Calm, gain 7 Block."
            self.upgraded = true
        end
    }
}

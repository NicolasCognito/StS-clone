return {
    MentalFortress = {
        id = "MentalFortress",
        name = "Mental Fortress",
        cost = 1,
        type = "POWER",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Whenever you change your stance, gain 4 Block.",
        blockGain = 4,

        onPlay = function(self, world, player, target)
            -- Apply Mental Fortress status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "Mental Fortress",
                amount = self.blockGain
            })
        end,

        onUpgrade = function(self)
            self.blockGain = 6
            self.description = "Whenever you change your stance, gain 6 Block."
            self.upgraded = true
        end
    }
}

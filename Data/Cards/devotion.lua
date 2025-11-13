return {
    Devotion = {
        id = "Devotion",
        name = "Devotion",
        cost = 1,
        type = "POWER",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "At the start of your turn, gain 2 Mantra.",
        mantra = 2,

        onPlay = function(self, world, player)
            -- Apply Devotion status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "devotion",
                amount = self.mantra
            })
        end,

        onUpgrade = function(self)
            self.mantra = 3
            self.description = "At the start of your turn, gain 3 Mantra."
            self.upgraded = true
        end
    }
}

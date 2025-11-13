return {
    Worship = {
        id = "Worship",
        name = "Worship",
        cost = 2,
        type = "SKILL",
        character = "WATCHER",
        rarity = "COMMON",
        description = "Gain 5 Mantra. Retain.",
        mantra = 5,
        retain = true,

        onPlay = function(self, world, player)
            -- Gain mantra
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "mantra",
                amount = self.mantra
            })
        end,

        onUpgrade = function(self)
            self.cost = 1
            self.description = "Gain 5 Mantra. Retain."
            self.upgraded = true
        end
    }
}

return {
    Prostrate = {
        id = "Prostrate",
        name = "Prostrate",
        cost = 0,
        type = "SKILL",
        character = "WATCHER",
        rarity = "COMMON",
        description = "Gain 4 Mantra. Gain 2 Block.",
        mantra = 4,
        block = 2,

        onPlay = function(self, world, player)
            -- Gain mantra
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "mantra",
                amount = self.mantra
            })

            -- Gain block
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = self.block,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.mantra = 5
            self.block = 3
            self.description = "Gain 5 Mantra. Gain 3 Block."
            self.upgraded = true
        end
    }
}

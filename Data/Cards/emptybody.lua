return {
    EmptyBody = {
        id = "EmptyBody",
        name = "Empty Body",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "COMMON",
        description = "Gain 7 Block. Exit your stance.",
        block = 7,

        onPlay = function(self, world, player)
            -- Gain block
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = self.block
            })

            -- Exit stance (set to nil for neutral)
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = nil
            })
        end,

        onUpgrade = function(self)
            self.block = 10
            self.description = "Gain 10 Block. Exit your stance."
            self.upgraded = true
        end
    }
}

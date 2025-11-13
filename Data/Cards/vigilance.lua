return {
    Vigilance = {
        id = "Vigilance",
        name = "Vigilance",
        cost = 2,
        type = "SKILL",
        character = "WATCHER",
        rarity = "STARTER",
        description = "Gain 8 Block. Enter Calm.",
        block = 8,

        onPlay = function(self, world, player)
            -- Gain block
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = self.block
            })

            -- Enter Calm stance
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Calm"
            })
        end,

        onUpgrade = function(self)
            self.block = 12
            self.description = "Gain 12 Block. Enter Calm."
            self.upgraded = true
        end
    }
}

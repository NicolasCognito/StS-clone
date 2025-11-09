return {
    Defend = {
        id = "Defend",
        name = "Defend",
        cost = 1,
        type = "SKILL",
        block = 5,
        Targeted = 0,
        description = "Gain 5 block.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.block = 8
            self.description = "Gain 8 block."
        end
    }
}

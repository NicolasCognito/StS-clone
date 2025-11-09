return {
    FlameBarrier = {
        id = "Flame_Barrier",
        name = "Flame Barrier",
        cost = 2,
        type = "SKILL",
        block = 12,
        thorns = 4,
        description = "Gain 12 block. Gain 4 Thorns.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                card = self
            })
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "Thorns",
                amount = self.thorns,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.block = 16
            self.thorns = 6
            self.description = "Gain 16 block. Gain 6 Thorns."
        end
    }
}

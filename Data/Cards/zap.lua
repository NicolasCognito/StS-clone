return {
    Zap = {
        id = "Zap",
        name = "Zap",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "STARTER",
        description = "Channel 1 Lightning.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_CHANNEL_ORB",
                orbType = "Lightning"
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Channel 1 Lightning. (Cost reduced)"
        end
    }
}

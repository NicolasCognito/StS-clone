return {
    Charge = {
        id = "Charge",
        name = "Charge",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "COMMON",
        description = "Channel 1 Plasma.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_CHANNEL_ORB",
                orbType = "Plasma"
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Channel 1 Plasma. (Cost reduced)"
        end
    }
}

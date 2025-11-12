return {
    Darkness = {
        id = "Darkness",
        name = "Darkness",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        description = "Channel 1 Dark.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_CHANNEL_ORB",
                orbType = "Dark"
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Channel 1 Dark. (Cost reduced)"
        end
    }
}

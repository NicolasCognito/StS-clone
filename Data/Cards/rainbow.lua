-- RAINBOW
-- Skill: Channel 1 Lightning, 1 Frost, 1 Dark. Exhaust.
return {
    Rainbow = {
        id = "Rainbow",
        name = "Rainbow",
        cost = 2,
        type = "SKILL",
        character = "DEFECT",
        rarity = "RARE",
        upgraded = false,
        exhausts = true,
        description = "Channel 1 Lightning, 1 Frost, 1 Dark. Exhaust.",

        onPlay = function(self, world, player)
            world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Lightning"})
            world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Frost"})
            world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Dark"})
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.exhausts = false
            self.description = "Channel 1 Lightning, 1 Frost, 1 Dark."
        end
    }
}

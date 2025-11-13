-- GLACIER
-- Skill: Gain 7 Block. Channel 2 Frost.
return {
    Glacier = {
        id = "Glacier",
        name = "Glacier",
        cost = 2,
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        block = 7,
        upgraded = false,
        description = "Gain 7 Block. Channel 2 Frost.",

        onPlay = function(self, world, player)
            -- Gain block
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = self.block
            })

            -- Channel Frost orbs
            for i = 1, 2 do
                world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Frost"})
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.block = 10
            self.description = "Gain 10 Block. Channel 2 Frost."
        end
    }
}

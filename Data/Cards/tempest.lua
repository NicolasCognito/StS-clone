-- TEMPEST
-- Skill (X-cost): Channel X Lightning. Exhaust.
return {
    Tempest = {
        id = "Tempest",
        name = "Tempest",
        cost = "X",
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        exhausts = true,
        description = "Channel X Lightning. Exhaust.",

        onPlay = function(self, world, player)
            local channelCount = self.energySpent or 0
            if self.upgraded then
                channelCount = channelCount + 1
            end

            for i = 1, channelCount do
                world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Lightning"})
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Channel X+1 Lightning. Exhaust."
        end
    }
}

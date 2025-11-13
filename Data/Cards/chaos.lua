-- CHAOS
-- Skill: Channel 1 random Orb.
return {
    Chaos = {
        id = "Chaos",
        name = "Chaos",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Channel 1 random Orb.",

        onPlay = function(self, world, player)
            local orbTypes = {"Lightning", "Frost", "Dark", "Plasma"}
            local channelCount = self.upgraded and 2 or 1

            for i = 1, channelCount do
                local randomOrb = orbTypes[math.random(#orbTypes)]
                world.queue:push({type = "ON_CHANNEL_ORB", orbType = randomOrb})
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Channel 2 random Orbs."
        end
    }
}

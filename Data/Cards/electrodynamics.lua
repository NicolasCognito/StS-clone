-- ELECTRODYNAMICS
-- Power: Lightning Orbs hit ALL enemies. Channel 2 Lightning.
return {
    Electrodynamics = {
        id = "Electrodynamics",
        name = "Electrodynamics",
        cost = 2,
        type = "POWER",
        character = "DEFECT",
        rarity = "RARE",
        upgraded = false,
        description = "Lightning Orbs now hit ALL enemies. Channel 2 Lightning.",

        onPlay = function(self, world, player)
            -- Apply Electrodynamics status effect
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "electrodynamics",
                amount = 1
            })

            -- Channel Lightning orbs
            local channelCount = self.upgraded and 3 or 2
            for i = 1, channelCount do
                world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Lightning"})
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Lightning Orbs now hit ALL enemies. Channel 3 Lightning."
        end
    }
}

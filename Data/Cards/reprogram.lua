-- REPROGRAM
-- Skill: Lose 1 Focus. Gain 1 Strength. Gain 1 Dexterity.
return {
    Reprogram = {
        id = "Reprogram",
        name = "Reprogram",
        cost = 1,
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Lose 1 Focus. Gain 1 Strength. Gain 1 Dexterity.",

        onPlay = function(self, world, player)
            local statGain = self.upgraded and 2 or 1

            -- Lose Focus
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "focus",
                amount = -statGain
            })

            -- Gain Strength
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "strength",
                amount = statGain
            })

            -- Gain Dexterity
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "dexterity",
                amount = statGain
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Lose 2 Focus. Gain 2 Strength. Gain 2 Dexterity."
        end
    }
}

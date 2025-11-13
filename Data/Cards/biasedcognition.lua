-- BIASED COGNITION
-- Power: Gain 4 Focus. At the start of each turn, lose 1 Focus.
return {
    BiasedCognition = {
        id = "Biased_Cognition",
        name = "Biased Cognition",
        cost = 1,
        type = "POWER",
        character = "DEFECT",
        rarity = "RARE",
        upgraded = false,
        description = "Gain 4 Focus. At the start of each turn, lose 1 Focus.",

        onPlay = function(self, world, player)
            local focusGain = self.upgraded and 5 or 4

            -- Gain Focus
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "focus",
                amount = focusGain
            })

            -- Apply Bias debuff (loses 1 Focus per turn)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "bias",
                amount = 1  -- Intensity: 1 bias = lose 1 Focus per turn
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Gain 5 Focus. At the start of each turn, lose 1 Focus."
        end
    }
}

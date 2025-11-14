-- Normality (Curse)
-- You cannot play more than 3 cards this turn.

return {
    Normality = {
        id = "Normality",
        name = "Normality",
        cost = -2,  -- Unplayable
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        description = "Unplayable. You cannot play more than 3 cards this turn.",

        -- Unplayable flag
        isPlayable = function(self, world, player)
            return false, "Normality is unplayable"
        end
    }
}

-- Clumsy (Curse)
-- Unplayable. Ethereal.

return {
    Clumsy = {
        id = "Clumsy",
        name = "Clumsy",
        cost = -2,  -- Unplayable
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        ethereal = true,
        description = "Unplayable. Ethereal. (Discarded at end of turn.)",

        -- Unplayable flag
        isPlayable = function(self, world, player)
            return false, "Clumsy is unplayable"
        end
    }
}

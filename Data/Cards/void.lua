-- Void (Status)
-- Unplayable. Ethereal.
-- Status card added by certain enemies (Awakened One's Sludge attack)

return {
    Void = {
        id = "Void",
        name = "Void",
        cost = -2,  -- Unplayable
        type = "STATUS",
        character = "COLORLESS",
        rarity = "COMMON",
        unplayable = true,
        ethereal = true,
        description = "Unplayable. Ethereal.",

        -- No onPlay function - this card cannot be played
        -- Ethereal means it's removed at end of turn if in hand (handled by EndTurn pipeline)
    }
}

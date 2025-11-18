-- Dazed (Status)
-- Unplayable. Ethereal.
-- Status card added by certain enemies (Chosen, Sentry, Repulsor, Deca, Corrupt Heart)

return {
    Dazed = {
        id = "Dazed",
        name = "Dazed",
        cost = -2,  -- Unplayable
        type = "STATUS",
        character = "COLORLESS",
        rarity = "COMMON",
        unplayable = true,
        ethereal = true,
        description = "Unplayable. Ethereal.",

        -- No onPlay function - this card cannot be played
        -- No onUpgrade function - status cards (except Burn) don't upgrade
        -- Ethereal means it's removed at end of turn if in hand (handled by EndTurn pipeline)
    }
}

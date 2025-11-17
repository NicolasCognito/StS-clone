return {
    Wound = {
        id = "Wound",
        name = "Wound",
        cost = -2,  -- Unplayable
        type = "STATUS",
        character = "COLORLESS",
        rarity = "COMMON",
        unplayable = true,
        description = "Unplayable.",

        -- No onPlay function - this card cannot be played
        -- No onUpgrade function - status cards don't upgrade
    }
}

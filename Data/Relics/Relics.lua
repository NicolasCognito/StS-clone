-- RELICS DATA
-- Relic definitions with their effects

local Relics = {
    BurningBlood = {
        id = "Burning_Blood",
        name = "Burning Blood",
        rarity = "STARTER",
        description = "At the end of combat, heal 6 HP.",

        -- Effect trigger point: will be handled in EndTurn or PostCombat
        -- When added, this relic pushes an ON_RELIC_EFFECT event or similar
        onEndCombat = true,
        healAmount = 6
    }
}

return Relics

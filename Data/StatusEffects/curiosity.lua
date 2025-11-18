-- CURIOSITY STATUS EFFECT
-- Used by Awakened One boss in Phase 1
-- Whenever the player plays a Power card, this enemy gains Strength

return {
    curiosity = {
        id = "curiosity",
        name = "Curiosity",
        description = "Gains Strength when you play Power cards.",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",  -- More stacks = more Strength per Power
        debuff = false,

        -- This effect is checked in AfterCardPlayed pipeline
        -- When player plays a Power card, the enemy with Curiosity gains Strength
        -- The amount is equal to the Curiosity stacks
    }
}

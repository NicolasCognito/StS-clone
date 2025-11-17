-- INVINCIBLE STATUS EFFECT
-- Caps all damage and HP loss taken per turn
-- Works with invincible_max status which stores the cap value and restores this at turn start
return {
    invincible = {
        id = "invincible",
        name = "Invincible",
        description = "Damage and HP loss taken this turn is capped at this amount.",
        minValue = 0,
        maxValue = 9999,
        stackType = "intensity",
        debuff = false,

        -- NOTE: Restoration logic is in invincible_max.onStartTurn
        -- This status tracks the remaining damage cap for the current turn
        -- Gets reduced as damage is taken during damage pipelines
    }
}

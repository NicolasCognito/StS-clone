-- VIGOR STATUS EFFECT
return {
    vigor = {
        id = "vigor",
        name = "Vigor",
        description = "Your next Attack deals this much additional damage.",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
        -- Note: Vigor does NOT expire at end of turn
        -- It is only consumed after playing an Attack (handled in AfterCardPlayed.lua)
    }
}

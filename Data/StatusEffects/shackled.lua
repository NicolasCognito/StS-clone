-- SHACKLED STATUS EFFECT
return {
    shackled = {

        id = "shackled",
        name = "Shackled",
        description = "Gain that much Strength at start of turn, then remove",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true
    ,

    onStartTurn = function(world, target)
        -- Applied in StartTurn pipeline, then removed
        -- This hook is called but the logic is handled in StartTurn
        -- (queues ON_STATUS_GAIN for Strength)
    end
    }
}

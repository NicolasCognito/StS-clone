-- BLUR STATUS EFFECT
return {
    blur = {

        id = "blur",
        name = "Blur",
        description = "Block is not removed at start of turn",
        minValue = 0,
        maxValue = 1,  -- Binary effect
        stackType = "intensity",
        debuff = false,
        goesDownOnRoundEnd = true,
        roundEndMode = "WoreOff"
    
    }
}

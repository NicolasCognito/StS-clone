-- BLOCK_RETURN STATUS EFFECT
return {
    block_return = {

        id = "block_return",
        name = "Block Return",
        description = "When you deal attack damage, the target gains Block",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "WoreOff"
    
    }
}

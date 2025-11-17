-- NO_BLOCK STATUS EFFECT
return {
    no_block = {

        id = "no_block",
        name = "No Block",
        description = "Cannot gain Block",
        minValue = 0,
        maxValue = 1,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    
    }
}

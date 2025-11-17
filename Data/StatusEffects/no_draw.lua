-- NO_DRAW STATUS EFFECT
return {
    no_draw = {

        id = "no_draw",
        name = "No Draw",
        description = "Cannot draw cards this turn",
        minValue = 0,
        maxValue = 1,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    
    }
}

-- FRAIL STATUS EFFECT
return {
    frail = {

        id = "frail",
        name = "Frail",
        description = "Gain 25% less block from cards",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    
    }
}

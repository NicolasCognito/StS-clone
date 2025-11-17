-- SLOW STATUS EFFECT
return {
    slow = {

        id = "slow",
        name = "Slow",
        description = "Take 10% more attack damage per stack this turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "WoreOff"
    
    }
}

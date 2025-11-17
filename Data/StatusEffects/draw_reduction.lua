-- DRAW_REDUCTION STATUS EFFECT
return {
    draw_reduction = {

        id = "draw_reduction",
        name = "Draw Reduction",
        description = "Draw fewer cards next draw phase",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "WoreOff"
    
    }
}

-- DOUBLE_DAMAGE STATUS EFFECT
return {
    double_damage = {

        id = "double_damage",
        name = "Double Damage",
        description = "Your Attacks deal double damage this turn. Decreases by 1 at end of round.",
        minValue = 0,
        maxValue = 99,
        stackType = "duration",
        debuff = false,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    
    }
}

-- LOCK_ON STATUS EFFECT
return {
    lock_on = {

        id = "lock_on",
        name = "Lock-On",
        description = "Orbs deal 50% more damage to this target",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    
    }
}

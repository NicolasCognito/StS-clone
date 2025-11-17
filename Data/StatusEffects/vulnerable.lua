-- VULNERABLE STATUS EFFECT
return {
    vulnerable = {
        id = "vulnerable",
        name = "Vulnerable",
        description = "Take 50% more damage from attacks (75% with Paper Phrog)",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown"
    }
}

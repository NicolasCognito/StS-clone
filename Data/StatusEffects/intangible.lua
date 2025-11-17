-- INTANGIBLE STATUS EFFECT
return {
    intangible = {
        id = "intangible",
        name = "Intangible",
        description = "Damage received is reduced to 1",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = false,
        goesDownOnRoundEnd = true,
        roundEndMode = "TickDown",

        onStartTurn = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            Utils.Decrement(target, "intangible", 1)
            local remaining = target.status.intangible or 0
            Utils.log(world, targetName .. "'s Intangible decreased to " .. remaining)
        end
    }
}

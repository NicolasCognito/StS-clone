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

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.vulnerable and target.status.vulnerable > 0 then
                Utils.Decrement(target, "vulnerable", 1)
                local remaining = target.status.vulnerable or 0
                Utils.log(world, targetName .. "'s Vulnerable decreased to " .. remaining)
            end
        end
    }
}

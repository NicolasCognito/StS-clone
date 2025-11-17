-- WEAK STATUS EFFECT
return {
    weak = {
        id = "weak",
        name = "Weak",
        description = "Deal 25% less damage with attacks",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.weak and target.status.weak > 0 then
                Utils.Decrement(target, "weak", 1)
                local remaining = target.status.weak or 0
                Utils.log(world, targetName .. "'s Weak decreased to " .. remaining)
            end
        end
    }
}

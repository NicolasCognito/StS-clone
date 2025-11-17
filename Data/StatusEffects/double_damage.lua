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

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.double_damage and target.status.double_damage > 0 then
                Utils.Decrement(target, "double_damage", 1)
                local remaining = target.status.double_damage or 0
                Utils.log(world, targetName .. "'s Double Damage decreased to " .. remaining)
            end
        end
    }
}

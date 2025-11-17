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

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.lock_on and target.status.lock_on > 0 then
                Utils.Decrement(target, "lock_on", 1)
                local remaining = target.status.lock_on or 0
                Utils.log(world, targetName .. "'s Lock-On decreased to " .. remaining)
            end
        end
    }
}

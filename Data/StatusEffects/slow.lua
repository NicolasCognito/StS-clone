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

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.slow and target.status.slow > 0 then
                Utils.WoreOff(target, "slow")
                Utils.log(world, targetName .. "'s Slow wore off")
            end
        end
    }
}

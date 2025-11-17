-- BLUR STATUS EFFECT
return {
    blur = {
        id = "blur",
        name = "Blur",
        description = "Block is not removed at start of turn",
        minValue = 0,
        maxValue = 1,
        stackType = "intensity",
        debuff = false,

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.blur and target.status.blur > 0 then
                Utils.WoreOff(target, "blur")
                Utils.log(world, targetName .. "'s Blur wore off")
            end
        end
    }
}

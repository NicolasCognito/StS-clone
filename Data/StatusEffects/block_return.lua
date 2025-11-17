-- BLOCK_RETURN STATUS EFFECT
return {
    block_return = {
        id = "block_return",
        name = "Block Return",
        description = "When you deal attack damage, the target gains Block",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.block_return and target.status.block_return > 0 then
                Utils.WoreOff(target, "block_return")
                Utils.log(world, targetName .. "'s Block Return wore off")
            end
        end
    }
}

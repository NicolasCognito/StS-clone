-- NO_BLOCK STATUS EFFECT
return {
    no_block = {
        id = "no_block",
        name = "No Block",
        description = "Cannot gain Block",
        minValue = 0,
        maxValue = 1,
        stackType = "duration",
        debuff = true,

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.no_block and target.status.no_block > 0 then
                Utils.Decrement(target, "no_block", 1)
                local remaining = target.status.no_block or 0
                Utils.log(world, targetName .. "'s No Block decreased to " .. remaining)
            end
        end
    }
}

-- NO_DRAW STATUS EFFECT
return {
    no_draw = {
        id = "no_draw",
        name = "No Draw",
        description = "Cannot draw cards this turn",
        minValue = 0,
        maxValue = 1,
        stackType = "duration",
        debuff = true,

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.no_draw and target.status.no_draw > 0 then
                Utils.Decrement(target, "no_draw", 1)
                local remaining = target.status.no_draw or 0
                Utils.log(world, targetName .. "'s No Draw decreased to " .. remaining)
            end
        end
    }
}

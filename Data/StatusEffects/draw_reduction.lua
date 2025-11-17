-- DRAW_REDUCTION STATUS EFFECT
return {
    draw_reduction = {
        id = "draw_reduction",
        name = "Draw Reduction",
        description = "Draw fewer cards next draw phase",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.draw_reduction and target.status.draw_reduction > 0 then
                Utils.WoreOff(target, "draw_reduction")
                Utils.log(world, targetName .. "'s Draw Reduction wore off")
            end
        end
    }
}

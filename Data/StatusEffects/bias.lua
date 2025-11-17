-- BIAS STATUS EFFECT
return {
    bias = {

        id = "bias",
        name = "Bias",
        description = "Lose 1 Focus each turn",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true
    ,

    onStartTurn = function(world, target)
        local Utils = require("utils")
        local playerName = target.name or target.id or "Target"
        local amount = target.status.bias
        if amount and amount > 0 then
            target.status.focus = (target.status.focus or 0) - amount
            Utils.log(world, playerName .. " lost " .. amount .. " Focus from Bias")
        end
    end
    }
}

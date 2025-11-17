-- FASTING STATUS EFFECT
return {
    fasting = {

        id = "fasting",
        name = "Fasting",
        description = "Lose 1 energy at start of turn per stack",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    ,

    onStartTurn = function(world, target)
        local Utils = require("utils")
        local playerName = target.name or target.id or "Target"
        local amount = target.status.fasting
        if amount and amount > 0 then
            local penalty = math.min(amount, target.energy)
            if penalty > 0 then
                target.energy = target.energy - penalty
                Utils.log(world, playerName .. " lost " .. penalty .. " energy to Fasting")
            end
        end
    end
    }
}

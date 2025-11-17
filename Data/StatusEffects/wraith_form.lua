-- WRAITH_FORM STATUS EFFECT
return {
    wraith_form = {

        id = "wraith_form",
        name = "Wraith Form",
        description = "Lose 1 Dexterity at end of turn per stack",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true
    ,

    onStartTurn = function(world, target)
        local Utils = require("utils")
        local playerName = target.name or target.id or "Target"
        local amount = target.status.wraith_form
        if amount and amount > 0 then
            target.status.dexterity = (target.status.dexterity or 0) - amount
            Utils.log(world, playerName .. " lost " .. amount .. " Dexterity from Wraith Form")
        end
    end
    }
}

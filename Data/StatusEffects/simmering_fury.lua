-- SIMMERING_FURY STATUS EFFECT
return {
    simmering_fury = {

        id = "simmering_fury",
        name = "Simmering Fury",
        description = "At the start of your next turn, enter Wrath and draw 2 cards",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    ,

    onStartTurn = function(world, target)
        local Utils = require("utils")
        local amount = target.status.simmering_fury
        if amount and amount > 0 then
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Wrath"
            })

            for i = 1, 2 do
                world.queue:push({type = "ON_DRAW"})
            end

            Utils.WoreOff(target, "simmering_fury")
        end
    end
    }
}

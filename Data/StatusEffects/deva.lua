-- DEVA STATUS EFFECT
return {
    deva = {

        id = "deva",
        name = "Deva Form",
        description = "At the start of your turn, gain Energy equal to stacks",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    ,

    onStartTurn = function(world, target)
        local Utils = require("utils")
        local playerName = target.name or target.id or "Target"
        local energyGain = target.status.deva
        if energyGain and energyGain > 0 then
            target.energy = target.energy + energyGain
            Utils.log(world, playerName .. " gained " .. energyGain .. " energy from Deva Form")

            local growth = target.status.deva_growth or 0
            if growth > 0 then
                target.status.deva = target.status.deva + growth
                Utils.log(world, playerName .. "'s Deva Form energy gain increased to " .. target.status.deva)
            end
        end
    end
    }
}

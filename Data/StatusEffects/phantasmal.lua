-- PHANTASMAL STATUS EFFECT
return {
    phantasmal = {

        id = "phantasmal",
        name = "Phantasmal",
        description = "At the start of your next turn, gain that many stacks of Double Damage",
        minValue = 0,
        maxValue = 99,
        stackType = "intensity",
        debuff = false
    ,

    onStartTurn = function(world, target)
        local Utils = require("utils")
        local playerName = target.name or target.id or "Target"
        local stacks = target.status.phantasmal
        if stacks and stacks > 0 then
            target.status.double_damage = (target.status.double_damage or 0) + stacks
            Utils.WoreOff(target, "phantasmal")
            Utils.log(world, playerName .. " gains " .. stacks .. " Double Damage from Phantasmal!")
        end
    end
    }
}

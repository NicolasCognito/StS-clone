-- CONSTRICTED STATUS EFFECT
return {
    constricted = {

        id = "constricted",
        name = "Constricted",
        description = "Take damage at end of turn equal to stacks",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    ,

    onEndTurn = function(world, target)
        local Utils = require("utils")
        local playerName = target.name or target.id or "Target"
        local amount = target.status.constricted
        if amount and amount > 0 then
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = "Constricted",
                target = target,
                amount = amount,
                tags = {"constricted"}
            })
            Utils.log(world, playerName .. " takes " .. amount .. " damage from Constricted")
        end
    end
    }
}

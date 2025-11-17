-- POISON STATUS EFFECT
return {
    poison = {

        id = "poison",
        name = "Poison",
        description = "Lose HP at the end of turn, then reduce by 1",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = true
    ,

    onEndTurn = function(world, target)
        local Utils = require("utils")
        local playerName = target.name or target.id or "Target"
        local amount = target.status.poison
        if amount and amount > 0 then
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = "Poison",
                target = target,
                amount = amount,
                tags = {"poison"}
            })
            Utils.log(world, playerName .. " takes " .. amount .. " damage from Poison")
            Utils.Decrement(target, "poison", 1)
        end
    end
    }
}

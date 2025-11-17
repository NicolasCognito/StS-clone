-- PLATED_ARMOR STATUS EFFECT
return {
    plated_armor = {

        id = "plated_armor",
        name = "Plated Armor",
        description = "Gain block at end of turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    ,

    onEndTurn = function(world, target)
        local amount = target.status.plated_armor
        if amount and amount > 0 then
            world.queue:push({
                type = "ON_BLOCK",
                target = target,
                amount = amount,
                source = "Plated Armor"
            })
        end
    end
    }
}

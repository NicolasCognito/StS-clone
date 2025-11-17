-- REGENERATION STATUS EFFECT
return {
    regeneration = {

        id = "regeneration",
        name = "Regeneration",
        description = "Heal HP at end of turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    ,

    onEndTurn = function(world, target)
        local amount = target.status.regeneration
        if amount and amount > 0 then
            world.queue:push({
                type = "ON_HEAL",
                target = target,
                amount = amount,
                source = "Regeneration"
            })
        end
    end
    }
}

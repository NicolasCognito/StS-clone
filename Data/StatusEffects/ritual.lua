-- RITUAL STATUS EFFECT
return {
    ritual = {

        id = "ritual",
        name = "Ritual",
        description = "Gain strength at end of turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    ,

    onEndTurn = function(world, target)
        local amount = target.status.ritual
        if amount and amount > 0 then
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = target,
                effectType = "Strength",
                amount = amount,
                source = "Ritual"
            })
        end
    end
    }
}

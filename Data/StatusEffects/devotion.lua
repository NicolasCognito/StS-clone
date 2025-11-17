-- DEVOTION STATUS EFFECT
return {
    devotion = {

        id = "devotion",
        name = "Devotion",
        description = "At the start of your turn, gain Mantra equal to stacks",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    ,

    onStartTurn = function(world, target)
        local amount = target.status.devotion
        if amount and amount > 0 then
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = target,
                effectType = "mantra",
                amount = amount
            })
        end
    end
    }
}

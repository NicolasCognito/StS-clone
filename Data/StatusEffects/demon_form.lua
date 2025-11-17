-- DEMON_FORM STATUS EFFECT
return {
    demon_form = {

        id = "demon_form",
        name = "Demon Form",
        description = "At the start of your turn, gain Strength equal to stacks.",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    ,

    onStartTurn = function(world, target)
        local amount = target.status.demon_form
        if amount and amount > 0 then
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = target,
                effectType = "Strength",
                amount = amount,
                source = "Demon Form"
            })
        end
    end
    }
}

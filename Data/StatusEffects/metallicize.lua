-- METALLICIZE STATUS EFFECT
return {
    metallicize = {

        id = "metallicize",
        name = "Metallicize",
        description = "Gain block at end of turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false
    ,

    onEndTurn = function(world, target)
        local amount = target.status.metallicize
        if amount and amount > 0 then
            world.queue:push({
                type = "ON_BLOCK",
                target = target,
                amount = amount,
                source = "Metallicize"
            })
        end
    end
    }
}

-- FRAIL STATUS EFFECT
return {
    frail = {
        id = "frail",
        name = "Frail",
        description = "Gain 25% less block from cards",
        minValue = 0,
        maxValue = 999,
        stackType = "duration",
        debuff = true,

        onEndRound = function(world, target)
            local Utils = require("utils")
            local targetName = target.name or target.id or "Target"
            if target.status.frail and target.status.frail > 0 then
                Utils.Decrement(target, "frail", 1)
                local remaining = target.status.frail or 0
                Utils.log(world, targetName .. "'s Frail decreased to " .. remaining)
            end
        end
    }
}

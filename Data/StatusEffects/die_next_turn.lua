-- DIE_NEXT_TURN STATUS EFFECT
return {
    die_next_turn = {

        id = "die_next_turn",
        name = "Die Next Turn",
        description = "At the start of your next turn, take 9999 damage (from Blasphemy)",
        minValue = 0,
        maxValue = 1,  -- Non-stackable
        stackType = "intensity",  -- Non-degrading
        debuff = false  -- It's a "buff" in terms of game mechanics (positive for player strategy)
    ,

    onStartTurn = function(world, target)
        local Utils = require("utils")
        local playerName = target.name or target.id or "Target"
        Utils.log(world, playerName .. " takes 9999 damage from Blasphemy!")

        world.queue:push({
            type = "ON_NON_ATTACK_DAMAGE",
            source = "Blasphemy",
            target = target,
            amount = 9999,
            tags = {"ignoreBlock"}
        })

        -- Remove the status after triggering
        Utils.WoreOff(target, "die_next_turn")
    end
    }
}

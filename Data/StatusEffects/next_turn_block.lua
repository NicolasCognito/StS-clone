-- NEXT TURN BLOCK STATUS EFFECT
-- Accumulates block to be granted at the start of next turn
-- Used by Self-Forming Clay and potentially other effects
return {
    next_turn_block = {
        id = "next_turn_block",
        name = "Next Turn Block",
        description = "Gain this much Block at the start of next turn",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",  -- Stacks add up
        debuff = false,

        onStartTurn = function(world, target)
            local amount = target.status.next_turn_block
            if amount and amount > 0 then
                world.queue:push({
                    type = "ON_BLOCK",
                    target = target,
                    amount = amount,
                    source = "Deferred Block"
                })
                -- Clear after granting
                target.status.next_turn_block = 0
            end
        end
    }
}

-- TIME_WARP STATUS EFFECT
-- Counter starts at 12, decrements by 1 each time player plays a card
-- When it reaches 0: end player's turn, grant +2 Strength to Time Eater, reset to 12
return {
    time_warp = {

        id = "time_warp",
        name = "Time Warp",
        description = "When you play 12 cards in a single turn, end your turn and gain 2 Strength.",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false,

        onApply = function(world, target, amount, source)
            -- Check if counter has reached 0 or below
            if target.status.time_warp <= 0 then
                -- Grant +2 Strength to the Time Warp owner (Time Eater)
                world.queue:push({
                    type = "ON_STATUS_GAIN",
                    target = target,
                    effectType = "strength",
                    amount = 2,
                    source = "Time Warp"
                })

                -- Reset Time Warp counter to 12
                target.status.time_warp = 12
                table.insert(world.log, "Time Warp activated! Gained 2 Strength. Counter reset to 12.")

                -- Set flag for CombatEngine to end the turn
                if world.combat then
                    world.combat.timeWarpTriggered = true
                end
            end
        end

    }
}

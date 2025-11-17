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
                -- Set flag for CombatEngine to end the turn
                if world.combat then
                    world.combat.timeWarpTriggered = true
                    world.combat.timeWarpOwner = target
                end

                table.insert(world.log, "Time Warp activated! Turn ending...")
            end
        end

    }
}

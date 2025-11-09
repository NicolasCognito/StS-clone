-- AFTER CARD PLAYED PIPELINE
-- Called after a card's onPlay effect has been executed
-- Used for cleanup actions that need to happen after card effects
--
-- Handles:
-- - Pen Nib counter reset (when counter reaches trigger threshold)

local AfterCardPlayed = {}

function AfterCardPlayed.execute(world, player)
    -- Check if player has Pen Nib relic and counter has reached trigger threshold
    if player.relics then
        for _, relic in ipairs(player.relics) do
            if relic.id == "Pen_Nib" then
                -- Reset counter if it has reached the trigger threshold
                if world.penNibCounter >= relic.triggerCount then
                    world.penNibCounter = 0
                    table.insert(world.log, "Pen Nib reset!")
                end
                break
            end
        end
    end
end

return AfterCardPlayed

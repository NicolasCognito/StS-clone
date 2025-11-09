-- LOSE RELIC PIPELINE
-- world: the complete game state
-- relicId: the ID of the relic to lose
--
-- Handles:
-- - Remove relic from player.relics
-- - Special handling for Winged Boots (set world.wingedBootsCharges to 0)

local LoseRelic = {}

function LoseRelic.execute(world, relicId)
    -- Find and remove relic
    for i, relic in ipairs(world.player.relics) do
        if relic.id == relicId then
            table.remove(world.player.relics, i)

            -- Special handling for Winged Boots
            if relicId == "Winged_Boots" then
                world.wingedBootsCharges = 0
                print("Lost " .. relic.name .. " (charges reset to 0)")
            else
                print("Lost " .. relic.name)
            end
            return true
        end
    end

    print("Relic not found: " .. relicId)
    return false
end

return LoseRelic

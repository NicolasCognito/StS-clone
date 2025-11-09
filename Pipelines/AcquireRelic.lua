-- ACQUIRE RELIC PIPELINE
-- world: the complete game state
-- relic: the relic template to acquire
--
-- Handles:
-- - Add relic to player.relics
-- - Special handling for Winged Boots (set world.wingedBootsCharges)

local AcquireRelic = {}

function AcquireRelic.execute(world, relic)
    -- Add relic to player's collection
    table.insert(world.player.relics, relic)

    -- Special handling for Winged Boots
    if relic.id == "Winged_Boots" and relic.charges then
        world.wingedBootsCharges = relic.charges
        print("Acquired " .. relic.name .. " (" .. relic.charges .. " charges)")
    else
        print("Acquired " .. relic.name)
    end
end

return AcquireRelic

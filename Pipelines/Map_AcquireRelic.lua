-- MAP ACQUIRE RELIC PIPELINE
-- Adds a relic to the player's collection and handles overworld bookkeeping

local Map_AcquireRelic = {}

function Map_AcquireRelic.execute(world, relic)
    table.insert(world.player.relics, relic)

    if relic.id == "Winged_Boots" and relic.charges then
        world.wingedBootsCharges = relic.charges
        print("Acquired " .. relic.name .. " (" .. relic.charges .. " charges)")
    else
        print("Acquired " .. relic.name)
    end
end

return Map_AcquireRelic

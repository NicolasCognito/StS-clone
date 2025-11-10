-- MAP LOSE RELIC PIPELINE
-- Removes a relic from the player's inventory and resets related state

local Map_LoseRelic = {}

function Map_LoseRelic.execute(world, relicId)
    for i, relic in ipairs(world.player.relics) do
        if relic.id == relicId then
            table.remove(world.player.relics, i)
            if relicId == "Winged_Boots" then
                world.wingedBootsCharges = 0
                print("Lost " .. relic.name .. " (charges reset)")
            else
                print("Lost " .. relic.name)
            end
            return true
        end
    end

    print("Relic not found: " .. relicId)
    return false
end

return Map_LoseRelic

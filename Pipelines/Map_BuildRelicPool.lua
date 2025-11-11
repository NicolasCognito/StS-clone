-- MAP BUILD RELIC POOL PIPELINE
-- Provides a filtered list of relic templates for events like merchants or
-- treasure nodes.

local Relics = require("Data.relics")
local Utils = require("utils")

local Map_BuildRelicPool = {}

function Map_BuildRelicPool.execute(world, options)
    options = options or {}
    local filter = options.filter
    local excludeOwned = options.excludeOwned ~= false
    local pool = {}

    for _, relic in pairs(Relics) do
        if type(relic) == "table" and relic.id then
            local include = true
            if excludeOwned and world and world.player and Utils.hasRelic(world.player, relic.id) then
                include = false
            end
            if include and filter then
                include = filter(world, relic)
            end

            if include then
                table.insert(pool, relic)
            end
        end
    end

    return pool
end

return Map_BuildRelicPool

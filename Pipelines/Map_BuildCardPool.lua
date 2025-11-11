-- MAP BUILD CARD POOL PIPELINE
-- Returns a list of card templates filtered by optional criteria so map events
-- can construct rewards or shop inventories without reimplementing loaders.

local Cards = require("Data.cards")

local Map_BuildCardPool = {}

function Map_BuildCardPool.execute(world, options)
    options = options or {}
    local filter = options.filter
    local pool = {}

    for _, card in pairs(Cards) do
        if type(card) == "table" and card.id then
            local include = true
            if filter then
                include = filter(world, card)
            end

            if include then
                table.insert(pool, card)
            end
        end
    end

    return pool
end

return Map_BuildCardPool

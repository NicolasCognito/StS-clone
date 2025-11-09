-- WORLD STATE
-- Persistent game data (player, map, relic charges, etc.)
-- Combat-only context (queue/log/counters) is attached temporarily per encounter
-- This module intentionally stays logic-free; it should only shape state containers.

local World = {}

function World.createWorld(playerData)
    return {
        player = {
            -- Identity
            id = playerData.id or "IronClad",
            name = playerData.name or playerData.id or "IronClad",

            -- HP
            maxHp = playerData.maxHp or 80,
            currentHp = playerData.currentHp or playerData.maxHp or 80,
            hp = playerData.currentHp or playerData.maxHp or 80,
            block = 0,

            -- Energy
            energy = 3,
            maxEnergy = 3,

            -- Cards (templates, card.state assigned at combat start)
            cards = playerData.cards or {},

            -- Relics & gold
            relics = playerData.relics or {},
            gold = playerData.gold or 0,

            -- Combat-only state (status effects, powers)
            status = nil,
            powers = nil
        },

        -- Current encounter enemies (array or nil outside combat)
        enemies = nil,

        -- Map traversal metadata
        map = playerData.map or nil,
        currentNode = playerData.startNode or nil,
        floor = playerData.floor or 1,

        -- Winged Boots state (managed by AcquireRelic/LoseRelic pipelines)
        wingedBootsCharges = playerData.wingedBootsCharges or 0
    }
end

return World

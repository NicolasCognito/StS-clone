-- WORLD STATE
-- Persistent game state that carries between combats
-- Operations on world state should be done through pipelines or directly

local World = {}

-- ============================================================================
-- WORLD CREATION
-- ============================================================================
-- The 'world' object contains persistent state across the entire run:
-- - player: persistent player data (maxHp, currentHp, deck, relics, gold)
-- - currentNode: current position on the map (future)
-- - floor: current floor number (future)
--
-- This is separate from combat state which is ephemeral per encounter

function World.createWorld(playerData)
    return {
        player = {
            id = playerData.id or "IronClad",
            name = playerData.name or playerData.id or "IronClad",
            maxHp = playerData.maxHp or 80,
            currentHp = playerData.currentHp or playerData.maxHp or 80,

            -- Persistent deck (card templates without state)
            deck = playerData.deck or {},

            -- Relics
            relics = playerData.relics or {},

            -- Gold
            gold = playerData.gold or 0,
        },

        -- Map state (future)
        currentNode = nil,
        floor = 1,
    }
end

return World

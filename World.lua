-- WORLD STATE
-- All game data lives here - player, enemies, deck, map, etc.
-- Combat state only adds temporary context (queue, counters, log)

local World = {}

-- ============================================================================
-- WORLD CREATION
-- ============================================================================
-- The 'world' object contains ALL game state:
-- - player: player data (maxHp, currentHp, hp, block, energy, cards, relics, gold, status, powers)
-- - enemies: current encounter enemies (or nil if not in combat)
-- - map: the map graph structure
-- - currentNode: current position on the map
-- - floor: current floor number
--
-- Combat state is just temporary context added during combat (queue, counters, log)

function World.createWorld(playerData)
    return {
        player = {
            -- Identity
            id = playerData.id or "IronClad",
            name = playerData.name or playerData.id or "IronClad",

            -- HP
            maxHp = playerData.maxHp or 80,
            currentHp = playerData.currentHp or playerData.maxHp or 80,
            hp = playerData.currentHp or playerData.maxHp or 80,  -- Current HP in combat
            block = 0,

            -- Energy
            energy = 3,
            maxEnergy = 3,

            -- Cards (with state property during combat)
            cards = playerData.cards or {},

            -- Relics
            relics = playerData.relics or {},

            -- Gold
            gold = playerData.gold or 0,

            -- Combat state (status effects, powers)
            status = nil,  -- Initialized when needed
            powers = nil,  -- Initialized when needed
        },

        -- Enemies (current encounter, or nil if not in combat)
        enemies = nil,

        -- Map
        map = playerData.map or nil,           -- Map graph structure
        currentNode = playerData.startNode or nil,  -- Current node ID
        floor = 1,

        -- Winged Boots state
        wingedBootsCharges = 0,  -- Set to 3 if player has Winged Boots relic
    }
end

return World

-- GAME ENGINE
-- Initializes and manages game state, runs the main game loop

local EventQueue = require("Pipelines.EventQueue")

local Engine = {}

-- ============================================================================
-- GAME STATE INITIALIZATION
-- ============================================================================
-- The 'world' object passed to all pipelines contains:
-- - player: player character with hp, maxHp, block, energy, deck, hand, discard
-- - enemy: current enemy with hp, maxHp, intents
-- - queue: event queue for all actions
-- - log: combat log for debugging/display
-- - relics: player's relics list

function Engine.createGameState(playerData, enemyData)
    return {
        -- PLAYER
        player = {
            id = playerData.id or "IronClad",
            hp = playerData.hp or 80,
            maxHp = playerData.hp or 80,
            block = 0,
            energy = 3,
            maxEnergy = 3,

            deck = {},  -- all cards in deck
            hand = {},  -- cards in current hand
            discard = {},  -- discarded cards

            relics = playerData.relics or {},
        },

        -- ENEMY
        enemy = {
            id = enemyData.id,
            name = enemyData.name,
            hp = enemyData.hp,
            maxHp = enemyData.maxHp,
            description = enemyData.description,
        },

        -- EVENT QUEUE
        queue = EventQueue.new(),

        -- COMBAT LOG
        log = {}
    }
end

-- ============================================================================
-- GAME LOOP
-- ============================================================================

function Engine.init(playerData, enemyData)
    local world = Engine.createGameState(playerData, enemyData)
    return world
end

function Engine.addLogEntry(world, message)
    table.insert(world.log, message)
end

return Engine

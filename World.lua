-- WORLD STATE
-- Manages persistent game state that carries between combats
-- This includes: player stats, deck, relics, gold, map position

local World = {}

-- ============================================================================
-- WORLD CREATION
-- ============================================================================
-- The 'world' object contains persistent state across the entire run:
-- - player: persistent player data (maxHp, deck, relics, gold)
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

-- ============================================================================
-- DECK MANAGEMENT
-- ============================================================================

-- Add a card to the permanent deck
function World.addCardToDeck(world, cardTemplate)
    table.insert(world.player.deck, cardTemplate)
end

-- Remove a card from the permanent deck
function World.removeCardFromDeck(world, cardTemplate)
    for i, card in ipairs(world.player.deck) do
        if card == cardTemplate then
            table.remove(world.player.deck, i)
            return true
        end
    end
    return false
end

-- ============================================================================
-- RELIC MANAGEMENT
-- ============================================================================

-- Add a relic
function World.addRelic(world, relic)
    table.insert(world.player.relics, relic)
end

-- Check if player has a relic
function World.hasRelic(world, relicId)
    for _, relic in ipairs(world.player.relics) do
        if relic.id == relicId then
            return true
        end
    end
    return false
end

-- ============================================================================
-- HP MANAGEMENT
-- ============================================================================

-- Heal the player (persists between combats)
function World.healPlayer(world, amount)
    world.player.currentHp = math.min(world.player.currentHp + amount, world.player.maxHp)
end

-- Damage the player (persists between combats)
function World.damagePlayer(world, amount)
    world.player.currentHp = math.max(0, world.player.currentHp - amount)
end

-- Increase max HP
function World.increaseMaxHp(world, amount)
    world.player.maxHp = world.player.maxHp + amount
    world.player.currentHp = world.player.currentHp + amount
end

-- ============================================================================
-- GOLD MANAGEMENT
-- ============================================================================

function World.addGold(world, amount)
    world.player.gold = world.player.gold + amount
end

function World.removeGold(world, amount)
    world.player.gold = math.max(0, world.player.gold - amount)
end

return World

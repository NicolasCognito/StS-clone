-- Lightweight CombatEngine replacement used while the full engine is stubbed out.
-- Immediately resolves combat as a victory so other systems (map events, rewards, etc.)
-- can be developed without interactive battles.

local Utils = require("utils")

local CombatEngineStub = {}

local function ensureLog(world)
    world.log = world.log or {}
end

function CombatEngineStub.addLogEntry(world, message)
    ensureLog(world)
    table.insert(world.log, message)
end

function CombatEngineStub.getCardsByState(player, state)
    if not player or not player.combatDeck then
        return {}
    end
    return Utils.getCardsByState(player.combatDeck, state)
end

function CombatEngineStub.getCardCountByState(player, state)
    if not player or not player.combatDeck then
        return 0
    end
    return Utils.getCardCountByState(player.combatDeck, state)
end

function CombatEngineStub.displayGameState()
    print("\n[CombatEngineStub] Combat auto-resolves immediately; skipping gameplay.")
end

function CombatEngineStub.displayLog(world, count)
    ensureLog(world)
    count = count or #world.log
    print("\n[CombatEngineStub] Recent log:")
    local start = math.max(1, #world.log - count + 1)
    for i = start, #world.log do
        print("  " .. world.log[i])
    end
end

function CombatEngineStub.playGame(world)
    ensureLog(world)
    CombatEngineStub.addLogEntry(world, "[Stub] Combat auto-resolved as a victory.")

    -- Zero-out all current enemies to signal victory.
    if world.enemies then
        for _, enemy in ipairs(world.enemies) do
            enemy.hp = 0
        end
    end

    -- Mirror a normal victory outcome for downstream systems.
    CombatEngineStub.displayGameState(world)
    print("[CombatEngineStub] Victory!")

    return true
end

return CombatEngineStub

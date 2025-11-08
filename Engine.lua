-- GAME ENGINE
-- Initializes and manages game state, runs the main game loop

local EventQueue = require("Pipelines.EventQueue")
local PlayCard = require("Pipelines.PlayCard")
local EndTurn = require("Pipelines.EndTurn")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")
local DrawCard = require("Pipelines.DrawCard")
local StartTurn = require("Pipelines.StartTurn")
local GetCost = require("Pipelines.GetCost")

local Engine = {}

-- ============================================================================
-- GAME STATE INITIALIZATION
-- ============================================================================
-- The 'world' object passed to all pipelines contains:
-- - player: player character with hp, maxHp, block, energy, cards (single table)
-- - enemy: current enemy with hp, maxHp, intents
-- - combat: combat-wide state (timesHpLost, etc.)
-- - queue: event queue for all actions
-- - log: combat log for debugging/display
-- - relics: player's relics list
--
-- Cards architecture:
-- - All cards are stored in player.cards[] (single source of truth)
-- - Each card has a 'state' property: "DECK", "HAND", "DISCARD_PILE", "EXHAUSTED_PILE"
-- - Use helper functions to get cards by state

function Engine.createGameState(playerData, enemyData)
    return {
        -- PLAYER
        player = {
            id = playerData.id or "IronClad",
            name = playerData.name or playerData.id or "IronClad",
            hp = playerData.hp or 80,
            maxHp = playerData.hp or 80,
            block = 0,
            energy = 3,
            maxEnergy = 3,

            cards = {},  -- All cards with state property (DECK, HAND, DISCARD_PILE, EXHAUSTED_PILE)

            relics = playerData.relics or {},
        },

        -- ENEMY
        enemy = enemyData,

        -- COMBAT STATE
        -- Tracks combat-wide counters for card mechanics
        combat = {
            timesHpLost = 0,  -- For Blood for Blood cost reduction
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

-- ============================================================================
-- CARD STATE HELPER FUNCTIONS
-- ============================================================================

-- Get all cards in a specific state
function Engine.getCardsByState(player, state)
    local cards = {}
    for _, card in ipairs(player.cards) do
        if card.state == state then
            table.insert(cards, card)
        end
    end
    return cards
end

-- Get count of cards in a specific state
function Engine.getCardCountByState(player, state)
    local count = 0
    for _, card in ipairs(player.cards) do
        if card.state == state then
            count = count + 1
        end
    end
    return count
end

-- ============================================================================
-- GAME DISPLAY
-- ============================================================================

function Engine.displayGameState(world)
    print("\n" .. string.rep("=", 60))

    -- Enemy status line
    local enemyStatus = ""
    if world.enemy.status and world.enemy.status.vulnerable and world.enemy.status.vulnerable > 0 then
        enemyStatus = enemyStatus .. " [Vulnerable: " .. world.enemy.status.vulnerable .. "]"
    end
    if world.enemy.status and world.enemy.status.weak and world.enemy.status.weak > 0 then
        enemyStatus = enemyStatus .. " [Weak: " .. world.enemy.status.weak .. "]"
    end
    print("ENEMY: " .. world.enemy.name .. " | HP: " .. world.enemy.hp .. "/" .. world.enemy.maxHp .. enemyStatus)

    print(string.rep("=", 60))

    -- Player status line
    local playerStatus = ""
    if world.player.block > 0 then
        playerStatus = playerStatus .. " | Block: " .. world.player.block
    end
    if world.player.status and world.player.status.vulnerable and world.player.status.vulnerable > 0 then
        playerStatus = playerStatus .. " [Vulnerable: " .. world.player.status.vulnerable .. "]"
    end
    if world.player.status and world.player.status.weak and world.player.status.weak > 0 then
        playerStatus = playerStatus .. " [Weak: " .. world.player.status.weak .. "]"
    end
    if world.player.status and world.player.status.thorns and world.player.status.thorns > 0 then
        playerStatus = playerStatus .. " [Thorns: " .. world.player.status.thorns .. "]"
    end
    if world.player.status and world.player.status.confused and world.player.status.confused > 0 then
        playerStatus = playerStatus .. " [Confused]"
    end
    print("PLAYER: " .. world.player.id .. " | HP: " .. world.player.hp .. "/" .. world.player.maxHp .. " | Energy: " .. world.player.energy .. "/" .. world.player.maxEnergy .. playerStatus)

    -- Display relics
    if world.player.relics and #world.player.relics > 0 then
        local relicNames = {}
        for _, relic in ipairs(world.player.relics) do
            table.insert(relicNames, relic.name)
        end
        print("RELICS: " .. table.concat(relicNames, ", "))
    end

    print(string.rep("-", 60))
    print("HAND:")
    local hand = Engine.getCardsByState(world.player, "HAND")
    if #hand == 0 then
        print("  (empty)")
    else
        for i, card in ipairs(hand) do
            local cardCost = GetCost.execute(world, world.player, card)
            local targetInfo = card.Targeted == 1 and " [TARGETED]" or ""
            print("  [" .. i .. "] " .. card.name .. " (Cost: " .. cardCost .. ")" .. targetInfo .. " - " .. card.description)
        end
    end
    print(string.rep("=", 60))
end

function Engine.displayLog(world, count)
    count = count or 5
    print("\nRECENT LOG:")
    local start = math.max(1, #world.log - count + 1)
    for i = start, #world.log do
        print("  " .. world.log[i])
    end
end

-- ============================================================================
-- GAME LOOP
-- ============================================================================

function Engine.playGame(world)
    local gameOver = false
    local waitingForTarget = false
    local pendingCard = nil

    -- Start first turn (draw initial hand, apply Snecko Eye bonus, etc.)
    StartTurn.execute(world, world.player)

    while not gameOver do
        Engine.displayGameState(world)

        if waitingForTarget then
            print("\nChoose a target:")
            print("  [1] " .. world.enemy.name)
            io.write("> ")
            local input = io.read()
            if not input then
                print("\nInput stream closed. Exiting game.")
                gameOver = true
                break
            end

            if input == "1" then
                -- Execute the pending card with target
                PlayCard.execute(world, world.player, pendingCard, world.enemy)
                Engine.displayLog(world, 3)
                waitingForTarget = false
                pendingCard = nil
            else
                print("Invalid target. Try again.")
            end
        else
            print("\nActions:")
            print("  play <card number> - Play a card from your hand")
            print("  end - End your turn")
            io.write("> ")
            local input = io.read()
            if not input then
                print("\nInput stream closed. Exiting game.")
                gameOver = true
                break
            end

            -- Parse command
            local command, arg = input:match("^(%S+)%s*(%S*)$")
            if not command then
                command = input
            end

            if command == "play" then
                local cardIndex = tonumber(arg)
                local hand = Engine.getCardsByState(world.player, "HAND")
                if cardIndex and cardIndex >= 1 and cardIndex <= #hand then
                    local card = hand[cardIndex]

                    -- Check if card requires targeting
                    if card.Targeted == 1 then
                        pendingCard = card
                        waitingForTarget = true
                    else
                        -- Non-targeted card, execute immediately
                        PlayCard.execute(world, world.player, card, world.player)
                        Engine.displayLog(world, 3)
                    end
                else
                    print("Invalid card number. Try again.")
                end

            elseif command == "end" then
                -- End player turn
                EndTurn.execute(world, world.player)

                -- Check if player won
                if world.enemy.hp <= 0 then
                    print("\n🎉 Victory! You defeated " .. world.enemy.name .. "!")
                    gameOver = true
                else
                    -- Enemy turn
                    EnemyTakeTurn.execute(world, world.enemy, world.player)
                    Engine.displayLog(world, 5)

                    -- Check if player lost
                    if world.player.hp <= 0 then
                        print("\n💀 Defeat! You were slain by " .. world.enemy.name .. "!")
                        gameOver = true
                    else
                        -- Start new player turn
                        StartTurn.execute(world, world.player)
                    end
                end

            else
                print("Unknown command. Type 'play <number>' or 'end'")
            end
        end

        -- Check win/loss conditions after each action
        if world.enemy.hp <= 0 then
            print("\n🎉 Victory! You defeated " .. world.enemy.name .. "!")
            gameOver = true
        elseif world.player.hp <= 0 then
            print("\n💀 Defeat! You were slain by " .. world.enemy.name .. "!")
            gameOver = true
        end
    end

    print("\nGame Over!")
    Engine.displayLog(world, 10)
end

return Engine

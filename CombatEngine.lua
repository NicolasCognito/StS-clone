-- Runs combat encounters against one or more enemies using the pipeline system

local PlayCard = require("Pipelines.PlayCard")
local EndTurn = require("Pipelines.EndTurn")
local EnemyTakeTurn = require("Pipelines.EnemyTakeTurn")
local StartTurn = require("Pipelines.StartTurn")
local GetCost = require("Pipelines.GetCost")
local ContextProvider = require("Pipelines.ContextProvider")
local Utils = require("utils")

local CombatEngine = {}

function CombatEngine.addLogEntry(world, message)
    table.insert(world.log, message)
end

function CombatEngine.getCardsByState(player, state)
    return Utils.getCardsByState(player.combatDeck, state)
end

function CombatEngine.getCardCountByState(player, state)
    return Utils.getCardCountByState(player.combatDeck, state)
end

local function aliveEnemies(world)
    local list = {}
    if not world.enemies then
        return list
    end
    for _, enemy in ipairs(world.enemies) do
        if enemy.hp > 0 then
            table.insert(list, enemy)
        end
    end
    return list
end

local function hasLivingEnemies(world)
    return #aliveEnemies(world) > 0
end

function CombatEngine.displayGameState(world)
    print("\n" .. string.rep("=", 60))

    print("ENEMIES:")
    if not world.enemies or #world.enemies == 0 then
        print("  (no enemies)")
    else
        for i, enemy in ipairs(world.enemies) do
            if enemy.hp > 0 then
                local enemyStatus = ""
                if enemy.status and enemy.status.vulnerable and enemy.status.vulnerable > 0 then
                    enemyStatus = enemyStatus .. " [Vulnerable: " .. enemy.status.vulnerable .. "]"
                end
                if enemy.status and enemy.status.weak and enemy.status.weak > 0 then
                    enemyStatus = enemyStatus .. " [Weak: " .. enemy.status.weak .. "]"
                end
                print("  [" .. i .. "] " .. enemy.name .. " | HP: " .. enemy.hp .. "/" .. enemy.maxHp .. enemyStatus)
            else
                print("  [" .. i .. "] " .. enemy.name .. " (DEAD)")
            end
        end
    end

    print(string.rep("=", 60))

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

    if world.player.relics and #world.player.relics > 0 then
        local relicNames = {}
        for _, relic in ipairs(world.player.relics) do
            table.insert(relicNames, relic.name)
        end
        print("RELICS: " .. table.concat(relicNames, ", "))
    end

    print(string.rep("-", 60))
    print("HAND:")
    local hand = CombatEngine.getCardsByState(world.player, "HAND")
    if #hand == 0 then
        print("  (empty)")
    else
        for i, card in ipairs(hand) do
            local cardCost = GetCost.execute(world, world.player, card)
            print("  [" .. i .. "] " .. card.name .. " (Cost: " .. cardCost .. ") - " .. card.description)
        end
    end
    print(string.rep("=", 60))
end

function CombatEngine.displayLog(world, count)
    count = count or 5
    print("\nRECENT LOG:")
    local start = math.max(1, #world.log - count + 1)
    for i = start, #world.log do
        print("  " .. world.log[i])
    end
end

function CombatEngine.playGame(world)
    local gameOver = false

    while not gameOver do
        CombatEngine.displayGameState(world)

        -- Check if there's a context request pending
        if world.combat.contextRequest then
            local request = world.combat.contextRequest
            local context = nil
            local validInput = false

            -- Check if we can reuse stable context
            if request.stability == "stable" and world.combat.stableContext then
                context = world.combat.stableContext
                validInput = true
            else
                -- Need to collect context from user
                local contextType = ContextProvider.getContextType(request.contextProvider)

                if contextType == "enemy" then
                    print("\nChoose a target:")
                    local living = aliveEnemies(world)
                    for i, enemy in ipairs(living) do
                        print("  [" .. i .. "] " .. enemy.name .. " (" .. enemy.hp .. " HP)")
                    end
                    print("  [0] Cancel")
                    io.write("> ")
                    local input = io.read()
                    if not input then
                        print("\nInput stream closed. Exiting game.")
                        break
                    end
                    local choice = tonumber(input)
                    if choice == 0 then
                        world.combat.contextRequest = nil
                        world.combat.stableContext = nil
                        world.combat.tempContext = nil
                        validInput = false
                        print("Cancelled.")
                    elseif choice and choice >= 1 and choice <= #living then
                        context = living[choice]
                        validInput = true
                    else
                        print("Invalid target. Try again.")
                    end
                elseif contextType == "cards" then
                    -- Card selection system
                    local selectableCards = ContextProvider.getValidCards(world, world.player, request.contextProvider, request.card)

                    if #selectableCards == 0 then
                        print("No cards available to select.")
                        validInput = true
                        context = {}
                    else
                        -- Get display name for card source
                        local info = ContextProvider.getSelectionInfo(request.contextProvider)
                        local sourceName = info.source == "master" and "master deck" or "available cards"

                        print("\nChoose a card from " .. sourceName .. ":")
                        for i, card in ipairs(selectableCards) do
                            print("  [" .. i .. "] " .. card.name)
                        end
                        print("  [0] Cancel")
                        io.write("> ")
                        local input = io.read()
                        if not input then
                            print("\nInput stream closed. Exiting game.")
                            break
                        end
                        local cardIndex = tonumber(input)
                        if cardIndex == 0 then
                            world.combat.contextRequest = nil
                            world.combat.stableContext = nil
                            world.combat.tempContext = nil
                            validInput = false
                            print("Cancelled.")
                        elseif cardIndex and cardIndex >= 1 and cardIndex <= #selectableCards then
                            context = {selectableCards[cardIndex]}
                            validInput = true
                        else
                            print("Invalid selection. Try again.")
                        end
                    end
                end
            end

            -- Store collected context
            if validInput then
                if request.stability == "stable" then
                    world.combat.stableContext = context
                else
                    world.combat.tempContext = context
                end
                world.combat.contextRequest = nil

                -- Continue playing the card
                local result = PlayCard.execute(world, world.player, request.card)
                CombatEngine.displayLog(world, 3)
                -- Context cleanup handled by QueueOver pipeline
            end
        else
            print("\nActions:")
            print("  play <card number> - Play a card from your hand")
            print("  end - End your turn")
            io.write("> ")
            local input = io.read()
            if not input then
                print("\nInput stream closed. Exiting game.")
                break
            end

            local command, arg = input:match("^(%S+)%s*(%S*)$")
            if not command then
                command = input
            end

            if command == "play" then
                local cardIndex = tonumber(arg)
                local hand = CombatEngine.getCardsByState(world.player, "HAND")
                if cardIndex and cardIndex >= 1 and cardIndex <= #hand then
                    local card = hand[cardIndex]
                    local result = PlayCard.execute(world, world.player, card)

                    -- Check if result is successful (not needsContext)
                    if type(result) ~= "table" or not result.needsContext then
                        CombatEngine.displayLog(world, 3)
                    end

                    -- If needsContext, the next iteration will handle it via contextRequest
                else
                    print("Invalid card number. Try again.")
                end
            elseif command == "end" then
                EndTurn.execute(world, world.player)

                if not hasLivingEnemies(world) then
                    print("\n🎉 Victory! You defeated all enemies!")
                    gameOver = true
                else
                    for _, enemy in ipairs(world.enemies or {}) do
                        if enemy.hp > 0 then
                            EnemyTakeTurn.execute(world, enemy, world.player)
                        end
                    end
                    CombatEngine.displayLog(world, 5)

                    if world.player.hp <= 0 then
                        print("\n💀 Defeat! You were slain!")
                        gameOver = true
                    else
                        StartTurn.execute(world, world.player)
                    end
                end
            else
                print("Unknown command. Type 'play <number>' or 'end'")
            end
        end

        if not gameOver then
            if not hasLivingEnemies(world) then
                print("\n🎉 Victory! You defeated all enemies!")
                gameOver = true
            elseif world.player.hp <= 0 then
                print("\n💀 Defeat! You were slain!")
                gameOver = true
            end
        end
    end

    print("\nGame Over!")
    if world.log then
        CombatEngine.displayLog(world, 10)
    end
end

return CombatEngine

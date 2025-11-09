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
            local targetInfo = card.contextProvider == "enemy" and " [TARGETED]" or ""
            print("  [" .. i .. "] " .. card.name .. " (Cost: " .. cardCost .. ")" .. targetInfo .. " - " .. card.description)
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
    local waitingForContext = false
    local waitingForPostPlayContext = false
    local pendingCard = nil
    local pendingContextType = nil

    while not gameOver do
        CombatEngine.displayGameState(world)

        if waitingForContext then
            local context = nil
            local validInput = false

            if pendingContextType == "enemy" then
                -- Show appropriate prompt for post-play vs regular play
                if waitingForPostPlayContext then
                    print("\n" .. pendingCard.name .. " - Choose a target:")
                else
                    print("\nChoose a target:")
                end
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
                    waitingForContext = false
                    waitingForPostPlayContext = false
                    pendingCard = nil
                    pendingContextType = nil
                    validInput = false
                    print("Cancelled.")
                elseif choice and choice >= 1 and choice <= #living then
                    context = living[choice]
                    validInput = true
                else
                    print("Invalid target. Try again.")
                end
            elseif pendingContextType == "cards" then
                -- Card selection system
                local contextField = waitingForPostPlayContext and "postPlayContext" or "contextProvider"
                local selectableCards = ContextProvider.getValidCards(world, world.player, pendingCard, contextField)

                if #selectableCards == 0 then
                    print("No cards available to select.")
                    validInput = true
                    context = {}
                else
                    -- Get display name for card source
                    local info = ContextProvider.getSelectionInfo(pendingCard, contextField)
                    local sourceName = info.source == "master" and "master deck" or "available cards"

                    -- Show appropriate prompt for post-play vs regular play
                    if waitingForPostPlayContext then
                        print("\n" .. pendingCard.name .. " - Choose a card from " .. sourceName .. ":")
                    else
                        print("\nChoose a card from " .. sourceName .. ":")
                    end
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
                        waitingForContext = false
                        waitingForPostPlayContext = false
                        pendingCard = nil
                        pendingContextType = nil
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

            if validInput and pendingCard then
                if waitingForPostPlayContext then
                    -- Execute post-play phase
                    local result = PlayCard.executePostPlay(world, world.player, pendingCard, context)
                    CombatEngine.displayLog(world, 3)

                    -- Check if postPlay needs to execute again (e.g., Double Tap)
                    if type(result) == "table" and result.needsPostPlay then
                        -- Stay in postPlay mode, prompt again for next discard
                        -- pendingCard and pendingContextType remain unchanged
                    else
                        -- All postPlay executions complete
                        waitingForContext = false
                        waitingForPostPlayContext = false
                        pendingCard = nil
                        pendingContextType = nil
                    end
                else
                    -- Execute main play
                    local result = PlayCard.execute(world, world.player, pendingCard, context)
                    CombatEngine.displayLog(world, 3)

                    -- Check if card needs post-play phase
                    if type(result) == "table" and result.needsPostPlay then
                        -- Enter post-play context collection mode
                        pendingContextType = ContextProvider.getContextType(pendingCard, "postPlayContext")
                        waitingForPostPlayContext = true
                        -- Keep pendingCard for post-play execution
                    else
                        -- Normal completion
                        waitingForContext = false
                        pendingCard = nil
                        pendingContextType = nil
                    end
                end
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
                    local contextType = ContextProvider.getContextType(card)
                    if contextType == "none" then
                        -- Play card without initial context
                        local result = PlayCard.execute(world, world.player, card, nil)
                        CombatEngine.displayLog(world, 3)

                        -- Check if card needs post-play phase
                        if type(result) == "table" and result.needsPostPlay then
                            pendingCard = card
                            pendingContextType = ContextProvider.getContextType(card, "postPlayContext")
                            waitingForContext = true
                            waitingForPostPlayContext = true
                        end
                    else
                        pendingCard = card
                        pendingContextType = contextType
                        waitingForContext = true
                    end
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

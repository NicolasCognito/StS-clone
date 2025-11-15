-- Runs combat encounters against one or more enemies using the pipeline system

local PlayCard = require("Pipelines.PlayCard")
local UsePotion = require("Pipelines.UsePotion")
local EndTurn = require("Pipelines.EndTurn")
local EndRound = require("Pipelines.EndRound")
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

local function resolveSelectionBounds(world, request)
    local provider = request.contextProvider or {}
    local count = provider.count

    if type(count) == "function" then
        local ok, resolved = pcall(count, world, world.player, request.card)
        if ok and type(resolved) == "table" then
            count = resolved
        else
            count = nil
        end
    end

    if type(count) ~= "table" then
        count = {min = 1, max = 1}
    end

    local minSelect = count.min
    local maxSelect = count.max

    if type(minSelect) ~= "number" then
        minSelect = 1
    end
    if type(maxSelect) ~= "number" then
        maxSelect = minSelect
    end

    minSelect = math.max(0, math.floor(minSelect))
    maxSelect = math.max(minSelect, math.floor(maxSelect))

    return {min = minSelect, max = maxSelect}
end

local function enrichContextRequest(world, request)
    if not request or not request.contextProvider then
        return request
    end

    request.selectionInfo = request.selectionInfo or ContextProvider.getSelectionInfo(request.contextProvider)

    if request.contextProvider.type == "cards" then
        request.selectableCards = ContextProvider.getValidCards(world, world.player, request.contextProvider, request.card)
        request.selectionBounds = resolveSelectionBounds(world, request)
    end

    return request
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

    -- Display orbs
    if world.player.orbs and #world.player.orbs > 0 then
        local orbDisplay = {}
        for i, orb in ipairs(world.player.orbs) do
            local orbInfo = orb.id
            if orb.accumulatedDamage then
                orbInfo = orbInfo .. "(" .. orb.accumulatedDamage .. ")"
            end
            table.insert(orbDisplay, orbInfo)
        end
        print("ORBS [" .. #world.player.orbs .. "/" .. world.player.maxOrbs .. "]: " .. table.concat(orbDisplay, " | "))
    end

    -- Display Focus
    if world.player.status and world.player.status.focus and world.player.status.focus ~= 0 then
        print("FOCUS: " .. world.player.status.focus)
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

    print(string.rep("-", 60))
    print("POTIONS:")
    if not world.player.masterPotions or #world.player.masterPotions == 0 then
        print("  (none)")
    else
        for i, potion in ipairs(world.player.masterPotions) do
            print("  [" .. i .. "] " .. potion.name .. " - " .. potion.description)
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

local function resolveContext(world, handlers, request)
    if request.stability == "stable" and world.combat.stableContext then
        return world.combat.stableContext, "stable"
    end

    if not handlers or type(handlers.onContextRequest) ~= "function" then
        error("CombatEngine.playGame: context requested but no onContextRequest handler provided")
    end
    return handlers.onContextRequest(world, request)
end

local function getPlayerAction(handlers, world)
    if not handlers or type(handlers.onPlayerAction) ~= "function" then
        error("CombatEngine.playGame requires an onPlayerAction handler")
    end
    return handlers.onPlayerAction(world)
end

local function notifyDisplayLog(handlers, world, count)
    if handlers and type(handlers.onDisplayLog) == "function" then
        handlers.onDisplayLog(world, count)
    end
end

local function notifyRender(handlers, world)
    if handlers and type(handlers.onRenderState) == "function" then
        handlers.onRenderState(world)
    end
end

local function notifyResult(handlers, world, result)
    if handlers and type(handlers.onCombatResult) == "function" then
        handlers.onCombatResult(world, result)
    end
end

local function notifyCombatEnd(handlers, world, result)
    if handlers and type(handlers.onCombatEnd) == "function" then
        handlers.onCombatEnd(world, result)
    end
end

function CombatEngine.playGame(world, handlers)
    handlers = handlers or {}
    local gameOver = false
    local resultToken = nil

    while not gameOver do
        notifyRender(handlers, world)

        if world.combat.contextRequest then
            local request = enrichContextRequest(world, world.combat.contextRequest)
            local context, control = resolveContext(world, handlers, request)

            if control == "quit" then
                resultToken = "quit"
                break
            end

            if context == nil then
                world.combat.contextRequest = nil
                world.combat.stableContext = nil
                world.combat.tempContext = nil
            else
                if request.stability == "stable" then
                    world.combat.stableContext = context
                else
                    world.combat.tempContext = context
                end
                world.combat.contextRequest = nil

                -- Resume execution based on who requested context:
                -- - If request.card exists: context was requested by PlayCard (card needs target)
                -- - If request.card is nil: context was requested by another pipeline (e.g., EndTurn for Well-Laid Plans)
                if request.card then
                    -- Resume card play with collected context
                    local result = PlayCard.execute(world, world.player, request.card)
                    if type(result) ~= "table" or not result.needsContext then
                        notifyDisplayLog(handlers, world, 3)
                    end
                else
                    -- Resume queue processing (continuation pattern)
                    -- The queue still has pending events from the pipeline that requested context
                    local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
                    ProcessEventQueue.execute(world)
                    notifyDisplayLog(handlers, world, 3)

                    -- Check if this was EndTurn with Vault active
                    if world.combat.vaultPlayed then
                        world.combat.vaultPlayed = nil
                        -- EndTurn completed, handle Vault effect (skip enemy turns)
                        if not hasLivingEnemies(world) then
                            notifyResult(handlers, world, "victory")
                            resultToken = "victory"
                            gameOver = true
                        elseif world.player.hp <= 0 then
                            notifyResult(handlers, world, "defeat")
                            resultToken = "defeat"
                            gameOver = true
                        else
                            table.insert(world.log, "--- Enemies' turns skipped (Vault) ---")
                            StartTurn.execute(world, world.player)
                            notifyDisplayLog(handlers, world, 5)
                        end
                    else
                        -- Normal EndTurn (not Vault), proceed with enemy turns
                        if not hasLivingEnemies(world) then
                            notifyResult(handlers, world, "victory")
                            resultToken = "victory"
                            gameOver = true
                        else
                            for _, enemy in ipairs(world.enemies or {}) do
                                if enemy.hp > 0 then
                                    EnemyTakeTurn.execute(world, enemy, world.player)
                                end
                            end

                            EndRound.execute(world, world.player, world.enemies)
                            notifyDisplayLog(handlers, world, 5)

                            if world.player.hp <= 0 then
                                notifyResult(handlers, world, "defeat")
                                resultToken = "defeat"
                                gameOver = true
                            else
                                StartTurn.execute(world, world.player)
                            end
                        end
                    end
                end
            end
        else
            local action, control = getPlayerAction(handlers, world)
            if control == "quit" then
                resultToken = "quit"
                break
            end
            if not action then
                resultToken = "quit"
                break
            end

            if action.type == "play" then
                local hand = CombatEngine.getCardsByState(world.player, "HAND")
                local card = action.card or (action.cardIndex and hand[action.cardIndex])
                if not card then
                    if handlers.onInvalidAction then
                        handlers.onInvalidAction(world, action)
                    end
                else
                    local result = PlayCard.execute(world, world.player, card)
                    if type(result) ~= "table" or not result.needsContext then
                        notifyDisplayLog(handlers, world, 3)
                    end

                    if world.combat.vaultPlayed then
                        local vaultResult = EndTurn.execute(world, world.player)

                        -- Check if EndTurn paused for context (unlikely with Vault, but handle it)
                        if type(vaultResult) == "table" and vaultResult.needsContext then
                            -- Context request will be handled on next loop iteration
                            -- Keep vaultPlayed flag set so we handle it after context is resolved
                        else
                            -- EndTurn completed, clear the Vault flag
                            world.combat.vaultPlayed = nil


                            -- EndTurn completed normally, skip enemy turns (Vault effect)
                            if not hasLivingEnemies(world) then
                                notifyResult(handlers, world, "victory")
                                resultToken = "victory"
                                gameOver = true
                            elseif world.player.hp <= 0 then
                                notifyResult(handlers, world, "defeat")
                                resultToken = "defeat"
                                gameOver = true
                            else
                                table.insert(world.log, "--- Enemies' turns skipped (Vault) ---")
                                StartTurn.execute(world, world.player)
                                notifyDisplayLog(handlers, world, 5)
                            end
                        end
                    end
                end
            elseif action.type == "use_potion" then
                local potion = action.potion or (action.potionIndex and world.player.masterPotions[action.potionIndex])
                if not potion then
                    if handlers.onInvalidAction then
                        handlers.onInvalidAction(world, action)
                    end
                else
                    UsePotion.execute(world, world.player, potion)
                    notifyDisplayLog(handlers, world, 3)
                end
            elseif action.type == "end" then
                local result = EndTurn.execute(world, world.player)

                -- Check if EndTurn paused for context (e.g., Well-Laid Plans card selection)
                if type(result) == "table" and result.needsContext then
                    -- Context request will be handled on next loop iteration
                    -- Don't proceed with enemy turns yet
                else
                    -- EndTurn completed normally, proceed with enemy turns
                    if not hasLivingEnemies(world) then
                        notifyResult(handlers, world, "victory")
                        resultToken = "victory"
                        gameOver = true
                    else
                        for _, enemy in ipairs(world.enemies or {}) do
                            if enemy.hp > 0 then
                                EnemyTakeTurn.execute(world, enemy, world.player)
                            end
                        end

                        EndRound.execute(world, world.player, world.enemies)
                        notifyDisplayLog(handlers, world, 5)

                        if world.player.hp <= 0 then
                            notifyResult(handlers, world, "defeat")
                            resultToken = "defeat"
                            gameOver = true
                        else
                            StartTurn.execute(world, world.player)
                        end
                    end
                end
            else
                if handlers.onInvalidAction then
                    handlers.onInvalidAction(world, action)
                else
                    error("CombatEngine.playGame: unknown action type " .. tostring(action.type))
                end
            end
        end

        if not gameOver then
            if not hasLivingEnemies(world) then
                notifyResult(handlers, world, "victory")
                resultToken = "victory"
                gameOver = true
            elseif world.player.hp <= 0 then
                notifyResult(handlers, world, "defeat")
                resultToken = "defeat"
                gameOver = true
            end
        end
    end

    notifyCombatEnd(handlers, world, resultToken or "quit")
end

return CombatEngine

-- COMBAT CLI DRIVER
-- Thin wrapper around CombatEngine that handles user input/output.

local CombatCLI = {}

local CombatEngine = require("CombatEngine")

local function prompt(message)
    if message then
        print(message)
    end
    io.write("> ")
    return io.read()
end

local function listLivingEnemies(world)
    local enemies = {}
    if not world.enemies then
        return enemies
    end
    for _, enemy in ipairs(world.enemies) do
        -- Exclude reviving enemies from targeting
        if enemy.hp > 0 and not enemy.reviving then
            table.insert(enemies, enemy)
        end
    end
    return enemies
end

local function requestEnemyTarget(world)
    local living = listLivingEnemies(world)
    if #living == 0 then
        print("No living enemies to target.")
        return nil
    end

    print("\nChoose a target:")
    for i, enemy in ipairs(living) do
        print(string.format("  [%d] %s (%d HP)", i, enemy.name, enemy.hp))
    end
    print("  [0] Cancel")

    while true do
        local input = prompt(nil)
        if not input then
            return nil, "quit"
        end
        local choice = tonumber(input)
        if choice == 0 then
            print("Cancelled.")
            return nil, "cancel"
        end
        if choice and living[choice] then
            return living[choice], "ok"
        end
        print("Invalid target. Try again.")
    end
end

local function requestCardSelection(world, request)
    local selectable = request.selectableCards or {}
    local info = request.selectionInfo or {}
    local bounds = request.selectionBounds or {}
    local minSelect = bounds.min
    local maxSelect = bounds.max

    if type(minSelect) ~= "number" then
        minSelect = 1
    end
    if type(maxSelect) ~= "number" then
        maxSelect = minSelect
    end

    minSelect = math.max(0, math.floor(minSelect))
    maxSelect = math.max(minSelect, math.floor(maxSelect))

    local sourceName = info.source == "master" and "master deck" or "available cards"

    if #selectable == 0 then
        if minSelect == 0 then
            print("No cards available; submitting empty selection.")
            return {}, "ok"
        end
        print("No cards available to meet the requirement. Selection cancelled.")
        return nil, "cancel"
    end

    if #selectable < minSelect then
        print(string.format("Only %d cards available but %d required. Selection cancelled.", #selectable, minSelect))
        return nil, "cancel"
    end

    local selectedLookup = {}
    local selectedCards = {}

    local function selectionSummary()
        if minSelect == maxSelect then
            return string.format("Select exactly %d card%s.", minSelect, minSelect == 1 and "" or "s")
        else
            return string.format("Select between %d and %d cards.", minSelect, maxSelect)
        end
    end

    local function renderList()
        print("\nChoose cards from " .. sourceName .. ":")
        print(string.format("Currently selected: %d/%d. %s", #selectedCards, math.min(maxSelect, #selectable), selectionSummary()))
        for i, card in ipairs(selectable) do
            local marker = selectedLookup[i] and "*" or " "
            print(string.format("  [%d]%s %s", i, marker, card.name))
        end
        print("  [0] Cancel (or press Enter to submit)")
    end

    local function toggleSelection(index)
        if selectedLookup[index] then
            selectedLookup[index] = nil
            for i = #selectedCards, 1, -1 do
                if selectedCards[i] == selectable[index] then
                    table.remove(selectedCards, i)
                    break
                end
            end
            print(selectable[index].name .. " deselected.")
            return
        end

        if #selectedCards >= maxSelect then
            print(string.format("Already selected maximum of %d cards. Press Enter to submit or deselect a card first.", maxSelect))
            return
        end

        selectedLookup[index] = true
        table.insert(selectedCards, selectable[index])
        print(selectable[index].name .. " selected.")
    end

    while true do
        renderList()
        local input = prompt(nil)
        if input == nil then
            return nil, "quit"
        end

        if input == "" then
            if #selectedCards < minSelect then
                print(string.format("Need at least %d card%s selected before submitting.", minSelect, minSelect == 1 and "" or "s"))
            else
                return selectedCards, "ok"
            end
        else
            local index = tonumber(input)
            if index == nil then
                print("Invalid input. Enter a card number, 0 to cancel, or press Enter to submit.")
            elseif index == 0 then
                print("Cancelled.")
                return nil, "cancel"
            elseif selectable[index] then
                toggleSelection(index)
            else
                print("Invalid selection. Try again.")
            end
        end
    end
end

local function getContextType(request)
    local provider = request and request.contextProvider
    if provider and type(provider) == "table" then
        return provider.type or "none"
    end
    return "none"
end

local function handleContextRequest(world, request)
    local contextType = getContextType(request)
    if contextType == "enemy" then
        return requestEnemyTarget(world)
    elseif contextType == "cards" then
        return requestCardSelection(world, request)
    end
    return nil, "cancel"
end

local function requestPlayerAction(world)
    print("\nActions:")
    print("  play <card number> - Play a card from your hand")
    print("  end - End your turn")
    print("  quit - Exit combat")

    while true do
        local input = prompt(nil)
        if not input then
            return nil, "quit"
        end
        local command, arg = input:match("^(%S+)%s*(%S*)$")
        command = command or input
        command = command:lower()

        if command == "play" then
            local index = tonumber(arg)
            if not index then
                print("Please provide the card number to play.")
            else
                local hand = CombatEngine.getCardsByState(world.player, "HAND")
                if index >= 1 and index <= #hand then
                    return {type = "play", cardIndex = index}, "ok"
                else
                    print("Invalid card number. Try again.")
                end
            end
        elseif command == "end" then
            return {type = "end"}, "ok"
        elseif command == "quit" then
            return nil, "quit"
        else
            print("Unknown command. Type 'play <number>', 'end', or 'quit'.")
        end
    end
end

local function renderState(world)
    CombatEngine.displayGameState(world)
end

local function showLog(world, count)
    CombatEngine.displayLog(world, count)
end

local function announceResult(_, result)
    if result == "victory" then
        print("\n🎉 Victory! You defeated all enemies!")
    elseif result == "defeat" then
        print("\n💀 Defeat! You were slain!")
    end
end

local function finalizeCombat(world, result)
    if result ~= "victory" and result ~= "defeat" then
        print("\nCombat ended.")
    end
    CombatEngine.displayLog(world, 10)
end

function CombatCLI.play(world)
    CombatEngine.playGame(world, {
        onRenderState = renderState,
        onContextRequest = function(w, request)
            local context, status = handleContextRequest(w, request)
            if status == "cancel" then
                return nil, "cancel"
            end
            return context, status
        end,
        onPlayerAction = function(w)
            local action, status = requestPlayerAction(w)
            if status == "quit" then
                return nil, "quit"
            end
            return action, status
        end,
        onDisplayLog = showLog,
        onCombatResult = announceResult,
        onCombatEnd = finalizeCombat
    })
end

return CombatCLI

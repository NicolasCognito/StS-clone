-- MAP CLI LOOP
-- Lightweight text UI for traversing the overworld and resolving MapEvents.

local MapCLI = {}

local MapEngine = require("MapEngine")
local Map_ChooseNextNode = require("Pipelines.Map_ChooseNextNode")

local function prompt(message)
    if message and #message > 0 then
        print(message)
    end
    io.write("> ")
    return io.read()
end

local function describeOption(option, index)
    local label = option.label or ("Option " .. index)
    local description = option.description or ""
    return string.format("  [%d] %s%s", index, label, (#description > 0) and (" - " .. description) or "")
end

local function promptOptionSelection(_, request)
    local options = request.options or {}
    if #options == 0 then
        print("No options available.")
        return nil
    end

    local header = request.prompt or "Choose an option:"
    print("\n" .. header)
    for i, option in ipairs(options) do
        print(describeOption(option, i))
    end
    print("  [0] Cancel")

    while true do
        local input = prompt(nil)
        if not input then
            return nil
        end
        local choice = tonumber(input)
        if choice == 0 then
            print("Selection cancelled.")
            return nil
        elseif choice and options[choice] then
            return options[choice]
        else
            print("Invalid choice. Try again.")
        end
    end
end

local function formatCard(card, index)
    local name = card.name or card.id or ("Card " .. index)
    local upgraded = card.upgraded and " (Upgraded)" or ""
    return string.format("  [%d] %s%s", index, name, upgraded)
end

local function promptCardSelection(_, request)
    local cards = request.selectableCards or {}
    local bounds = request.selectionBounds or {}
    local minCount = bounds.min or 1
    local maxCount = bounds.max or minCount

    if type(minCount) ~= "number" then
        minCount = 1
    end
    if type(maxCount) ~= "number" then
        maxCount = minCount
    end

    minCount = math.max(0, math.floor(minCount))
    maxCount = math.max(minCount, math.floor(maxCount))

    if #cards == 0 then
        print("No valid cards available.")
        return (minCount == 0) and {} or nil
    end

    print("\nChoose a card:")
    for i, card in ipairs(cards) do
        print(formatCard(card, i))
    end
    if minCount == 0 then
        print("  [0] Skip")
    end

    while true do
        local input = prompt(nil)
        if not input then
            return nil
        end
        local selection = {}
        if input == "0" and minCount == 0 then
            return selection
        end

        for token in input:gmatch("[^,%s]+") do
            local index = tonumber(token)
            if not index or index < 1 or index > #cards then
                selection = nil
                break
            end
            table.insert(selection, cards[index])
            if #selection >= maxCount then
                break
            end
        end

        if selection and (#selection >= minCount or minCount == 0) then
            return selection
        end

        print("Invalid selection. Enter indices separated by commas.")
    end
end

local function displayCurrentNode(world, node)
    print(string.rep("-", 50))
    print(string.format("Current node: %s (Floor %d, %s)", node.id, node.floor or 0, node.type or "unknown"))
    print(string.rep("-", 50))
end

local function promptNextNode(world, node)
    local connections = node.connections or {}
    if #connections == 0 then
        print("No further nodes from here.")
        return nil
    end

    print("\nChoose next node (or type 'q' to exit map):")
    for i, nodeId in ipairs(connections) do
        local target = world.map.nodes[nodeId]
        local label = target and (target.type:upper() .. " (Floor " .. tostring(target.floor or "?") .. ")") or "Unknown"
        print(string.format("  [%d] %s - %s", i, nodeId, label))
    end

    while true do
        local input = prompt(nil)
        if not input then
            return nil
        end
        input = input:lower()
        if input == "q" or input == "quit" or input == "exit" then
            return nil
        end
        local choice = tonumber(input)
        if choice and connections[choice] then
            return connections[choice]
        end
        print("Invalid node selection. Try again or type 'q' to exit.")
    end
end

local function ensureAtStart(world)
    if world.currentNode then
        return true
    end
    local map = world.map
    if not map or not map.startNode then
        return false
    end
    return Map_ChooseNextNode.execute(world, map.startNode)
end

function MapCLI.play(world)
    if not world or not world.map then
        print("No map available.")
        return
    end

    world.mapEventOptions = {
        onOptionSelection = promptOptionSelection,
        onCardSelection = promptCardSelection
    }

    if not ensureAtStart(world) then
        print("Unable to enter the map.")
        world.mapEventOptions = nil
        return
    end

    MapEngine.advanceEvent(world, world.mapEventOptions)

    while true do
        local currentNode = MapEngine.getCurrentNode(world)
        if not currentNode then
            print("No active node. Exiting map loop.")
            break
        end

        if world.mapEvent then
            MapEngine.advanceEvent(world, world.mapEventOptions)
        end

        currentNode = MapEngine.getCurrentNode(world)
        if not currentNode then
            print("Traversal ended.")
            break
        end

        displayCurrentNode(world, currentNode)
        local nextNodeId = promptNextNode(world, currentNode)
        if not nextNodeId then
            print("Leaving the map.")
            break
        end

        local moved = Map_ChooseNextNode.execute(world, nextNodeId)
        if not moved then
            print("Failed to move to node " .. tostring(nextNodeId))
        end
    end

    world.mapEventOptions = nil
end

return MapCLI

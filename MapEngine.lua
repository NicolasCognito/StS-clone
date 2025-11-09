-- MAP ENGINE
-- Helper functions for map operations

local MapEngine = {}

-- Get the current node object
function MapEngine.getCurrentNode(world)
    if not world.currentNode or not world.map then
        return nil
    end
    return world.map.nodes[world.currentNode]
end

-- Get available next nodes (nodes connected to current node)
function MapEngine.getAvailableNodes(world)
    local currentNode = MapEngine.getCurrentNode(world)
    if not currentNode then
        return {}
    end

    local availableNodes = {}
    for _, nodeId in ipairs(currentNode.connections) do
        local node = world.map.nodes[nodeId]
        if node then
            table.insert(availableNodes, node)
        end
    end

    return availableNodes
end

-- Get all nodes on a specific floor
function MapEngine.getNodesOnFloor(world, floor)
    local nodes = {}
    for _, node in pairs(world.map.nodes) do
        if node.floor == floor then
            table.insert(nodes, node)
        end
    end
    return nodes
end

-- Check if player has Winged Boots with charges remaining
function MapEngine.hasWingedBoots(world)
    for _, relic in ipairs(world.player.relics) do
        if relic.id == "Winged_Boots" and relic.charges and relic.charges > 0 then
            return true, relic
        end
    end
    return false, nil
end

-- Display available nodes for user selection
function MapEngine.displayAvailableNodes(nodes)
    print("\nAvailable paths:")
    for i, node in ipairs(nodes) do
        local nodeTypeName = node.type:upper()
        print("  [" .. i .. "] Floor " .. node.floor .. " - " .. nodeTypeName .. " (" .. node.id .. ")")
    end
end

return MapEngine

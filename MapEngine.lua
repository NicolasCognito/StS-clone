-- MAP ENGINE
-- Helper utilities for querying map nodes/floors

local MapEngine = {}

function MapEngine.getCurrentNode(world)
    if not world.currentNode or not world.map then
        return nil
    end
    return world.map.nodes[world.currentNode]
end

function MapEngine.getNodesOnFloor(world, floor)
    if not world.map then
        return {}
    end

    local nodes = {}
    for _, node in pairs(world.map.nodes) do
        if node.floor == floor then
            table.insert(nodes, node)
        end
    end
    return nodes
end

return MapEngine


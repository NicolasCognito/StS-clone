-- MAP ENGINE
-- Helper functions for map queries only (no logic)

local MapEngine = {}

-- Get the current node object
function MapEngine.getCurrentNode(world)
    if not world.currentNode or not world.map then
        return nil
    end
    return world.map.nodes[world.currentNode]
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

return MapEngine

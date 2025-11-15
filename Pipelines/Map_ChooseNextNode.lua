-- MAP CHOOSE NEXT NODE PIPELINE
-- Validates map traversal and consumes Winged Boots charges when bypassing paths

local Map_ChooseNextNode = {}

local MapEngine = require("MapEngine")

local function displayNodeInfo(node)
    local nodeDesc = node.id .. " - Floor " .. node.floor .. " - " .. node.type:upper()
    print("  - " .. nodeDesc)
end

function Map_ChooseNextNode.execute(world, targetNodeId)
    if not world.map then
        print("No map loaded.")
        return false
    end

    local targetNode = world.map.nodes[targetNodeId]
    if not targetNode then
        print("Invalid node ID: " .. tostring(targetNodeId))
        return false
    end

    local currentNode = MapEngine.getCurrentNode(world)
    if not currentNode then
        world.currentNode = targetNodeId
        world.floor = targetNode.floor
        print("Moved to " .. targetNode.type:upper() .. " on floor " .. targetNode.floor)
        return true
    end

    local isConnected = false
    for _, connectedId in ipairs(currentNode.connections) do
        if connectedId == targetNodeId then
            isConnected = true
            break
        end
    end

    local usedWingedBoots = false
    if not isConnected then
        if world.wingedBootsCharges > 0 then
            if targetNode.floor == currentNode.floor + 1 then
                usedWingedBoots = true
                print("Using Winged Boots! (" .. world.wingedBootsCharges .. " -> " .. (world.wingedBootsCharges - 1) .. ")")
            else
                print("Winged Boots can only jump to the next floor.")
                return false
            end
        else
            print("Invalid move! Available nodes:")
            for _, connectedId in ipairs(currentNode.connections) do
                displayNodeInfo(world.map.nodes[connectedId])
            end
            return false
        end
    end

    world.currentNode = targetNodeId
    world.floor = targetNode.floor

    if usedWingedBoots then
        world.wingedBootsCharges = world.wingedBootsCharges - 1
        if world.wingedBootsCharges == 0 then
            print("Winged Boots has been fully consumed!")
        end
    end

    print("Moved to " .. targetNode.type:upper() .. " on floor " .. targetNode.floor)
    MapEngine.triggerNodeEvent(world, targetNode)

    return true
end

return Map_ChooseNextNode

-- CHOOSE NEXT NODE PIPELINE
-- world: the complete game state
-- targetNodeId: the ID of the node to move to
--
-- Handles:
-- - Validate move is legal (connected path or Winged Boots charges)
-- - Move player to target node
-- - Update floor number
-- - Consume Winged Boots charge if used
-- - Trigger node event (combat, rest, merchant, etc.)
--
-- Winged Boots:
-- - If world.wingedBootsCharges > 0, can choose any node on next floor
-- - Cannot choose same floor, skip floors, or go back
-- - Consumes 1 charge per use

local ChooseNextNode = {}

local MapEngine = require("MapEngine")

function ChooseNextNode.execute(world, targetNodeId)
    local currentNode = MapEngine.getCurrentNode(world)
    local targetNode = world.map.nodes[targetNodeId]

    -- Validate target node exists
    if not targetNode then
        print("Invalid node ID: " .. tostring(targetNodeId))
        return false
    end

    -- Check if this is the starting move (no current node)
    if not currentNode then
        world.currentNode = targetNodeId
        world.floor = targetNode.floor
        ChooseNextNode.displayNodeEntry(targetNode)
        return true
    end

    -- Determine if move is valid
    local isConnected = false
    for _, connectedId in ipairs(currentNode.connections) do
        if connectedId == targetNodeId then
            isConnected = true
            break
        end
    end

    local usedWingedBoots = false

    -- If not connected, check Winged Boots
    if not isConnected then
        if world.wingedBootsCharges > 0 then
            -- Winged Boots rules:
            -- 1. Can only choose nodes on next floor
            -- 2. Cannot choose same floor, skip floors, or go back
            local currentFloor = currentNode.floor
            local targetFloor = targetNode.floor

            if targetFloor == currentFloor + 1 then
                -- Valid Winged Boots move to next floor
                usedWingedBoots = true
                print("Using Winged Boots! (Charges: " .. world.wingedBootsCharges .. " -> " .. (world.wingedBootsCharges - 1) .. ")")
            else
                print("Invalid move! Winged Boots can only choose nodes on the next floor.")
                print("Current floor: " .. currentFloor .. ", Target floor: " .. targetFloor)
                return false
            end
        else
            print("Invalid move! Node " .. targetNodeId .. " is not connected to " .. currentNode.id)
            print("Available nodes:")
            for _, connectedId in ipairs(currentNode.connections) do
                local node = world.map.nodes[connectedId]
                ChooseNextNode.displayNodeInfo(node)
            end
            return false
        end
    end

    -- Move is valid - update world state
    world.currentNode = targetNodeId
    world.floor = targetNode.floor

    -- Consume Winged Boots charge if used
    if usedWingedBoots then
        world.wingedBootsCharges = world.wingedBootsCharges - 1
        if world.wingedBootsCharges == 0 then
            print("Winged Boots has been fully consumed!")
        end
    end

    ChooseNextNode.displayNodeEntry(targetNode)

    -- Trigger node event based on type
    ChooseNextNode.triggerNodeEvent(world, targetNode)

    return true
end

-- Display node info (for listing options)
function ChooseNextNode.displayNodeInfo(node)
    local nodeDesc = node.id .. " - Floor " .. node.floor .. " - " .. node.type:upper()
    if node.type == "combat" and node.difficulty then
        nodeDesc = nodeDesc .. " (" .. node.difficulty .. ")"
    end
    print("  - " .. nodeDesc)
end

-- Display node entry message
function ChooseNextNode.displayNodeEntry(node)
    local nodeDesc = node.type:upper()
    if node.type == "combat" and node.difficulty then
        nodeDesc = node.difficulty:upper() .. " " .. nodeDesc
    end
    print("Moved to " .. nodeDesc .. " on floor " .. node.floor)
end

-- Trigger the event for the current node type
function ChooseNextNode.triggerNodeEvent(world, node)
    -- TODO: Implement node event handlers
    -- For now, just print what would happen
    if node.type == "combat" then
        local difficultyDesc = node.difficulty or "normal"
        print("  -> " .. difficultyDesc:upper() .. " combat encounter! (not implemented yet)")
    elseif node.type == "rest" then
        print("  -> Rest site! (not implemented yet)")
    elseif node.type == "merchant" then
        print("  -> Merchant! (not implemented yet)")
    elseif node.type == "treasure" then
        print("  -> Treasure chest! (not implemented yet)")
    elseif node.type == "event" then
        print("  -> Random event! (not implemented yet)")
    end
end

return ChooseNextNode

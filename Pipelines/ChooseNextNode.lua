-- CHOOSE NEXT NODE PIPELINE
-- world: the complete game state
-- targetNodeId: the ID of the node to move to
--
-- Handles:
-- - Validate move is legal (connected or Winged Boots)
-- - Move player to target node
-- - Update floor number
-- - Consume Winged Boots charge if used
-- - Trigger node event (combat, rest, merchant, etc.)
--
-- Winged Boots:
-- - Allows choosing any node on next floor (ignoring paths)
-- - Cannot choose same floor, skip floors, or go back
-- - Has limited charges (3) across the run

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
        print("Starting at " .. targetNode.type .. " on floor " .. targetNode.floor)
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
        local hasBoots, bootsRelic = MapEngine.hasWingedBoots(world)

        if hasBoots then
            -- Winged Boots rules:
            -- 1. Can only choose nodes on next floor
            -- 2. Cannot choose same floor, skip floors, or go back
            local currentFloor = currentNode.floor
            local targetFloor = targetNode.floor

            if targetFloor == currentFloor + 1 then
                -- Valid Winged Boots move to next floor
                usedWingedBoots = true
                print("Using Winged Boots! (Charges remaining: " .. bootsRelic.charges .. " -> " .. (bootsRelic.charges - 1) .. ")")
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
                print("  - " .. connectedId .. " (" .. node.type .. ", floor " .. node.floor .. ")")
            end
            return false
        end
    end

    -- Move is valid - update world state
    world.currentNode = targetNodeId
    world.floor = targetNode.floor

    -- Consume Winged Boots charge if used
    if usedWingedBoots then
        for _, relic in ipairs(world.player.relics) do
            if relic.id == "Winged_Boots" then
                relic.charges = relic.charges - 1
                if relic.charges == 0 then
                    print("Winged Boots has been fully consumed!")
                end
                break
            end
        end
    end

    print("Moved to " .. targetNode.type .. " on floor " .. targetNode.floor)

    -- Trigger node event based on type
    ChooseNextNode.triggerNodeEvent(world, targetNode)

    return true
end

-- Trigger the event for the current node type
function ChooseNextNode.triggerNodeEvent(world, node)
    -- TODO: Implement node event handlers
    -- For now, just print what would happen
    print("  -> Entering " .. node.type .. " encounter...")

    if node.type == "combat" then
        -- TODO: Set up enemies for combat encounter
        print("  -> Combat encounter! (not implemented yet)")
    elseif node.type == "elite" then
        print("  -> Elite combat encounter! (not implemented yet)")
    elseif node.type == "boss" then
        print("  -> Boss combat encounter! (not implemented yet)")
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

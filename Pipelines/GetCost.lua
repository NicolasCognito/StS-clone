-- GET COST PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card to get the cost for
--
-- Handles:
-- - Calculate the current cost of a card
-- - Base cost from card.cost
-- - Cost reduction based on combat state (Blood for Blood)
-- - Future: other cost modifications (Corruption, Confused, etc.)
--
-- This is the centralized place for all cost calculation logic

local GetCost = {}

function GetCost.execute(world, player, card)
    -- Start with base cost
    local cost = card.cost

    -- Blood for Blood: reduce cost based on times HP was lost
    if card.costReductionPerHpLoss then
        local reduction = world.combat.timesHpLost * card.costReductionPerHpLoss
        cost = cost - reduction
    end

    -- Cost can't go below 0
    cost = math.max(0, cost)

    return cost
end

return GetCost

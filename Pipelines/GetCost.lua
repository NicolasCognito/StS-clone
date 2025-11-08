-- GET COST PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card to get the cost for
--
-- Handles:
-- - Calculate the current cost of a card
-- - For now, simply returns the base cost
-- - Later will handle cost modifications (like Blood for Blood)
--
-- This is the centralized place for all cost calculation logic

local GetCost = {}

function GetCost.execute(world, player, card)
    -- For now, just return the base cost
    -- Future: this is where we'll add cost reduction logic
    -- (e.g., Blood for Blood reduces cost based on HP lost this combat)

    return card.cost
end

return GetCost

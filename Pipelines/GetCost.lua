-- GET COST PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card to get the cost for
--
-- Handles:
-- - Calculate the current cost of a card
-- - Priority order:
--   1. costsZeroThisTurn (highest priority - costs 0 this turn)
--   2. Corruption power (Skills cost 0)
--   3. confused (from Confused status - random 0-3)
--   4. cost (base cost)
--   5. Cost reductions (Blood for Blood, etc.)
--
-- This is the centralized place for all cost calculation logic

local GetCost = {}

-- Helper to check if player has a power
local function hasPower(player, powerId)
    if not player.powers then return false end
    for _, power in ipairs(player.powers) do
        if power.id == powerId then
            return true
        end
    end
    return false
end

function GetCost.execute(world, player, card)
    -- HIGHEST PRIORITY: costsZeroThisTurn flag
    -- Used by: Bullet Time, Infernal Blade, potions, etc.
    if card.costsZeroThisTurn == 1 then
        return 0
    end

    -- CORRUPTION POWER: Skills cost 0
    if hasPower(player, "Corruption") and card.type == "SKILL" then
        return 0
    end

    -- Start with base cost
    -- If card has confused cost (from Confused status), use that instead
    local cost = card.confused or card.cost

    -- Blood for Blood: reduce cost based on times HP was lost
    -- This applies AFTER confused cost (if any)
    if card.costReductionPerHpLoss then
        local reduction = world.combat.timesHpLost * card.costReductionPerHpLoss
        cost = cost - reduction
    end

    -- Cost can't go below 0
    cost = math.max(0, cost)

    return cost
end

return GetCost

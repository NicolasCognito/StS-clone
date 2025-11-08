-- GET COST PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card to get the cost for
--
-- Handles:
-- - Calculate the current cost of a card
-- - Priority order:
--   1. permanentCostZero (permanent 0 cost for rest of combat)
--   2. costsZeroThisTurn (costs 0 this turn only)
--   3. Corruption power (Skills cost 0)
--   4. confused (from Confused status - random 0-3) or base cost
--   5. Cost reductions/increases:
--      - costReductionPerHpLoss (Blood for Blood, Masterful Stab with -1)
--      - costReductionPerDiscard (Eviscerate)
--      - costReductionPerPowerPlayed (Force Field)
--      - costReductionPerRetain (Sands of Time)
--      - retainCostReduction (Establishment power)
--   6. Enlightenment (cap cost at 1 if cost >= 2)
--   7. Minimum 0
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
    -- HIGHEST PRIORITY: permanentCostZero flag
    -- Used by: Setup, Forethought, Madness, Chrysalis, Metamorphosis
    if card.permanentCostZero == 1 then
        return 0
    end

    -- SECOND PRIORITY: costsZeroThisTurn flag
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

    -- COST REDUCTIONS/INCREASES:

    -- Blood for Blood: reduce cost based on times HP was lost
    -- Masterful Stab: INCREASE cost (uses negative costReductionPerHpLoss value)
    if card.costReductionPerHpLoss then
        local reduction = world.combat.timesHpLost * card.costReductionPerHpLoss
        cost = cost - reduction
    end

    -- Eviscerate: reduce cost based on cards discarded this turn
    if card.costReductionPerDiscard then
        local reduction = (world.combat.cardsDiscardedThisTurn or 0) * card.costReductionPerDiscard
        cost = cost - reduction
    end

    -- Force Field: reduce cost based on Powers played this combat
    if card.costReductionPerPowerPlayed then
        local reduction = (world.combat.powersPlayedThisCombat or 0) * card.costReductionPerPowerPlayed
        cost = cost - reduction
    end

    -- Sands of Time: reduce cost based on times retained
    if card.costReductionPerRetain and card.timesRetained then
        local reduction = card.timesRetained * card.costReductionPerRetain
        cost = cost - reduction
    end

    -- Establishment power: reduce cost for retained cards
    if card.retainCostReduction then
        cost = cost - card.retainCostReduction
    end

    -- ENLIGHTENMENT: Cap cost at 1 for cards that cost 2+
    -- enlightenedThisTurn: only this turn (Enlightenment base)
    -- enlightenedPermanent: rest of combat (Enlightenment+)
    if (card.enlightenedThisTurn or card.enlightenedPermanent) and cost >= 2 then
        cost = 1
    end

    -- Cost can't go below 0
    cost = math.max(0, cost)

    return cost
end

return GetCost

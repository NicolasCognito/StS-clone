-- APPLY STATUS EFFECT PIPELINE
-- Processes ON_STATUS_GAIN events from the queue
--
-- Event should have:
-- - target: character gaining the status
-- - effectType: type of status (Poison, Vulnerable, Weak, Strength, etc.)
-- - amount: amount of the status effect
-- - source: what caused this effect (card, enemy, relic)
--
-- Handles:
-- - Applying status effects to character
-- - Status-specific rules (caps, interactions, etc.)
-- - Combat logging

local ApplyStatusEffect = {}

function ApplyStatusEffect.execute(world, event)
    local target = event.target
    local effectType = event.effectType
    local amount = event.amount or 0
    local source = event.source

    -- Initialize status object if needed
    if not target.status then
        target.status = {}
    end

    -- Apply the status based on type
    if effectType == "Poison" then
        target.status.poison = (target.status.poison or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " poison")

    elseif effectType == "Vulnerable" then
        target.status.vulnerable = (target.status.vulnerable or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " vulnerable")

    elseif effectType == "Weak" then
        target.status.weak = (target.status.weak or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " weak")

    elseif effectType == "Strength" then
        target.status.strength = (target.status.strength or 0) + amount
        table.insert(world.log, target.name .. " gained " .. amount .. " strength")

    else
        table.insert(world.log, "Unknown status effect: " .. effectType)
    end
end

return ApplyStatusEffect

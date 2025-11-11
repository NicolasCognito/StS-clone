-- HEAL PIPELINE
-- Processes ON_HEAL events from the queue
--
-- Event should have:
-- - target: character being healed
-- - amount: heal amount (optional, can come from source.healAmount)
-- - source: the card/relic triggering the heal (optional, for logging)
-- - maxHpIncrease: optional amount to increase max HP (default 0)
--
-- Handles:
-- - Adding HP to character
-- - Capping at max HP
-- - Optional max HP increase
-- - Combat logging

local Heal = {}

function Heal.execute(world, event)
    local target = event.target
    local source = event.source or event.relic  -- Support both new and old format
    local maxHpIncrease = event.maxHpIncrease or 0

    -- Get heal amount from event.amount or source.healAmount
    local amount = event.amount or (source and source.healAmount) or 0

    -- Increase max HP if specified
    if maxHpIncrease > 0 then
        target.maxHp = target.maxHp + maxHpIncrease
    end

    -- Heal
    local oldHp = target.hp
    target.hp = math.min(target.hp + amount, target.maxHp)
    local actualHealing = target.hp - oldHp

    -- Log with source name if available
    local sourceName = (source and source.name) or "unknown source"
    local logMsg = target.name .. " healed " .. actualHealing .. " HP"
    if maxHpIncrease > 0 then
        logMsg = logMsg .. " and gained " .. maxHpIncrease .. " Max HP"
    end
    logMsg = logMsg .. " (from " .. sourceName .. ")"
    table.insert(world.log, logMsg)
end

return Heal

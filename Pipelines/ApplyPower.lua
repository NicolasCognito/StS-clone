-- APPLY POWER PIPELINE
-- world: the complete game state
-- event: event with target and powerTemplate
--
-- Event should have:
-- - target: character to receive the power (player or enemy)
-- - powerTemplate: the power definition from Powers.lua
--
-- Handles:
-- - Initialize target.powers if needed
-- - Check if power already exists (some powers stack, some don't)
-- - Add power to target.powers[]
-- - Combat logging
--
-- Powers last entire combat unless removed
-- Power effects are checked in other pipelines (GetCost, PlayCard, etc.)

local ApplyPower = {}

function ApplyPower.execute(world, event)
    local target = event.target
    local powerTemplate = event.powerTemplate

    -- Initialize powers table if needed
    if not target.powers then
        target.powers = {}
    end

    -- Check if power already exists
    local alreadyHas = false
    for _, power in ipairs(target.powers) do
        if power.id == powerTemplate.id then
            alreadyHas = true
            break
        end
    end

    -- Add power if not already present
    -- (For now, powers don't stack - Corruption can only be applied once)
    if not alreadyHas then
        -- Create a copy of the power
        local newPower = {}
        for k, v in pairs(powerTemplate) do
            newPower[k] = v
        end

        table.insert(target.powers, newPower)
        table.insert(world.log, target.name .. " gained " .. newPower.name)
    end
end

return ApplyPower

-- HEAL PIPELINE
-- Processes ON_HEAL events from the queue
--
-- Event should have:
-- - target: character being healed
-- - relic: the relic triggering the heal (contains healAmount)
--
-- Handles:
-- - Adding HP to character
-- - Capping at max HP
-- - Combat logging

local Heal = {}

function Heal.execute(world, event)
    local target = event.target
    local relic = event.relic

    local amount = relic.healAmount or 0

    local oldHp = target.hp
    target.hp = math.min(target.hp + amount, target.maxHp)
    local actualHealing = target.hp - oldHp

    -- Apply caps to target (HP, block, status effects)
    world.queue:push({
        type = "ON_APPLY_CAPS",
        character = target
    })

    table.insert(world.log, target.name .. " healed " .. actualHealing .. " HP (from " .. relic.name .. ")")
end

return Heal

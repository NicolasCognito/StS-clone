-- DEATH PIPELINE
-- Processes ON_DEATH events from the queue
--
-- Event should have:
-- - entity: the character that died (hp <= 0)
--
-- Handles:
-- - Logging death
-- - Setting combat result flags (victory/defeat)
-- - Future: triggering on-death effects, relics, etc.
--
-- Note: This pipeline does NOT remove enemies from combat.enemies
-- That will be handled in part 2 of the death system refactor

local Death = {}

function Death.execute(world, event)
    local entity = event.entity
    local source = event.source
    local damage = event.damage
    local card = event.card

    if not entity then
        table.insert(world.log, "Warning: Death event with no entity")
        return
    end

    -- Log the death with details
    local deathMsg = entity.name .. " has been defeated"
    if source then
        deathMsg = deathMsg .. " by " .. source.name
    end
    if card and card.name then
        deathMsg = deathMsg .. " (" .. card.name .. ")"
    end
    deathMsg = deathMsg .. "!"
    table.insert(world.log, deathMsg)

    -- Set player death flag if player died
    if entity == world.player then
        world.combat.playerDied = true
    else
        -- Mark enemy as dead
        entity.dead = true
    end

    -- Future: Trigger on-death effects, relics, powers, etc.
    -- Example: "When an enemy dies, gain 1 energy" or "When you kill an enemy with poison, draw a card"
end

return Death

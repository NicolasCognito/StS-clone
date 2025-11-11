-- MAP START COMBAT PIPELINE
-- Initiates a combat encounter from within the map system
-- Stores combat configuration for MapCLI to detect and execute

local Map_StartCombat = {}

function Map_StartCombat.execute(world, event)
    if not event.enemies then
        error("MAP_START_COMBAT requires enemies in event payload")
    end

    -- Store combat configuration for MapCLI to detect
    world.pendingCombat = {
        enemies = event.enemies,
        onVictory = event.onVictory,  -- Optional: "continue" (default) or "exit"
        onDefeat = event.onDefeat      -- Optional: "exit" (default) or "continue"
    }

    -- Signal that combat should start
    return {needsCombat = true}
end

return Map_StartCombat

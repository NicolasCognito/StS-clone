-- CHANGE STANCE PIPELINE
-- Handles changing the player's stance
--
-- Event should have:
-- - newStance: The stance object to switch to (should have name, onEnter, onExit)
--
-- Flow:
-- 1. Execute onExit for old stance (if exists)
-- 2. Execute onEnter for new stance (if exists)
-- 3. Update player.currentStance
--
-- Stance object structure:
-- {
--   name = "StanceName",
--   onEnter = function(world, player) ... end,  -- (optional)
--   onExit = function(world, player) ... end    -- (optional)
-- }

local ChangeStance = {}

function ChangeStance.execute(world, event)
    local player = world.player
    local newStance = event.newStance
    local oldStance = player.currentStance

    -- Exit old stance if it exists and has an onExit callback
    if oldStance and oldStance.onExit then
        oldStance.onExit(world, player)
        table.insert(world.log, player.name .. " exited " .. oldStance.name)
    end

    -- Enter new stance if it has an onEnter callback
    if newStance and newStance.onEnter then
        newStance.onEnter(world, player)
        table.insert(world.log, player.name .. " entered " .. newStance.name)
    end

    -- Update current stance
    player.currentStance = newStance

    -- Log stance change (if not just exiting a stance)
    if newStance then
        table.insert(world.log, player.name .. " is now in " .. newStance.name)
    elseif oldStance then
        table.insert(world.log, player.name .. " exited " .. oldStance.name .. " (no new stance)")
    end
end

return ChangeStance

-- CHANGE STANCE PIPELINE
-- Handles changing the player's stance
--
-- Event should have:
-- - newStance: The stance name (string: "Calm", "Wrath", "Divinity", or nil for neutral)
--
-- Flow:
-- 1. Exit old stance (hardcoded checks for old stance effects)
-- 2. Update player.currentStance
-- 3. Enter new stance (hardcoded checks for new stance effects)
--
-- All stance logic lives here - no callbacks in stance definitions!
-- This allows Ctrl+F to find all stance interactions in one place.

local ChangeStance = {}

function ChangeStance.execute(world, event)
    local player = world.player
    local oldStance = player.currentStance
    local newStance = event.newStance

    -- ============================================================================
    -- EXIT OLD STANCE
    -- ============================================================================
    if oldStance == "Calm" then
        -- Calm exit: Gain 2 energy
        -- TODO: Check for relics that modify this (e.g., Violet Lotus)
        player.energy = player.energy + 2
        table.insert(world.log, player.name .. " exited Calm and gained 2 energy")

    elseif oldStance == "Wrath" then
        -- Wrath exit: No special effect in base game
        table.insert(world.log, player.name .. " exited Wrath")

    elseif oldStance == "Divinity" then
        -- Divinity exit: No special effect
        table.insert(world.log, player.name .. " exited Divinity")
    end

    -- ============================================================================
    -- SWAP STANCE
    -- ============================================================================
    player.currentStance = newStance

    -- ============================================================================
    -- ENTER NEW STANCE
    -- ============================================================================
    if newStance == "Calm" then
        -- Calm enter: No immediate effect, but exit gives energy
        table.insert(world.log, player.name .. " entered Calm")

    elseif newStance == "Wrath" then
        -- Wrath enter: No immediate effect, but damage dealt/taken is doubled
        -- (This will be checked in DealAttackDamage pipeline)
        table.insert(world.log, player.name .. " entered Wrath")

    elseif newStance == "Divinity" then
        -- Divinity enter: Gain 3 energy, triple damage, gain 3 energy at start of turn
        -- TODO: Implement energy gain
        player.energy = player.energy + 3
        table.insert(world.log, player.name .. " entered Divinity and gained 3 energy")

    elseif newStance == nil then
        -- Neutral stance (no special effects)
        if oldStance then
            table.insert(world.log, player.name .. " returned to Neutral stance")
        end
    end
end

return ChangeStance

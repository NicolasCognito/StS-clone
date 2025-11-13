-- CHANNEL ORB PIPELINE
-- Processes ON_CHANNEL_ORB events from the queue
--
-- Event should have:
-- - orbType: The type of orb to channel (string: "Lightning", "Frost", "Dark", "Plasma")
--
-- Handles:
-- - Creating orb instance (copies definition data)
-- - Evoking leftmost orb if slots are full (FIFO)
-- - Adding new orb to rightmost position
-- - Combat logging
--
-- Orb instances are minimal:
-- - All orbs: {id = "OrbType", baseDamage/baseBlock/basePassive/damageIncrement/energyGain}
-- - Dark orbs additionally track: accumulatedDamage (instance state)
--
-- Focus is applied when orbs are used (passive/evoke), not when channeled

local ChannelOrb = {}

local OrbData = require("Data.orbs")

function ChannelOrb.execute(world, event)
    local player = world.player
    local orbType = event.orbType
    local orbDef = OrbData[orbType]

    if not orbDef then
        table.insert(world.log, "ERROR: Unknown orb type: " .. tostring(orbType))
        return
    end

    -- Check if slots are full - evoke leftmost orb FIRST (FIFO)
    if #player.orbs >= player.maxOrbs then
        world.queue:push({
            type = "ON_EVOKE_ORB",
            index = 1  -- Leftmost orb
        }, "FIRST")
    end

    -- Create orb instance by copying definition
    local orbInstance = ChannelOrb.createOrbInstance(orbDef)

    -- Add to rightmost position
    table.insert(player.orbs, orbInstance)

    table.insert(world.log, player.name .. " channeled " .. orbType .. " orb")

    -- Track channeled orbs for Thunder Strike / Blizzard cards
    if world.combat then
        local trackField = string.lower(orbType) .. "ChanneledThisCombat"
        if world.combat[trackField] ~= nil then
            world.combat[trackField] = world.combat[trackField] + 1
        end
    end
end

-- Create orb instance by copying definition table
function ChannelOrb.createOrbInstance(orbDef)
    -- Simple table copy
    local orb = {}
    for k, v in pairs(orbDef) do
        orb[k] = v
    end

    -- Dark orb: Initialize accumulation with baseDamage
    if orb.id == "Dark" then
        orb.accumulatedDamage = orb.baseDamage or 6
    end

    return orb
end

return ChannelOrb

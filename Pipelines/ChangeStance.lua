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
        -- Calm exit: Gain 2 energy (3 with Violet Lotus)
        local Utils = require("utils")
        local energyGain = 2
        if Utils.hasRelic(player, "Violet_Lotus") then
            energyGain = 3
        end

        player.energy = player.energy + energyGain
        table.insert(world.log, player.name .. " exited Calm and gained " .. energyGain .. " energy")

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

    -- ============================================================================
    -- STANCE CHANGE TRIGGERS (only if stance actually changed)
    -- ============================================================================
    if oldStance ~= newStance then
        -- Mental Fortress: gain block on stance change
        if player.status and player.status.mental_fortress and player.status.mental_fortress > 0 then
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = player.status.mental_fortress
            })
        end

        -- Rushdown: draw 2 cards when entering Wrath
        if newStance == "Wrath" and player.status and player.status.rushdown and player.status.rushdown > 0 then
            for i = 1, 2 do
                world.queue:push({type = "ON_DRAW"})
            end
        end

        -- Flurry of Blows: return from discard (respecting hand size)
        world.queue:push({
            type = "ON_CUSTOM_EFFECT",
            effect = function()
                local Utils = require("utils")
                local maxHandSize = player.maxHandSize or 10
                local currentHandSize = Utils.getCardCountByState(player.combatDeck, "HAND")

                for _, card in ipairs(player.combatDeck) do
                    if card.id == "FlurryOfBlows" and card.state == "DISCARD_PILE" then
                        if currentHandSize < maxHandSize then
                            card.state = "HAND"
                            currentHandSize = currentHandSize + 1
                            table.insert(world.log, "Flurry of Blows returned to hand!")
                        else
                            -- Hand is full, can't return
                            break
                        end
                    end
                end
            end
        })
    end
end

return ChangeStance

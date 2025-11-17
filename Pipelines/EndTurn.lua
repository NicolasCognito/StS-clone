-- END TURN PIPELINE
-- world: the complete game state
-- player: the player whose turn is ending
--
-- Handles:
-- - Trigger relics' onEndCombat effects
-- - Process effect queue
-- - Handle Retain mechanics (don't discard retained cards)
-- - Discard remaining hand
-- - Clear temporary turn flags
-- - Reset energy and turn counters
-- - Combat logging

local EndTurn = {}

local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local OrbPassive = require("Pipelines.OrbPassive")
local Utils = require("utils")
local StatusEffects = require("Data.statuseffects")

-- Helper: Call onEndTurn hooks for all status effects on a combatant
local function triggerStatusHooks(world, combatant)
    if not combatant.status then return end

    for statusKey, statusDef in pairs(StatusEffects) do
        if statusDef.onEndTurn and combatant.status[statusKey] and combatant.status[statusKey] > 0 then
            statusDef.onEndTurn(world, combatant)
        end
    end
end

-- Helper function: Discard hand and cleanup turn state
-- Extracted to support "queue as continuation" pattern for Well-Laid Plans
function EndTurn.discardHandAndCleanup(world, player)
    local hasEstablishment = Utils.hasPower(player, "Establishment")

    -- Process each card in hand: retain or discard
    for _, card in ipairs(player.combatDeck) do
        if card.state == "HAND" then
            -- Check if card has Retain keyword (permanent or temporary)
            if card.retain or card.retainThisTurn then
                -- Don't discard, but trigger retain effects
                card.timesRetained = (card.timesRetained or 0) + 1

                -- Establishment power: reduce cost by 1 for each turn retained
                if hasEstablishment then
                    card.retainCostReduction = (card.retainCostReduction or 0) + 1
                end

                -- Push ON_RETAIN event to trigger retention effects
                world.queue:push({
                    type = "ON_RETAIN",
                    card = card,
                    player = player
                })

                -- Card stays in hand (don't change state)
                table.insert(world.log, card.name .. " was retained")
            else
                -- Normal discard via event queue
                world.queue:push({
                    type = "ON_DISCARD",
                    card = card,
                    player = player
                })
            end
        end
    end

    -- Process all discard/retain events
    ProcessEventQueue.execute(world)

    -- Clear temporary turn-based flags from ALL cards
    for _, card in ipairs(player.combatDeck) do
        -- Clear "this turn" effects
        if card.costsZeroThisTurn then
            card.costsZeroThisTurn = nil
        end
        if card.enlightenedThisTurn then
            card.enlightenedThisTurn = nil
        end
    end

    -- Reset turn-based combat trackers
    world.combat.cardsDiscardedThisTurn = 0

    -- Reset energy for next turn
    player.energy = player.maxEnergy

    -- Clear shadow copies created during duplication
    -- Shadows have already been discarded/exhausted, so just clear the table
    world.DuplicationShadowCards = {}
end

function EndTurn.execute(world, player)
    table.insert(world.log, "--- End of Player Turn ---")

    -- Trigger all relics' onEndCombat effects
    for _, relic in ipairs(player.relics) do
        if relic.onEndCombat then
            relic:onEndCombat(world, player)
        end
    end

    -- Process all queued events from relics
    ProcessEventQueue.execute(world)

    -- Trigger orb passive effects (Lightning damage, Frost block, Dark accumulation)
    OrbPassive.execute(world)

    -- Process all queued events from orb passives
    ProcessEventQueue.execute(world)

    -- Frozen Core: If empty orb slots, channel 1 Frost
    if Utils.hasRelic(player, "FrozenCore") and #player.orbs < player.maxOrbs then
        world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Frost"})
        ProcessEventQueue.execute(world)
    end

    -- Trigger onEndTurn hooks for all status effects on player
    triggerStatusHooks(world, player)

    -- Trigger onEndTurn hooks for all status effects on enemies
    if world.enemies then
        for _, enemy in ipairs(world.enemies) do
            if enemy.hp > 0 then
                triggerStatusHooks(world, enemy)
            end
        end
    end

    -- Process any events queued by status effect hooks
    ProcessEventQueue.execute(world)

    -- Track HP loss for Emotion Chip
    if player.hp < world.combat.hpAtTurnStart then
        world.combat.lastTurnLostHp = true
    end

    -- Like Water: If in Calm stance, gain block at end of turn
    if player.status and player.status.like_water and player.status.like_water > 0 then
        if player.currentStance == "Calm" then
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = player.status.like_water,
                source = "Like Water"
            })
            ProcessEventQueue.execute(world)
        end
    end

    -- Clear Bullet Time / No Draw style effects at end of player turn
    if player.status then
        player.status.no_draw = nil
    end

    -- NOTE: Status effects (vulnerable, weak, frail, etc.) are now ticked down
    -- in the EndRound pipeline, not here. This is because they are "End of Round"
    -- effects, not "End of Turn" effects.

    -- Handle Retain mechanics and discard hand
    -- Always use "queue as continuation" pattern for consistency

    -- Well-Laid Plans: Let player choose cards to retain
    if player.status and player.status.well_laid_plans and player.status.well_laid_plans > 0 then
        local retainCount = player.status.well_laid_plans

        -- Step 1: Request context (FIRST priority - executes immediately)
        world.queue:push({
            type = "COLLECT_CONTEXT",
            contextProvider = {
                type = "cards",
                stability = "temp",
                source = "combat",
                count = {min = 0, max = retainCount},
                filter = function(_, _, _, card)
                    return card.state == "HAND" and not card.ethereal and not card.retain
                end
            }
        }, "FIRST")

        -- Step 2: Mark selected cards as retained (runs AFTER context collected)
        world.queue:push({
            type = "ON_CUSTOM_EFFECT",
            effect = function()
                local selectedCards = world.combat.tempContext or {}
                for _, card in ipairs(selectedCards) do
                    card.retainThisTurn = true
                    table.insert(world.log, card.name .. " will be retained (Well-Laid Plans)")
                end
            end
        })
    end

    -- Always queue cleanup and completion (runs immediately if no context needed)
    world.queue:push({
        type = "ON_CUSTOM_EFFECT",
        effect = function()
            EndTurn.discardHandAndCleanup(world, player)
            table.insert(world.log, player.id .. " ended turn")
            -- Signal completion to CombatEngine
            world.combat.endTurnComplete = true
        end
    })

    -- Process queue - might pause for context collection
    local result = ProcessEventQueue.execute(world)
    return result  -- {needsContext=true} or nil
end

return EndTurn

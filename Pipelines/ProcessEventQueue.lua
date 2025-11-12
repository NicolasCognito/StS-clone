-- PROCESS EVENT QUEUE PIPELINE
-- Routes and processes all queued events until queue is empty
--
-- Events are created by:
-- - Cards' onPlay functions
-- - Enemies' executeIntent functions
-- - Relics' onEndCombat functions
--
-- Event types:
-- - COLLECT_CONTEXT: requests context collection (pauses queue processing)
-- - ON_DAMAGE: routes to DealDamage, then ApplyCaps
-- - ON_NON_ATTACK_DAMAGE: routes to DealNonAttackDamage, then ApplyCaps
-- - ON_BLOCK: routes to ApplyBlock, then ApplyCaps
-- - ON_HEAL: routes to Heal, then ApplyCaps
-- - ON_STATUS_GAIN: routes to ApplyStatusEffect, then ApplyCaps
-- - ON_DRAW: routes to DrawCard
-- - ON_DISCARD: routes to Discard
-- - ON_ACQUIRE_CARD: routes to AcquireCard
-- - ON_APPLY_POWER: routes to ApplyPower
-- - ON_EXHAUST: routes to Exhaust
-- - ON_CUSTOM_EFFECT: routes to CustomEffect
-- - AFTER_CARD_PLAYED: routes to AfterCardPlayed
-- - ON_DEATH: routes to Death
--
-- ApplyCaps is called directly after stat-modifying effects (no event needed)
-- Simple linear processing (no recursion)

local ProcessEventQueue = {}

local DealDamage = require("Pipelines.DealDamage")
local DealNonAttackDamage = require("Pipelines.DealNonAttackDamage")
local ApplyBlock = require("Pipelines.ApplyBlock")
local Heal = require("Pipelines.Heal")
local ApplyStatusEffect = require("Pipelines.ApplyStatusEffect")
local DrawCard = require("Pipelines.DrawCard")
local Discard = require("Pipelines.Discard")
local AcquireCard = require("Pipelines.AcquireCard")
local ApplyPower = require("Pipelines.ApplyPower")
local Exhaust = require("Pipelines.Exhaust")
local CustomEffect = require("Pipelines.CustomEffect")
local ClearContext = require("Pipelines.ClearContext")
local ApplyCaps = require("Pipelines.ApplyCaps")
local AfterCardPlayed = require("Pipelines.AfterCardPlayed")
local Death = require("Pipelines.Death")
local ChannelOrb = require("Pipelines.ChannelOrb")
local EvokeOrb = require("Pipelines.EvokeOrb")
local QueueOver = require("Pipelines.EventQueueOver")
function ProcessEventQueue.execute(world)
    while not world.queue:isEmpty() do
        local event = world.queue:next()

        -- Pre-process: evaluate all function fields
        -- This allows cards to use lazy evaluation for context
        for key, value in pairs(event) do
            if type(value) == "function" then
                event[key] = value()  -- Replace function with its result
            end
        end

        if event.type == "COLLECT_CONTEXT" then
            -- Check if context already exists (for stable context reuse)
            local stability = event.stability
                or (event.contextProvider and event.contextProvider.stability)
                or "temp"
            local contextExists = (stability == "stable" and world.combat.stableContext ~= nil) or
                                 (stability == "temp" and world.combat.tempContext ~= nil)

            if not contextExists then
                -- Context not yet collected - put event back and pause processing
                world.queue:push(event, "FIRST")
                world.combat.contextRequest = {
                    card = event.card,  -- Card that needs context (for CombatEngine to resume)
                    contextProvider = event.contextProvider,
                    stability = stability
                }
                return {needsContext = true}
            end
            -- Context exists - event consumed, continue to next event

        elseif event.type == "ON_DAMAGE" then
            DealDamage.execute(world, event)
            -- Apply caps to all characters after damage
            ApplyCaps.execute(world)

        elseif event.type == "ON_NON_ATTACK_DAMAGE" then
            DealNonAttackDamage.execute(world, event)
            -- Apply caps to all characters after damage
            ApplyCaps.execute(world)

        elseif event.type == "ON_BLOCK" then
            ApplyBlock.execute(world, event)
            -- Apply caps to all characters after block gain
            ApplyCaps.execute(world)

        elseif event.type == "ON_HEAL" then
            Heal.execute(world, event)
            -- Apply caps to all characters after healing
            ApplyCaps.execute(world)

        elseif event.type == "ON_STATUS_GAIN" then
            ApplyStatusEffect.execute(world, event)
            -- Apply caps to all characters after status gain
            ApplyCaps.execute(world)

        elseif event.type == "ON_DRAW" then
            DrawCard.execute(world, event.player, event.count)

        elseif event.type == "ON_DISCARD" then
            Discard.execute(world, event)

        elseif event.type == "ON_ACQUIRE_CARD" then
            AcquireCard.execute(world, event.player, event.cardTemplate, event.tags)

        elseif event.type == "ON_APPLY_POWER" then
            ApplyPower.execute(world, event)

        elseif event.type == "ON_EXHAUST" then
            Exhaust.execute(world, event)

        elseif event.type == "ON_CUSTOM_EFFECT" then
            CustomEffect.execute(world, event)

        elseif event.type == "CLEAR_CONTEXT" then
            ClearContext.execute(world, event)

        elseif event.type == "AFTER_CARD_PLAYED" then
            AfterCardPlayed.execute(world, event.player)

        elseif event.type == "ON_DEATH" then
            Death.execute(world, event)

        elseif event.type == "ON_CHANNEL_ORB" then
            ChannelOrb.execute(world, event)

        elseif event.type == "ON_EVOKE_ORB" then
            EvokeOrb.execute(world, event)

        else
            table.insert(world.log, "Unknown event type: " .. event.type)
        end
    end

    -- Queue is now empty - run cleanup
    local queueOverResult = QueueOver.execute(world)
    if queueOverResult then
        return queueOverResult
    end
end

return ProcessEventQueue

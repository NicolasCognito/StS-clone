-- PROCESS EVENT QUEUE PIPELINE
-- Routes and processes all queued events until queue is empty
--
-- Events are created by:
-- - Cards' onPlay functions
-- - Enemies' executeIntent functions
-- - Relics' onEndCombat functions
--
-- Uses curated list for complex routing (context collection, ApplyCaps calls)
-- Uses default route table for simple pipeline dispatching
-- Simple linear processing (no recursion)
--
-- ARCHITECTURAL NOTE: This pattern separates complex routing from simple dispatch.
-- SpecialBehaviors (if-else chain) handles events needing extra logic (ApplyCaps, etc).
-- DefaultRoutes (table lookup) handles straightforward event->pipeline mapping.
-- Execution order within each category:
--   - SpecialBehaviors: controlled by if-else chain order (deterministic)
--   - DefaultRoutes: order doesn't matter (single event processed at a time)
-- If event ordering becomes critical, move to SpecialBehaviors or introduce priority queue.

local ProcessEventQueue = {}

local DealAttackDamage = require("Pipelines.DealAttackDamage")
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
local Scry = require("Pipelines.Scry")
local QueueOver = require("Pipelines.EventQueueOver")

-- Curated list of event types requiring special handling
local SpecialBehaviors = {
    "COLLECT_CONTEXT",
    "ON_ATTACK_DAMAGE",
    "ON_NON_ATTACK_DAMAGE",
    "ON_BLOCK",
    "ON_HEAL",
    "ON_STATUS_GAIN"
}

-- Default route table: simple event type -> pipeline mapping
local DefaultRoutes = {
    ON_DRAW = function(world, event)
        DrawCard.execute(world, event.player, event.count)
    end,
    ON_DISCARD = function(world, event)
        Discard.execute(world, event)
    end,
    ON_ACQUIRE_CARD = function(world, event)
        AcquireCard.execute(world, event.player, event.cardTemplate, event.tags)
    end,
    ON_APPLY_POWER = function(world, event)
        ApplyPower.execute(world, event)
    end,
    ON_EXHAUST = function(world, event)
        Exhaust.execute(world, event)
    end,
    ON_CUSTOM_EFFECT = function(world, event)
        CustomEffect.execute(world, event)
    end,
    CLEAR_CONTEXT = function(world, event)
        ClearContext.execute(world, event)
    end,
    AFTER_CARD_PLAYED = function(world, event)
        AfterCardPlayed.execute(world, event.player or world.player)
    end,
    ON_DEATH = function(world, event)
        Death.execute(world, event)
    end,
    ON_CHANNEL_ORB = function(world, event)
        ChannelOrb.execute(world, event)
    end,
    ON_EVOKE_ORB = function(world, event)
        EvokeOrb.execute(world, event)
    end,
    ON_SCRY = function(world, event)
        Scry.execute(world, event)
    end
}
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

        -- SPECIAL BEHAVIORS (curated list)

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

        elseif event.type == "ON_ATTACK_DAMAGE" then
            DealAttackDamage.execute(world, event)
            ApplyCaps.execute(world)

        elseif event.type == "ON_NON_ATTACK_DAMAGE" then
            DealNonAttackDamage.execute(world, event)
            ApplyCaps.execute(world)

        elseif event.type == "ON_BLOCK" then
            ApplyBlock.execute(world, event)
            ApplyCaps.execute(world)

        elseif event.type == "ON_HEAL" then
            Heal.execute(world, event)
            ApplyCaps.execute(world)

        elseif event.type == "ON_STATUS_GAIN" then
            ApplyStatusEffect.execute(world, event)
            ApplyCaps.execute(world)

        else
            -- DEFAULT ROUTE: Use routing table
            local routeHandler = DefaultRoutes[event.type]
            if routeHandler then
                routeHandler(world, event)
            else
                table.insert(world.log, "Unknown event type: " .. event.type)
            end
        end
    end

    -- Queue is now empty - run cleanup
    local queueOverResult = QueueOver.execute(world)
    if queueOverResult then
        return queueOverResult
    end
end

return ProcessEventQueue

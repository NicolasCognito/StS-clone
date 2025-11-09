-- PROCESS EFFECT QUEUE PIPELINE
-- Routes and processes all queued events until queue is empty
--
-- Events are created by:
-- - Cards' onPlay functions
-- - Enemies' executeIntent functions
-- - Relics' onEndCombat functions
--
-- Event types:
-- - ON_DAMAGE: routes to DealDamage, then ApplyCaps
-- - ON_NON_ATTACK_DAMAGE: routes to DealNonAttackDamage, then ApplyCaps
-- - ON_BLOCK: routes to ApplyBlock, then ApplyCaps
-- - ON_HEAL: routes to Heal, then ApplyCaps
-- - ON_STATUS_GAIN: routes to ApplyStatusEffect, then ApplyCaps
-- - ON_DRAW: routes to DrawCard
-- - ON_ACQUIRE_CARD: routes to AcquireCard
-- - ON_APPLY_POWER: routes to ApplyPower
-- - ON_EXHAUST: routes to Exhaust
-- - ON_CUSTOM_EFFECT: routes to CustomEffect
-- - AFTER_CARD_PLAYED: routes to AfterCardPlayed
--
-- ApplyCaps is called directly after stat-modifying effects (no event needed)
-- Simple linear processing (no recursion)

local ProcessEffectQueue = {}

local DealDamage = require("Pipelines.DealDamage")
local DealNonAttackDamage = require("Pipelines.DealNonAttackDamage")
local ApplyBlock = require("Pipelines.ApplyBlock")
local Heal = require("Pipelines.Heal")
local ApplyStatusEffect = require("Pipelines.ApplyStatusEffect")
local DrawCard = require("Pipelines.DrawCard")
local AcquireCard = require("Pipelines.AcquireCard")
local ApplyPower = require("Pipelines.ApplyPower")
local Exhaust = require("Pipelines.Exhaust")
local CustomEffect = require("Pipelines.CustomEffect")
local ApplyCaps = require("Pipelines.ApplyCaps")
local AfterCardPlayed = require("Pipelines.AfterCardPlayed")

function ProcessEffectQueue.execute(world)
    while not world.queue:isEmpty() do
        local event = world.queue:next()

        if event.type == "ON_DAMAGE" then
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

        elseif event.type == "ON_ACQUIRE_CARD" then
            AcquireCard.execute(world, event.player, event.cardTemplate, event.tags)

        elseif event.type == "ON_APPLY_POWER" then
            ApplyPower.execute(world, event)

        elseif event.type == "ON_EXHAUST" then
            Exhaust.execute(world, event)

        elseif event.type == "ON_CUSTOM_EFFECT" then
            CustomEffect.execute(world, event)

        elseif event.type == "AFTER_CARD_PLAYED" then
            AfterCardPlayed.execute(world, event.player)

        else
            table.insert(world.log, "Unknown event type: " .. event.type)
        end
    end
end

return ProcessEffectQueue

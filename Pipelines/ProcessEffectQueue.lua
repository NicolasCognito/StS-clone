-- PROCESS EFFECT QUEUE PIPELINE
-- Routes and processes all queued events until queue is empty
--
-- Events are created by:
-- - Cards' onPlay functions
-- - Enemies' executeIntent functions
-- - Relics' onEndCombat functions
--
-- Event types:
-- - ON_DAMAGE: routes to DealDamage
-- - ON_NON_ATTACK_DAMAGE: routes to DealNonAttackDamage
-- - ON_BLOCK: routes to ApplyBlock
-- - ON_HEAL: routes to Heal
-- - ON_STATUS_GAIN: routes to ApplyStatusEffect
-- - ON_ACQUIRE_CARD: routes to AcquireCard
-- - ON_APPLY_POWER: routes to ApplyPower
--
-- Simple linear processing (no recursion)

local ProcessEffectQueue = {}

local DealDamage = require("Pipelines.DealDamage")
local DealNonAttackDamage = require("Pipelines.DealNonAttackDamage")
local ApplyBlock = require("Pipelines.ApplyBlock")
local Heal = require("Pipelines.Heal")
local ApplyStatusEffect = require("Pipelines.ApplyStatusEffect")
local AcquireCard = require("Pipelines.AcquireCard")
local ApplyPower = require("Pipelines.ApplyPower")

function ProcessEffectQueue.execute(world)
    while not world.queue:isEmpty() do
        local event = world.queue:next()

        if event.type == "ON_DAMAGE" then
            DealDamage.execute(world, event)
        elseif event.type == "ON_NON_ATTACK_DAMAGE" then
            DealNonAttackDamage.execute(world, event)
        elseif event.type == "ON_BLOCK" then
            ApplyBlock.execute(world, event)
        elseif event.type == "ON_HEAL" then
            Heal.execute(world, event)
        elseif event.type == "ON_STATUS_GAIN" then
            ApplyStatusEffect.execute(world, event)
        elseif event.type == "ON_ACQUIRE_CARD" then
            AcquireCard.execute(world, event.player, event.cardTemplate, event.tags)
        elseif event.type == "ON_APPLY_POWER" then
            ApplyPower.execute(world, event)
        else
            table.insert(world.log, "Unknown event type: " .. event.type)
        end
    end
end

return ProcessEffectQueue

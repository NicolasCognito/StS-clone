-- USE POTION PIPELINE
-- world: the complete game state
-- player: the player character
-- potion: the potion to use (from player.masterPotions)
--
-- Potions are simpler than cards:
-- - No energy cost
-- - No duplication handling (Double Tap, Burst, etc.)
-- - Single-use: consumed (removed from masterPotions)
-- - Just pushes effects directly to the queue
--
-- Handles:
-- - Call potion.onUse to generate effects
-- - Process effect queue
-- - Remove potion from player.masterPotions
-- - Combat logging

local UsePotion = {}

local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local Autocast = require("Pipelines.Autocast")

local function removePotion(player, potion)
    for i, p in ipairs(player.masterPotions) do
        if p == potion then
            table.remove(player.masterPotions, i)
            return true
        end
    end
    return false
end

function UsePotion.execute(world, player, potion)
    if not potion then
        return false
    end

    -- STEP 1: LOG USAGE
    local logMessage = player.id .. " used " .. (potion.name or "Potion")
    table.insert(world.log, logMessage)

    -- STEP 2: EXECUTE POTION EFFECT
    if potion.onUse then
        potion:onUse(world, player)
    end

    -- STEP 3: PROCESS EFFECT QUEUE
    local queueResult = ProcessEventQueue.execute(world)
    if type(queueResult) == "table" and queueResult.needsContext then
        -- Potions don't support context collection for now
        -- If we need this in the future, we can add it
        table.insert(world.log, "Warning: Potion requested context, which is not supported")
        return false
    end

    -- STEP 4: REMOVE POTION (consumed)
    removePotion(player, potion)

    -- STEP 5: TRIGGER AUTOCASTING (for Distilled Chaos and similar potions)
    if world.combat and world.combat.autocastingNextTopCards and world.combat.autocastingNextTopCards > 0 then
        Autocast.execute(world)
    end

    return true
end

return UsePotion

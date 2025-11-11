-- MAP PROCESS QUEUE PIPELINE
-- Drains the overworld/map queue so MapEvents and other traversal systems can
-- enqueue verbs in a data-driven way, mirroring the combat ProcessEffectQueue.

local Map_MapQueue = require("Pipelines.Map_MapQueue")
local Map_ChooseNextNode = require("Pipelines.Map_ChooseNextNode")
local Map_AcquireRelic = require("Pipelines.Map_AcquireRelic")
local Map_LoseRelic = require("Pipelines.Map_LoseRelic")
local Map_SpendGold = require("Pipelines.Map_SpendGold")
local Map_Heal = require("Pipelines.Map_Heal")
local Map_RemoveCard = require("Pipelines.Map_RemoveCard")
local Map_EventComplete = require("Pipelines.Map_EventComplete")
local Map_ClearContext = require("Pipelines.Map_ClearContext")
local Map_UpgradeCard = require("Pipelines.Map_UpgradeCard")
local Map_StartCombat = require("Pipelines.Map_StartCombat")

local Map_ProcessQueue = {}

local function ensureMapEventState(world)
    if not world.mapEvent then
        world.mapEvent = {
            stableContext = nil,
            tempContext = nil,
            contextRequest = nil,
            deferStableContextClear = false
        }
    end
    return world.mapEvent
end

local handlers = {
    MAP_CHOOSE_NODE = function(world, event)
        return Map_ChooseNextNode.execute(world, event.targetNodeId)
    end,

    MAP_ACQUIRE_RELIC = function(world, event)
        if not event.relic then
            error("MAP_ACQUIRE_RELIC event missing relic payload")
        end
        return Map_AcquireRelic.execute(world, event.relic)
    end,

    MAP_LOSE_RELIC = function(world, event)
        if not event.relicId then
            error("MAP_LOSE_RELIC event missing relicId payload")
        end
        return Map_LoseRelic.execute(world, event.relicId)
    end,

    MAP_SPEND_GOLD = function(world, event)
        return Map_SpendGold.execute(world, event.amount or 0)
    end,

    MAP_HEAL = function(world, event)
        return Map_Heal.execute(world, event)
    end,

    MAP_REMOVE_CARD = function(world, event)
        return Map_RemoveCard.execute(world, event)
    end,

    MAP_EVENT_COMPLETE = function(world, event)
        return Map_EventComplete.execute(world, event)
    end,

    MAP_CLEAR_CONTEXT = function(world, event)
        return Map_ClearContext.execute(world, event)
    end,

    MAP_UPGRADE_CARD = function(world, event)
        return Map_UpgradeCard.execute(world, event)
    end,

    MAP_START_COMBAT = function(world, event)
        return Map_StartCombat.execute(world, event)
    end,

    MAP_COLLECT_CONTEXT = function(world, event)
        local mapEvent = ensureMapEventState(world)
        local contextProvider = event.contextProvider
        local stability = event.stability or (contextProvider and contextProvider.stability) or "temp"
        local contextExists = (stability == "stable" and mapEvent.stableContext ~= nil) or
                              (stability == "temp" and mapEvent.tempContext ~= nil)

        if not contextExists then
            Map_MapQueue.push(world, event, "FIRST")
            mapEvent.contextRequest = {
                contextProvider = contextProvider,
                stability = stability
            }
            return {needsContext = true}
        end
    end,

    MAP_REQUEST_SELECTION = function(world, event)
        local mapEvent = ensureMapEventState(world)
        if mapEvent.contextRequest then
            Map_MapQueue.push(world, event, "FIRST")
            return {needsContext = true}
        end

        mapEvent.contextRequest = {
            mode = event.mode or "options",
            options = event.options,
            nodes = event.nodes,
            prompt = event.prompt,
            nodeId = event.nodeId,
            stability = "temp"
        }

        return {needsContext = true}
    end
}

local function preprocessEvent(event)
    for key, value in pairs(event) do
        if type(value) == "function" then
            event[key] = value()
        end
    end
end

local function runHandler(world, event)
    local handler = handlers[event.type]
    if handler then
        return handler(world, event)
    end

    if type(event.handler) == "function" then
        return event.handler(world, event)
    end

    if event.pipeline and type(event.pipeline) == "table" and type(event.pipeline.execute) == "function" then
        return event.pipeline.execute(world, event)
    end

    if world.log then
        table.insert(world.log, "Unknown map event type: " .. tostring(event.type))
    else
        print("Unknown map event type: " .. tostring(event.type))
    end
end

function Map_ProcessQueue.execute(world)
    if not world or not world.mapQueue or world.mapQueue:isEmpty() then
        return
    end

    while not Map_MapQueue.isEmpty(world) do
        local event = Map_MapQueue.next(world)
        if event then
            preprocessEvent(event)
            local result = runHandler(world, event)
            if result then
                return result
            end
        end
    end
end

return Map_ProcessQueue

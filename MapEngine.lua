-- MAP ENGINE
-- Helper utilities for querying map nodes/floors and driving map queues & events

local MapEngine = {}
local World = require("World")

local WAIT_MODES = {
    OPTIONS = "options",
    CARDS = "cards",
    NODE = "node"
}

local lazy = {}

local function getHandlers(world, options)
    if options then
        return options
    end
    if world then
        return world.mapEventOptions
    end
    return nil
end

local function getContextProvider()
    if not lazy.ContextProvider then
        lazy.ContextProvider = require("Pipelines.ContextProvider")
    end
    return lazy.ContextProvider
end

local function getSelectionBounds(world, request)
    local provider = request.contextProvider or {}
    local count = provider.count

    if type(count) == "function" then
        local ok, resolved = pcall(count, world, world.player, request.card)
        if ok and type(resolved) == "table" then
            count = resolved
        else
            count = nil
        end
    end

    if type(count) ~= "table" then
        count = {min = 1, max = 1}
    end

    local minSelect = count.min
    local maxSelect = count.max

    if type(minSelect) ~= "number" then
        minSelect = 1
    end
    if type(maxSelect) ~= "number" then
        maxSelect = minSelect
    end

    minSelect = math.max(0, math.floor(minSelect))
    maxSelect = math.max(minSelect, math.floor(maxSelect))

    return {min = minSelect, max = maxSelect}
end

local function getMapProcessQueue()
    if not lazy.MapProcessQueue then
        lazy.MapProcessQueue = require("Pipelines.Map_ProcessQueue")
    end
    return lazy.MapProcessQueue
end

local function getMapQueue()
    if not lazy.MapQueue then
        lazy.MapQueue = require("Pipelines.Map_MapQueue")
    end
    return lazy.MapQueue
end

local function getMapEvents()
    if not lazy.MapEvents then
        lazy.MapEvents = require("Data.mapevents")
    end
    return lazy.MapEvents
end

function MapEngine.getCurrentNode(world)
    if not world or not world.currentNode or not world.map then
        return nil
    end
    return world.map.nodes[world.currentNode]
end

function MapEngine.getNodesOnFloor(world, floor)
    if not world or not world.map then
        return {}
    end

    local nodes = {}
    for _, node in pairs(world.map.nodes) do
        if node.floor == floor then
            table.insert(nodes, node)
        end
    end
    return nodes
end

local function normalizeMode(mode)
    if type(mode) ~= "string" then
        return nil
    end

    mode = mode:lower()
    if mode == WAIT_MODES.CARDS or mode == "card" then
        return WAIT_MODES.CARDS
    elseif mode == "nodes" then
        return WAIT_MODES.NODE
    elseif mode == WAIT_MODES.NODE then
        return WAIT_MODES.NODE
    end
    return WAIT_MODES.OPTIONS
end

local DEFAULT_RESOLVERS = {}

DEFAULT_RESOLVERS[WAIT_MODES.CARDS] = function(world, request)
    local ContextProvider = getContextProvider()
    return ContextProvider.execute(world, world.player, request.contextProvider, request.card)
end

DEFAULT_RESOLVERS[WAIT_MODES.OPTIONS] = function(_, request)
    local options = request.options or {}
    assert(#options > 0, "MapEngine cannot auto-resolve option selection with no options provided")
    local index = request.preferredIndex or 1
    return options[index] or options[1]
end

DEFAULT_RESOLVERS[WAIT_MODES.NODE] = function(_, request)
    local nodes = request.nodes or {}
    assert(#nodes > 0, "MapEngine cannot auto-resolve node selection with no nodes provided")
    local index = request.preferredIndex or 1
    return nodes[index] or nodes[1]
end

local function inferMode(request)
    local explicit = normalizeMode(request.mode)
    if explicit then
        return explicit
    end

    if request.contextProvider then
        local ContextProvider = getContextProvider()
        local contextType = ContextProvider.getContextType(request.contextProvider)
        if contextType == "cards" then
            return WAIT_MODES.CARDS
        end
    end

    return WAIT_MODES.OPTIONS
end

local function shouldStoreContext(request, mode)
    if mode == WAIT_MODES.CARDS then
        return true
    end
    return false
end

local function storeContext(world, request, context, mode)
    if not shouldStoreContext(request, mode) then
        return
    end

    if not world.mapEvent then
        world.mapEvent = World.initMapEventState()
    end

    if request.stability == "stable" then
        world.mapEvent.stableContext = context
    else
        world.mapEvent.tempContext = context
    end
end

local function callHandler(handler, world, request)
    if type(handler) == "function" then
        return handler(world, request)
    end
end

function MapEngine.resolveContextRequest(world, options)
    if not world or not world.mapEvent or not world.mapEvent.contextRequest then
        return nil
    end

    local request = world.mapEvent.contextRequest
    if request and request.contextProvider and request.contextProvider.type == "cards" then
        local ContextProvider = getContextProvider()
        request.selectionBounds = request.selectionBounds or getSelectionBounds(world, request)
        if not request.selectableCards then
            request.selectableCards = ContextProvider.getValidCards(world, world.player, request.contextProvider, request.card)
        end
        request.selectionInfo = request.selectionInfo or ContextProvider.getSelectionInfo(request.contextProvider)
    end
    local mode = inferMode(request)
    local handlers = getHandlers(world, options)

    local handler
    if mode == WAIT_MODES.CARDS then
        handler = handlers and (handlers.onCardSelection or handlers.onResolve)
    elseif mode == WAIT_MODES.NODE then
        handler = handlers and (handlers.onNodeSelection or handlers.onResolve)
    else
        handler = handlers and (handlers.onOptionSelection or handlers.onResolve)
    end

    local context = callHandler(handler, world, request)
    if context == nil then
        local resolver = DEFAULT_RESOLVERS[mode]
        context = resolver and resolver(world, request, options)
    end

    assert(context ~= nil, ("MapEngine failed to resolve %s context"):format(mode))
    storeContext(world, request, context, mode)
    if mode ~= WAIT_MODES.CARDS then
        mapEvent.pendingSelection = context
    end
    world.mapEvent.contextRequest = nil
    return context
end

function MapEngine.drainMapQueue(world, options)
    if not world or not world.mapQueue then
        return
    end

    local limit = (options and options.limit) or 50
    local iterations = 0
    local Map_ProcessQueue
    local handlers = getHandlers(world, options)

    while world.mapQueue and not world.mapQueue:isEmpty() do
        if not Map_ProcessQueue then
            Map_ProcessQueue = getMapProcessQueue()
        end

        local result = Map_ProcessQueue.execute(world)
        if type(result) == "table" and result.needsContext then
            MapEngine.resolveContextRequest(world, handlers)
        end

        iterations = iterations + 1
        assert(iterations <= limit, "Map queue failed to drain")
    end
end

-- EVENT HANDLING ------------------------------------------------------------

local function getEventDefinition(eventId)
    if not eventId then
        return nil
    end

    local events = getMapEvents()
    if events[eventId] then
        return events[eventId]
    end

    for _, event in pairs(events) do
        if type(event) == "table" and event.id == eventId then
            return event
        end
    end

    return nil
end

local function resetEventState(world, eventKey, eventDef)
    world.currentEvent = eventDef and (eventDef.id or eventKey) or nil
    world.mapEvent = World.initMapEventState(eventKey, eventDef)
end

local function ensureActiveEvent(world)
    return world.mapEvent and world.mapEvent.event
end

local function requestOptionSelection(world, state, node)
    local MapQueue = getMapQueue()
    MapQueue.push(world, {
        type = "MAP_REQUEST_SELECTION",
        mode = WAIT_MODES.OPTIONS,
        nodeId = state.currentNodeId,
        options = node.options,
        prompt = node.text
    }, "FIRST")
end

local function completeEvent(world, result, options)
    local handlers = getHandlers(world, options)
    local MapQueue = getMapQueue()
    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = result or "complete" })
    MapEngine.drainMapQueue(world, handlers)
end

function MapEngine.advanceEvent(world, options)
    local handlers = getHandlers(world, options)

    while ensureActiveEvent(world) do
        local state = world.mapEvent
        local event = state.event
        local nodeId = state.currentNodeId or event.entryNode
        local node = event.nodes and event.nodes[nodeId]
        local continueLoop = false

        if not node then
            completeEvent(world, "invalid_node", options)
            break
        end

        local nextNode = nil
        if type(node.onEnter) == "function" then
            nextNode = node.onEnter(world, state)
            MapEngine.drainMapQueue(world, handlers)
            if not ensureActiveEvent(world) then
                break
            end
        end

        if nextNode then
            state.currentNodeId = nextNode
            continueLoop = true
        elseif node.exit then
            completeEvent(world, node.exit.result, options)
            break
        elseif node.options and #node.options > 0 then
            requestOptionSelection(world, state, node)
            MapEngine.drainMapQueue(world, handlers)
            local selection = state.pendingSelection
            state.pendingSelection = nil
            if not selection then
                break
            end
            state.currentNodeId = selection.next or state.currentNodeId
            continueLoop = true
        end

        if not continueLoop then
            break
        end
    end
end

function MapEngine.startEvent(world, eventId, options)
    local eventDef = getEventDefinition(eventId)
    assert(eventDef, "Unknown map event: " .. tostring(eventId))
    resetEventState(world, eventId, eventDef)
    local handlers = getHandlers(world, options)
    MapEngine.advanceEvent(world, handlers)
end

function MapEngine.triggerNodeEvent(world, node, options)
    if not world or not node or not node.event then
        return
    end
    local handlers = getHandlers(world, options)
    MapEngine.startEvent(world, node.event, handlers)
end

return MapEngine

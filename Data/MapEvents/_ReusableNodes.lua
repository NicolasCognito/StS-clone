-- REUSABLE MAP EVENT NODE HELPERS
-- These helpers exist for patterns that show up identically across multiple
-- events (e.g., "remove a card from master deck"). They DO NOT replace the
-- direct-editing philosophy; they just keep copy/paste fragments consistent.

local MapQueue = require("Pipelines.Map_MapQueue")
local AcquireCard = require("Pipelines.AcquireCard")
local ContextProvider = require("Pipelines.ContextProvider")
local Cards = require("Data.cards")
local Utils = require("utils")

local ReusableNodes = {}

--- Creates a simple node table that immediately marks the event complete.
-- @param result string Optional result label (default "complete")
function ReusableNodes.exitNode(result)
    return {
        exit = { result = result or "complete" }
    }
end

--- Creates a node that removes a single card from the master deck using the
-- same context flow used by Peace Pipe / Cleric.
-- @param config table {result?, label?, description?}
function ReusableNodes.cardRemovalNode(config)
    config = config or {}
    return {
        label = config.label or "Remove",
        description = config.description or "Remove a card from your deck.",
        next = config.next or "remove_card",
        onEnter = function(world)
            MapQueue.push(world, {
                type = "MAP_COLLECT_CONTEXT",
                contextProvider = {
                    type = "cards",
                    source = "master",
                    environment = "map",
                    stability = "temp",
                    count = {min = 1, max = 1}
                }
            }, "FIRST")

            MapQueue.push(world, {
                type = "MAP_REMOVE_CARD",
                source = "master",
                card = function()
                    local ctx = world.mapEvent and world.mapEvent.tempContext
                    return ctx and ctx[1]
                end
            })
            MapQueue.push(world, { type = "MAP_CLEAR_CONTEXT", target = "temp" })
            if config.result then
                MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = config.result })
            end
            return config.nextAfterRemoval or "exit"
        end
    }
end

local function buildCardPool()
    local pool = {}
    for _, card in pairs(Cards) do
        if type(card) == "table" and card.id then
            table.insert(pool, card)
        end
    end
    return pool
end

local function applyAutoChoice(world, rewards)
    local chooser = world and world.autoRewardChoice
    if not chooser and world and world.mapEvent then
        chooser = world.mapEvent.autoRewardChoice
    end

    local index
    if type(chooser) == "number" then
        index = chooser
    elseif type(chooser) == "function" then
        local ok, value = pcall(chooser, world, rewards)
        if ok then
            index = value
        end
    end

    if index and rewards[index] then
        if index ~= 1 then
            rewards[1], rewards[index] = rewards[index], rewards[1]
        end
        return 1
    end

    return nil
end

-- INTERNAL HELPERS
local function insertDraftRewards(world, rewards)
    local deck = world.player.masterDeck
    for _, card in ipairs(rewards) do
        card.state = "DRAFT"
        card.rewardDraft = true
        table.insert(deck, card)
    end
end

local function cleanupDraftRewards(world)
    local deck = world.player.masterDeck
    for i = #deck, 1, -1 do
        if deck[i].rewardDraft then
            table.remove(deck, i)
        end
    end
end

function ReusableNodes.cardRewardChoiceNode(config)
    config = config or {}
    local count = config.count or 3
    local allowSkip = config.allowSkip ~= false
    local text = config.text or "Choose a card reward."
    local result = config.result or "card_reward"
    local nextNode = config.next or "exit"
    local completeEvent = config.completeEvent ~= false
    local minCount = allowSkip and 0 or 1
    local buildPoolFn = config.buildPool

    return {
        text = text,
        onEnter = function(world)
            local pool = buildPoolFn and buildPoolFn(world) or buildCardPool()
            if #pool == 0 then
                Utils.log(world, "No cards available for reward.")
                return nextNode
            end

            local rewards = {}
            for i = 1, count do
                local template = pool[math.random(#pool)]
                table.insert(rewards, Utils.copyCardTemplate(template))
            end

            applyAutoChoice(world, rewards)
            insertDraftRewards(world, rewards)

            local provider = {
                type = "cards",
                source = "master",
                environment = "map",
                stability = "temp",
                count = {min = minCount, max = 1},
                filter = function(_, _, _, candidate)
                    return candidate and candidate.rewardDraft
                end
            }

            local selection = ContextProvider.execute(world, world.player, provider)
            local chosen = selection and selection[1]

            cleanupDraftRewards(world)

            if chosen then
                AcquireCard.execute(world, world.player, chosen, nil, "master")
            else
                Utils.log(world, "You skip the reward.")
            end

            if completeEvent then
                MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = result })
            end
            return nextNode
        end
    }
end

return ReusableNodes

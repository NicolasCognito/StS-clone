local MapQueue = require("Pipelines.Map_MapQueue")
local Cards = require("Data.cards")
local Relics = require("Data.relics")
local Utils = require("utils")
local ReusableNodes = require("Data.MapEvents._ReusableNodes")

local function calculateRestHeal(world)
    if not world or not world.player or not world.player.maxHp then
        return 0
    end

    local amount = math.floor(world.player.maxHp * 0.30)
    local pillow = Utils.getRelic(world.player, "Regal_Pillow")
    if pillow then
        amount = amount + (pillow.restBonus or 15)
    end
    return math.max(amount, 0)
end

local function buildDreamCatcherPool(world)
    local pool = {}
    if not world or not world.player then
        return pool
    end

    local playerClass = string.upper(world.player.id or "IRONCLAD")

    for _, card in pairs(Cards) do
        if type(card) == "table" and card.id then
            local character = card.character or ""
            local rarity = card.rarity or ""
            local isStarter = rarity == "STARTER"
            local isCurse = rarity == "CURSE" or character == "CURSE" or card.type == "CURSE"
            local matchesClass = (character == "COLORLESS") or (character == playerClass)

            if matchesClass and not isStarter and not isCurse then
                table.insert(pool, card)
            end
        end
    end

    return pool
end

local function grantDreamCatcherReward(world)
    local player = world and world.player
    local relic = player and Utils.getRelic(player, "Dream_Catcher")
    if not relic then
        return
    end

    local rewardNode = ReusableNodes.cardRewardChoiceNode({
        count = relic.rewardCount or 3,
        allowSkip = true,
        text = "Dream Catcher reveals visions. Choose one.",
        result = "dream_catcher_reward",
        completeEvent = false,
        buildPool = function(currentWorld)
            return buildDreamCatcherPool(currentWorld)
        end
    })

    rewardNode.onEnter(world)
end

local function handleRestSiteEntry(world)
    if not world then
        return
    end

    if not world.mapEvent then
        world.mapEvent = {
            stableContext = nil,
            tempContext = nil,
            contextRequest = nil,
            deferStableContextClear = false
        }
    end

    if world.mapEvent.restSiteEntryProcessed then
        return
    end
    world.mapEvent.restSiteEntryProcessed = true

    local player = world and world.player
    local teaSet = player and Utils.getRelic(player, "Ancient_Tea_Set")
    if teaSet then
        local bonus = teaSet.restEnergy or 2
        world.pendingRestSiteEnergy = (world.pendingRestSiteEnergy or 0) + bonus
        Utils.log(world, string.format("Ancient Tea Set warms you for the next battle (+%d Energy).", bonus))
    end

    local feather = player and Utils.getRelic(player, "Eternal_Feather")
    if feather then
        local deckSize = #(world.player and world.player.masterDeck or {})
        local cardsPerChunk = feather.cardsPerChunk or 5
        local healPerChunk = feather.healPerChunk or 3
        local healAmount = math.floor(deckSize / cardsPerChunk) * healPerChunk
        if healAmount > 0 then
            MapQueue.push(world, { type = "MAP_HEAL", amount = healAmount, source = "Eternal Feather" })
        end
    end
end

local function buildDigPool(world)
    local pool = {}
    if not world or not world.player then
        return pool
    end

    for _, relic in pairs(Relics) do
        if type(relic) == "table" and relic.id and not Utils.hasRelic(world.player, relic.id) then
            table.insert(pool, relic)
        end
    end
    return pool
end

local function digRandomRelic(world)
    local pool = buildDigPool(world)
    if #pool == 0 then
        Utils.log(world, "There is nothing left to dig up here.")
        return nil
    end

    local relic = pool[math.random(#pool)]
    MapQueue.push(world, { type = "MAP_ACQUIRE_RELIC", relic = relic })
    Utils.log(world, "You dig up " .. (relic.name or relic.id or "a relic") .. "!")
    return relic
end

local function canRecall(world)
    return world and world.act4Unlocked and not world.rubyKeyObtained
end

return {
    Campfire = {
        id = "CAMPFIRE",
        name = "Campfire",
        tags = {"rest"},
        requirements = {
            acts = {1, 2, 3}
        },
        entryNode = "arrival",
        nodes = {
            arrival = {
                text = "You stumble upon a cozy campsite. The crackling fire offers warmth and anvil alike.",
                onEnter = function(world)
                    handleRestSiteEntry(world)
                end,
                options = {
                    {
                        id = "REST",
                        label = "Rest",
                        description = "Recover 30% of your Max HP.",
                        next = "rest"
                    },
                    {
                        id = "SMITH",
                        label = "Smith",
                        description = "Upgrade a card in your deck.",
                        next = "smith"
                    },
                    {
                        id = "LIFT",
                        label = "Lift",
                        description = "Permanently gain 1 Strength. (Requires Girya, up to 3 uses.)",
                        next = "lift"
                    },
                    {
                        id = "TOKE",
                        label = "Toke",
                        description = "Remove a card from your deck. (Requires Peace Pipe.)",
                        next = "toke"
                    },
                    {
                        id = "DIG",
                        label = "Dig",
                        description = "Obtain a random relic. (Requires Shovel.)",
                        next = "dig"
                    },
                    {
                        id = "RECALL",
                        label = "Recall",
                        description = "Obtain the Ruby Key. (Available when Act 4 is unlocked.)",
                        next = "recall"
                    },
                    {
                        id = "LEAVE",
                        label = "Leave",
                        description = "Pack up and move on.",
                        next = "exit"
                    }
                }
            },

            rest = {
                onEnter = function(world)
                    if Utils.hasRelic(world.player, "Coffee_Dripper") then
                        Utils.log(world, "Coffee Dripper hums loudly. You cannot rest.")
                        return "arrival"
                    end

                    local healAmount = calculateRestHeal(world)
                    if healAmount > 0 then
                        MapQueue.push(world, { type = "MAP_HEAL", amount = healAmount, source = "Campfire Rest" })
                    end

                    if Utils.hasRelic(world.player, "Dream_Catcher") then
                        grantDreamCatcherReward(world)
                    end

                    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = "rest" })
                    return "exit"
                end
            },

            smith = {
                onEnter = function(world)
                    if Utils.hasRelic(world.player, "Fusion_Hammer") then
                        Utils.log(world, "Fusion Hammer is too unwieldy—you cannot smith here.")
                        return "arrival"
                    end

                    MapQueue.push(world, {
                        type = "MAP_COLLECT_CONTEXT",
                        contextProvider = {
                            type = "cards",
                            source = "master",
                            environment = "map",
                            stability = "temp",
                            count = {min = 1, max = 1},
                            filter = function(_, _, _, candidate)
                                return candidate and not candidate.upgraded and type(candidate.onUpgrade) == "function"
                            end
                        }
                    }, "FIRST")

                    MapQueue.push(world, {
                        type = "MAP_UPGRADE_CARD",
                        card = function()
                            local ctx = world.mapEvent and world.mapEvent.tempContext
                            return ctx and ctx[1]
                        end
                    })

                    MapQueue.push(world, { type = "MAP_CLEAR_CONTEXT", target = "temp" })
                    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = "smith" })
                    return "exit"
                end
            },

            lift = {
                onEnter = function(world)
                    local player = world and world.player
                    local girya = player and Utils.getRelic(player, "Girya")
                    if not girya then
                        Utils.log(world, "You need Girya to Lift.")
                        return "arrival"
                    end

                    world.giryaLiftsUsed = world.giryaLiftsUsed or 0
                    local maxLifts = girya.maxLifts or 3
                    if world.giryaLiftsUsed >= maxLifts then
                        Utils.log(world, "Girya refuses to budge. No more lifts remain.")
                        return "arrival"
                    end

                    world.giryaLiftsUsed = world.giryaLiftsUsed + 1
                    world.player.permanentStrength = (world.player.permanentStrength or 0) + 1
                    Utils.log(world, string.format("You Lift the Girya. (%d/%d uses)", world.giryaLiftsUsed, maxLifts))
                    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = "lift" })
                    return "exit"
                end
            },

            toke = {
                onEnter = function(world)
                    if not Utils.hasRelic(world.player, "Peace_Pipe") then
                        Utils.log(world, "You need the Peace Pipe to Toke.")
                        return "arrival"
                    end

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
                    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = "toke" })
                    return "exit"
                end
            },

            dig = {
                onEnter = function(world)
                    if not Utils.hasRelic(world.player, "Shovel") then
                        Utils.log(world, "You need a Shovel to dig here.")
                        return "arrival"
                    end

                    digRandomRelic(world)
                    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = "dig" })
                    return "exit"
                end
            },

            recall = {
                onEnter = function(world)
                    if not canRecall(world) then
                        if world and world.rubyKeyObtained then
                            Utils.log(world, "You've already taken the Ruby Key.")
                        else
                            Utils.log(world, "The Ruby Key remains dormant. (Act 4 locked)")
                        end
                        return "arrival"
                    end

                    world.rubyKeyObtained = true
                    Utils.log(world, "You grasp the Ruby Key, feeling a distant stirring.")
                    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = "recall" })
                    return "exit"
                end
            },

            exit = {
                exit = { result = "complete" }
            }
        }
    }
}

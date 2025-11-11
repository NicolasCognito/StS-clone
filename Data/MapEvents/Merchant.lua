local MapQueue = require("Pipelines.Map_MapQueue")
local AcquireCard = require("Pipelines.AcquireCard")
local Map_BuildCardPool = require("Pipelines.Map_BuildCardPool")
local Map_BuildRelicPool = require("Pipelines.Map_BuildRelicPool")
local Utils = require("utils")

local DEFAULT_CARD_PRICE = 50
local DEFAULT_RELIC_PRICE = 150
local CARD_STOCK_SIZE = 7
local RELIC_STOCK_SIZE = 3

local Merchant = {}

local CARD_ORDINALS = {"first", "second", "third", "fourth", "fifth", "sixth", "seventh"}
local RELIC_ORDINALS = {"first", "second", "third"}

local CARD_RARITY_PRICES = {
    STARTER = DEFAULT_CARD_PRICE,
    BASIC = DEFAULT_CARD_PRICE,
    COMMON = DEFAULT_CARD_PRICE,
    UNCOMMON = 75,
    RARE = 150,
    COLORLESS = 150,
    SPECIAL = DEFAULT_CARD_PRICE
}

local function excludeCurses(_, card)
    local rarity = card.rarity or ""
    return rarity ~= "CURSE"
end

local DEFAULT_CARD_POOL_OPTIONS = {
    { filter = excludeCurses },
    { filter = excludeCurses },
    { filter = excludeCurses },
    { filter = excludeCurses },
    { filter = excludeCurses },
    { filter = excludeCurses },
    { filter = excludeCurses }
}

local DEFAULT_RELIC_POOL_OPTIONS = {
    { excludeOwned = true },
    { excludeOwned = true },
    { excludeOwned = true }
}

local function ensureState(world)
    world.mapEvent = world.mapEvent or {}
    world.mapEvent.merchant = world.mapEvent.merchant or {
        cards = {},
        relics = {},
        cardsGenerated = false,
        relicsGenerated = false
    }
    return world.mapEvent.merchant
end

local function buildCardStock(world, poolOptions)
    local state = ensureState(world)
    if not state.cardsGenerated then
        state.cards = {}
        poolOptions = poolOptions or DEFAULT_CARD_POOL_OPTIONS
        assert(#poolOptions == CARD_STOCK_SIZE, "Card pool options must match card stock size.")

        local usedIds = {}
        for slot = 1, CARD_STOCK_SIZE do
            local slotOptions = poolOptions[slot] or {}
            local pool = Map_BuildCardPool.execute(world, slotOptions)

            while #pool > 0 do
                local index = math.random(#pool)
                local candidate = pool[index]
                table.remove(pool, index)

                if candidate and candidate.id and not usedIds[candidate.id] then
                    state.cards[slot] = candidate
                    usedIds[candidate.id] = true
                    break
                end
            end
        end

        state.cardsGenerated = true
    end
    return state.cards
end

local function buildRelicStock(world, poolOptions)
    local state = ensureState(world)
    if not state.relicsGenerated then
        state.relics = {}
        poolOptions = poolOptions or DEFAULT_RELIC_POOL_OPTIONS
        assert(#poolOptions == RELIC_STOCK_SIZE, "Relic pool options must match relic stock size.")

        local usedIds = {}
        for slot = 1, RELIC_STOCK_SIZE do
            local slotOptions = poolOptions[slot] or {}
            local pool = Map_BuildRelicPool.execute(world, slotOptions)

            while #pool > 0 do
                local index = math.random(#pool)
                local candidate = pool[index]
                table.remove(pool, index)

                if candidate and candidate.id and not usedIds[candidate.id] then
                    state.relics[slot] = candidate
                    usedIds[candidate.id] = true
                    break
                end
            end
        end

        state.relicsGenerated = true
    end
    return state.relics
end

local function clearContextAndExit(world, result)
    MapQueue.push(world, { type = "MAP_CLEAR_CONTEXT", target = "temp" })
    MapQueue.push(world, { type = "MAP_EVENT_COMPLETE", result = result or "merchant" })
    return "exit"
end

local function createCardOption(slot)
    return {
        id = ("BUY_CARD_%d"):format(slot),
        label = ("Buy card slot %d (%d gold)"):format(slot, DEFAULT_CARD_PRICE),
        description = ("Purchase the %s card on display."):format(CARD_ORDINALS[slot] or tostring(slot)),
        next = ("buy_card_%d"):format(slot)
    }
end

local function createRelicOption(slot)
    return {
        id = ("BUY_RELIC_%d"):format(slot),
        label = ("Buy relic slot %d (%d gold)"):format(slot, DEFAULT_RELIC_PRICE),
        description = ("Inspect the %s relic."):format(RELIC_ORDINALS[slot] or tostring(slot)),
        next = ("buy_relic_%d"):format(slot)
    }
end

local function buildShopOptions()
    local options = {}
    for slot = 1, CARD_STOCK_SIZE do
        table.insert(options, createCardOption(slot))
    end

    table.insert(options, {
        id = "REMOVE_CARD",
        label = "Remove a card (75 gold)",
        description = "Purge a card from your deck.",
        next = "remove_card"
    })

    for slot = 1, RELIC_STOCK_SIZE do
        table.insert(options, createRelicOption(slot))
    end

    table.insert(options, {
        id = "LEAVE",
        label = "Leave",
        description = "Head back to the map.",
        next = "exit"
    })

    return options
end

local function assignPrice(node)
    if not node then
        return nil
    end

    if node.type then
        local rarity = node.rarity and string.upper(node.rarity) or ""
        return CARD_RARITY_PRICES[rarity] or DEFAULT_CARD_PRICE
    end

    return DEFAULT_RELIC_PRICE
end

local function handleStockPurchase(world, slot, stockBuilder, config, poolOptions)
    local stock = stockBuilder(world, poolOptions)
    local item = stock[slot]
    if not item then
        Utils.log(world, config.emptyMessage)
        return "shop"
    end

    local price = item.price or assignPrice(item) or config.defaultPrice
    item.price = price
    if world.player.gold < price then
        Utils.log(world, "Not enough gold to purchase " .. (item.name or item.id or config.fallbackName) .. ".")
        return "shop"
    end

    MapQueue.push(world, { type = "MAP_SPEND_GOLD", amount = price })
    config.onAcquire(world, item)
    Utils.log(world, ("You purchase %s."):format(item.name or item.id or config.fallbackName))
    stock[slot] = nil
    return "shop"
end

local CARD_PURCHASE_CONFIG = {
    emptyMessage = "That card slot is empty.",
    defaultPrice = DEFAULT_CARD_PRICE,
    fallbackName = "the card",
    onAcquire = function(world, card)
        AcquireCard.execute(world, world.player, card, nil, "master")
    end
}

local RELIC_PURCHASE_CONFIG = {
    emptyMessage = "That relic slot is empty.",
    defaultPrice = DEFAULT_RELIC_PRICE,
    fallbackName = "the relic",
    onAcquire = function(world, relic)
        MapQueue.push(world, { type = "MAP_ACQUIRE_RELIC", relic = relic })
    end
}

local function addPurchaseNodes(nodes, args)
    for slot = 1, args.count do
        local slotIndex = slot
        nodes[("%s%d"):format(args.prefix, slotIndex)] = {
            onEnter = function(world)
                return handleStockPurchase(world, slotIndex, args.stockBuilder, args.config, args.poolOptions)
            end
        }
    end
end

Merchant.Merchant = {
    id = "MERCHANT",
    name = "Merchant",
    tags = {"merchant"},
    entryNode = "shop",
    nodes = {
        shop = {
            text = "A mysterious merchant beckons you. \"Cards, relics, or perhaps you'd like to tidy that deck?\"",
            onEnter = function(world)
                ensureState(world)
            end,
            options = buildShopOptions()
        },

        remove_card = {
            onEnter = function(world)
                if world.player.gold < 75 then
                    Utils.log(world, "Not enough gold to remove a card.")
                    return "shop"
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

                MapQueue.push(world, { type = "MAP_SPEND_GOLD", amount = 75 })
                MapQueue.push(world, {
                    type = "MAP_REMOVE_CARD",
                    source = "master",
                    card = function()
                        local ctx = world.mapEvent and world.mapEvent.tempContext
                        return ctx and ctx[1]
                    end
                })

                clearContextAndExit(world, "merchant_remove_card")
                return "exit"
            end
        },

        exit = {
            exit = { result = "complete" }
        }
    }
}

addPurchaseNodes(Merchant.Merchant.nodes, {
    prefix = "buy_card_",
    count = CARD_STOCK_SIZE,
    stockBuilder = buildCardStock,
    config = CARD_PURCHASE_CONFIG,
    poolOptions = DEFAULT_CARD_POOL_OPTIONS
})

addPurchaseNodes(Merchant.Merchant.nodes, {
    prefix = "buy_relic_",
    count = RELIC_STOCK_SIZE,
    stockBuilder = buildRelicStock,
    config = RELIC_PURCHASE_CONFIG,
    poolOptions = DEFAULT_RELIC_POOL_OPTIONS
})

return Merchant

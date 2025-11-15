-- START COMBAT PIPELINE
-- Initializes combat-specific context before the player takes the first turn

local StartCombat = {}

local World = require("World")
local EventQueue = require("Pipelines.EventQueue")
local CardQueue = require("Pipelines.CardQueue")
local StartTurn = require("Pipelines.StartTurn")
local Utils = require("utils")

function StartCombat.execute(world)
    world.combat = World.initCombatState()

    world.queue = EventQueue.new()
    world.cardQueue = CardQueue.new()
    world.DuplicationShadowCards = {}  -- Tracks shadow copies created during duplication, cleared on turn end
    world.log = {}

    -- Ensure combat-only status table exists
    world.player.status = world.player.status or {}
    local permanentStrength = world.player.permanentStrength or 0
    if permanentStrength ~= 0 then
        world.player.status.strength = (world.player.status.strength or 0) + permanentStrength
        table.insert(world.log, string.format("%s benefits from %d permanent Strength.", world.player.name, permanentStrength))
    end

    -- Create combatDeck as a deep copy of masterDeck
    -- This ensures combat-only modifications (generated cards, temporary upgrades)
    -- don't affect the player's permanent deck
    world.player.combatDeck = Utils.deepCopyDeck(world.player.masterDeck)

    -- Initialize all combat cards to DECK state and clear combat-only properties
    for _, card in ipairs(world.player.combatDeck) do
        card.state = "DECK"
        card.confused = nil
        card.costsZeroThisTurn = nil
        card.timesRetained = nil
        card.retainCostReduction = nil
    end

    -- Shuffle the combat deck for random card order
    Utils.shuffleDeck(world.player.combatDeck, world)

    -- Handle Innate cards: move to top of deck
    local innateCards = {}
    local nonInnateCards = {}

    for _, card in ipairs(world.player.combatDeck) do
        if card.state == "DECK" then
            if card.innate then
                table.insert(innateCards, card)
            else
                table.insert(nonInnateCards, card)
            end
        end
    end

    if #innateCards > 0 then
        -- Shuffle Innate cards among themselves (for randomness when >10 Innate)
        if not world.NoShuffle then
            for i = #innateCards, 2, -1 do
                local j = math.random(i)
                innateCards[i], innateCards[j] = innateCards[j], innateCards[i]
            end
        end

        -- Rebuild deck: non-DECK cards, then Innate cards, then regular cards
        local rebuiltDeck = {}

        -- Preserve non-DECK cards (shouldn't be any at combat start, but safety)
        for _, card in ipairs(world.player.combatDeck) do
            if card.state ~= "DECK" then
                table.insert(rebuiltDeck, card)
            end
        end

        -- Add Innate cards on top
        for _, card in ipairs(innateCards) do
            table.insert(rebuiltDeck, card)
        end

        -- Add regular cards below
        for _, card in ipairs(nonInnateCards) do
            table.insert(rebuiltDeck, card)
        end

        world.player.combatDeck = rebuiltDeck

        table.insert(world.log, #innateCards .. " Innate card(s) placed on top of draw pile")
    end

    -- Blue Candle: Make all Curse cards playable
    if Utils.hasRelic(world.player, "Blue_Candle") then
        for _, card in ipairs(world.player.combatDeck) do
            if card.type == "CURSE" then
                -- Override isPlayable to always return true
                card.isPlayable = function(self, world, player)
                    return true
                end

                -- Override onPlay to deal 1 HP damage
                card.onPlay = function(self, world, player)
                    world.queue:push({
                        type = "ON_NON_ATTACK_DAMAGE",
                        source = self,
                        target = player,
                        amount = 1,
                        tags = {"ignoreBlock"}
                    })
                    table.insert(world.log, player.name .. " plays " .. self.name .. ", losing 1 HP (Blue Candle)")
                end
            end
        end
    end

    -- MedKit: Make all Status cards playable
    if Utils.hasRelic(world.player, "Medkit") then
        for _, card in ipairs(world.player.combatDeck) do
            if card.type == "STATUS" then
                -- Override isPlayable to always return true
                card.isPlayable = function(self, world, player)
                    return true
                end

                -- Override onPlay to just exhaust (Status cards have no effect)
                card.onPlay = function(self, world, player)
                    table.insert(world.log, player.name .. " plays " .. self.name .. " (Medkit)")
                end
            end
        end
    end

    world.player.block = 0
    world.player.energy = world.player.maxEnergy
    world.player.hp = world.player.currentHp
    local pendingRestEnergy = world.pendingRestSiteEnergy or 0
    if pendingRestEnergy > 0 then
        world.player.energy = world.player.energy + pendingRestEnergy
        table.insert(world.log, string.format("Ancient Tea Set grants +%d energy this turn.", pendingRestEnergy))
        world.pendingRestSiteEnergy = 0
    end

    for _, relic in ipairs(world.player.relics or {}) do
        if relic.onCombatStart then
            relic:onCombatStart(world)
        end

        if relic.id == "Snecko_Eye" then
            world.player.status = world.player.status or {}
            world.player.status.confused = 999
            table.insert(world.log, world.player.name .. " is Confused!")
        end
    end

    -- Orb-related relic effects at combat start
    if Utils.hasRelic(world.player, "CrackedCore") then
        world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Lightning"})
    end

    if Utils.hasRelic(world.player, "NuclearBattery") then
        world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Plasma"})
    end

    if Utils.hasRelic(world.player, "SymbioticVirus") then
        world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Dark"})
    end

    if Utils.hasRelic(world.player, "DataDisk") then
        world.queue:push({
            type = "ON_STATUS_GAIN",
            target = world.player,
            status = "focus",
            amount = 1
        })
    end

    if Utils.hasRelic(world.player, "RunicCapacitor") then
        world.player.maxOrbs = world.player.maxOrbs + 3
        table.insert(world.log, world.player.name .. " starts with 3 additional orb slots")
    end

    -- Initialize HP tracking for Emotion Chip
    world.combat.hpAtTurnStart = world.player.hp

    -- Initialize Mantra tracking for Brilliance card
    world.combat.mantraGainedThisCombat = 0

    StartTurn.execute(world, world.player)
end

return StartCombat


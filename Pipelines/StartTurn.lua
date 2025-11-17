-- START TURN PIPELINE
-- world: the complete game state
-- player: the player character
--
-- Handles:
-- - Clear per-turn state (temporary retention flags, duplication tracking)
-- - Reset block to 0
-- - Turn-start powers that need context (Foresight, Tools of the Trade)
-- - Draw cards (5 base + Snecko Eye bonus)
-- - Gambling Chip relic (first turn only)
-- - Trigger any start-of-turn power effects
-- - Combat logging
--
-- This centralizes all turn-start logic in one place
-- Uses Queue as Continuation pattern for context collection

local StartTurn = {}

local DrawCard = require("Pipelines.DrawCard")
local ChangeStance = require("Pipelines.ChangeStance")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local Utils = require("utils")

-- Helper: Calculate number of cards to draw
function StartTurn.calculateCardsToDraw(world, player)
    local baseDraw = 5  -- Base starting hand size
    local relicBonus = 0

    -- Calculate relic bonuses
    if player.relics then
        for _, relic in ipairs(player.relics) do
            if relic.id == "Snecko_Eye" then
                relicBonus = relicBonus + 2
            elseif relic.id == "RingOfTheSnake" or relic.id == "Ring_of_the_Snake" then
                relicBonus = relicBonus + 2
            elseif relic.id == "RingOfTheSerpent" or relic.id == "Ring_of_the_Serpent" then
                relicBonus = relicBonus + 1
            elseif relic.id == "BagOfPreparation" or relic.id == "Bag_of_Preparation" then
                relicBonus = relicBonus + 2
            end
        end
    end

    local cardsToDraw = baseDraw + relicBonus

    -- First turn only: Handle Innate cards
    -- If Innate count exceeds base draw, draw all Innate cards + relic bonuses
    if world.combat.turnCounter == 0 then
        local innateCount = 0
        for _, card in ipairs(player.combatDeck) do
            if card.state == "DECK" and card.innate then
                innateCount = innateCount + 1
            end
        end

        if innateCount > baseDraw then
            -- Draw all Innate cards + relic bonuses
            cardsToDraw = innateCount + relicBonus
        end
        -- else: use normal draw (baseDraw + relicBonus)
    end

    -- Cap at max hand size (10)
    local maxHandSize = player.maxHandSize or 10
    cardsToDraw = math.min(cardsToDraw, maxHandSize)

    local status = player.status or {}
    if status.draw_reduction and status.draw_reduction > 0 then
        local reduction = status.draw_reduction
        cardsToDraw = math.max(0, cardsToDraw - reduction)
        status.draw_reduction = nil
        local playerName = player.name or player.id or "Player"
        table.insert(world.log, playerName .. " draw reduced by " .. reduction .. " (" .. cardsToDraw .. " card(s) this turn)")
    end

    return cardsToDraw
end

-- Helper: Final cleanup (NIGHTMARE cards, Fasting, enemies select intents)
function StartTurn.finishTurnStart(world, player)
    local status = player.status or {}
    local playerName = player.name or player.id or "Player"

    -- Process NIGHTMARE state cards (from Nightmare card)
    -- Move NIGHTMARE cards to hand, respecting max hand size (default 10)
    -- If hand is full, Nightmare cards are removed entirely
    local maxHandSize = player.maxHandSize or 10

    for i = #player.combatDeck, 1, -1 do
        local card = player.combatDeck[i]
        if card.state == "NIGHTMARE" then
            local handSize = Utils.getCardCountByState(player.combatDeck, "HAND")

            if handSize < maxHandSize then
                card.state = "HAND"
                table.insert(world.log, card.name .. " added to hand from Nightmare")
            else
                -- Hand full - card is lost (removed from deck entirely)
                table.remove(player.combatDeck, i)
                table.insert(world.log, card.name .. " lost (hand full)")
            end
        end
    end

    if status.fasting and status.fasting > 0 then
        local penalty = math.min(status.fasting, player.energy)
        if penalty > 0 then
            player.energy = player.energy - penalty
            table.insert(world.log, playerName .. " lost " .. penalty .. " energy to Fasting")
        end
    end

    -- Enemies select their intents for the upcoming round
    -- This happens right after player gains energy
    if world.enemies then
        for _, enemy in ipairs(world.enemies) do
            if enemy.hp > 0 and enemy.selectIntent then
                enemy:selectIntent(world, player)
            end
        end
    end
end

-- Helper: Queue all turn-start work with context collections
function StartTurn.queueTurnStartWithContext(world, player, needsForesight, needsToolsOfTrade, needsGamblingChip)
    local status = player.status or {}

    -- PHASE 1: Foresight - Scry BEFORE drawing
    if needsForesight then
        local scryAmount = status.foresight

        world.queue:push({
            type = "COLLECT_CONTEXT",
            contextProvider = {
                type = "cards",
                stability = "temp",
                scry = scryAmount,
                count = {min = 0, max = scryAmount}
            }
        }, "FIRST")

        world.queue:push({type = "ON_SCRY"})
    end

    -- PHASE 2: Normal draw
    world.queue:push({
        type = "ON_CUSTOM_EFFECT",
        effect = function()
            local cardsToDraw = StartTurn.calculateCardsToDraw(world, player)
            DrawCard.execute(world, player, cardsToDraw)
        end
    })

    -- PHASE 3: Tools of the Trade - Draw 1, discard 1 AFTER normal draw
    if needsToolsOfTrade then
        -- Draw 1 extra card
        world.queue:push({type = "ON_DRAW"})

        -- Request discard context
        world.queue:push({
            type = "COLLECT_CONTEXT",
            contextProvider = {
                type = "cards",
                stability = "temp",
                source = "combat",
                count = {min = 1, max = 1},
                filter = function(w, p, card, candidate)
                    return candidate.state == "HAND"
                end
            }
        }, "FIRST")

        -- Discard selected card
        world.queue:push({
            type = "ON_CUSTOM_EFFECT",
            effect = function()
                local cardsToDiscard = world.combat.tempContext or {}
                if #cardsToDiscard > 0 then
                    local card = cardsToDiscard[1]
                    world.queue:push({type = "ON_DISCARD", card = card})
                    ProcessEventQueue.execute(world)
                end
            end
        })
    end

    -- PHASE 4: Gambling Chip - Discard any number, draw that many (first turn only)
    if needsGamblingChip then
        -- Request discard context
        world.queue:push({
            type = "COLLECT_CONTEXT",
            contextProvider = {
                type = "cards",
                stability = "temp",
                source = "combat",
                count = {min = 0, max = 10},  -- Can discard 0-10 cards
                filter = function(w, p, card, candidate)
                    return candidate.state == "HAND"
                end
            }
        }, "FIRST")

        -- Discard selected cards and draw that many
        world.queue:push({
            type = "ON_CUSTOM_EFFECT",
            effect = function()
                local cardsToDiscard = world.combat.tempContext or {}
                local count = #cardsToDiscard

                -- Discard selected cards
                for _, card in ipairs(cardsToDiscard) do
                    world.queue:push({type = "ON_DISCARD", card = card})
                end

                ProcessEventQueue.execute(world)

                -- Draw that many cards
                for i = 1, count do
                    world.queue:push({type = "ON_DRAW"})
                end

                ProcessEventQueue.execute(world)

                table.insert(world.log, "Gambling Chip: Discarded " .. count .. " card(s), drew " .. count .. " card(s)")
            end
        })
    end

    -- PHASE 5: Trigger Mayhem AFTER all drawing
    world.queue:push({
        type = "ON_CUSTOM_EFFECT",
        effect = function()
            StartTurn.triggerMayhem(world, player)
        end
    })

    -- PHASE 6: Final cleanup
    world.queue:push({
        type = "ON_CUSTOM_EFFECT",
        effect = function()
            StartTurn.finishTurnStart(world, player)
        end
    })
end

-- Helper: Trigger Mayhem autocasting AFTER draw
function StartTurn.triggerMayhem(world, player)
    local status = player.status or {}
    if status.mayhem and status.mayhem > 0 then
        local Autocast = require("Pipelines.Autocast")
        local stacks = status.mayhem
        world.combat.autocastingNextTopCards = (world.combat.autocastingNextTopCards or 0) + stacks
        table.insert(world.log, "Mayhem (" .. stacks .. ")! Will play top " .. stacks .. " card(s).")

        -- Trigger autocasting
        Autocast.execute(world)
    end
end

-- Helper: Normal path (no context needed)
function StartTurn.drawCardsAndFinish(world, player)
    local cardsToDraw = StartTurn.calculateCardsToDraw(world, player)
    DrawCard.execute(world, player, cardsToDraw)
    StartTurn.triggerMayhem(world, player)  -- Trigger AFTER draw
    StartTurn.finishTurnStart(world, player)
end

-- Main entry point
function StartTurn.execute(world, player)
    table.insert(world.log, "--- Start of Player Turn ---")

    -- Reset turn counters
    if world.combat then
        world.combat.cardsPlayedThisTurn = {}
    end

    -- Exit Divinity stance if player is in it (Divinity only lasts one turn)
    if player.currentStance == "Divinity" then
        ChangeStance.execute(world, {newStance = nil})
    end

    -- Trigger relics' onTurnStart effects
    for _, relic in ipairs(player.relics) do
        if relic.onTurnStart then
            relic:onTurnStart(world, player)
        end
    end

    -- Process queued events from relics
    ProcessEventQueue.execute(world)

    -- Check for die_next_turn status (from Blasphemy) - happens at START of turn
    if player.status and player.status.die_next_turn and player.status.die_next_turn > 0 then
        table.insert(world.log, player.name .. " takes 9999 damage from Blasphemy!")

        world.queue:push({
            type = "ON_NON_ATTACK_DAMAGE",
            source = "Blasphemy",
            target = player,
            amount = 9999,
            tags = {"ignoreBlock"}
        })

        -- Remove the status after triggering (non-degrading, just one-shot)
        player.status.die_next_turn = 0

        ProcessEventQueue.execute(world)
        -- If player somehow survived, continue turn normally
    end

    -- Clear temporary retention flags from all cards
    for _, card in ipairs(player.combatDeck) do
        card.retainThisTurn = nil
    end

    -- Reset turn-based duplication flags
    player.status = player.status or {}
    player.status.necronomiconThisTurn = false  -- Necronomicon can trigger again

    local status = player.status
    local playerName = player.name or player.id or "Player"

    local queuedStatusEvents = false

    if status.shackled and status.shackled > 0 then
        world.queue:push({
            type = "ON_STATUS_GAIN",
            target = player,
            effectType = "Strength",
            amount = status.shackled,
            source = "Shackled"
        })
        status.shackled = nil
        queuedStatusEvents = true
    end

    if status.bias and status.bias > 0 then
        status.focus = (status.focus or 0) - status.bias
        table.insert(world.log, playerName .. " lost " .. status.bias .. " Focus from Bias")
    end

    if status.demon_form and status.demon_form > 0 then
        world.queue:push({
            type = "ON_STATUS_GAIN",
            target = player,
            effectType = "Strength",
            amount = status.demon_form,
            source = "Demon Form"
        })
        queuedStatusEvents = true
    end

    if status.wraith_form and status.wraith_form > 0 then
        status.dexterity = (status.dexterity or 0) - status.wraith_form
        table.insert(world.log, playerName .. " lost " .. status.wraith_form .. " Dexterity from Wraith Form")
    end

    if status.intangible and status.intangible > 0 then
        status.intangible = status.intangible - 1
        table.insert(world.log, playerName .. "'s Intangible decreased to " .. status.intangible)
    end

    if world.enemies then
        for _, enemy in ipairs(world.enemies) do
            if enemy.hp > 0 and enemy.status then
                if enemy.status.shackled and enemy.status.shackled > 0 then
                    world.queue:push({
                        type = "ON_STATUS_GAIN",
                        target = enemy,
                        effectType = "Strength",
                        amount = enemy.status.shackled,
                        source = "Shackled"
                    })
                    enemy.status.shackled = nil
                    queuedStatusEvents = true
                end

                if enemy.status.intangible and enemy.status.intangible > 0 then
                    enemy.status.intangible = enemy.status.intangible - 1
                    local enemyName = enemy.name or "Enemy"
                    table.insert(world.log, enemyName .. "'s Intangible decreased to " .. enemy.status.intangible)
                end
            end
        end
    end

    if queuedStatusEvents then
        ProcessEventQueue.execute(world)
    end

    -- Set Echo Form counter from status effect stacks
    -- Echo Form: first N cards each turn are played twice (N = stacks)
    if player.status and player.status.echo_form and player.status.echo_form > 0 then
        player.status.echoFormThisTurn = player.status.echo_form
    end

    -- Phantasmal: Add to Double Damage at start of turn
    if player.status and player.status.phantasmal and player.status.phantasmal > 0 then
        local stacks = player.status.phantasmal
        player.status.double_damage = (player.status.double_damage or 0) + stacks
        player.status.phantasmal = 0
        table.insert(world.log, playerName .. " gains " .. stacks .. " Double Damage from Phantasmal!")
    end

    -- Simmering Fury: Enter Wrath and draw cards at start of next turn
    if player.status and player.status.simmering_fury and player.status.simmering_fury > 0 then
        world.queue:push({
            type = "CHANGE_STANCE",
            newStance = "Wrath"
        })

        for i = 1, 2 do
            world.queue:push({type = "ON_DRAW"})
        end

        player.status.simmering_fury = 0  -- Clear after triggering
        ProcessEventQueue.execute(world)
    end

    -- Devotion: Gain mantra at start of turn
    if player.status and player.status.devotion and player.status.devotion > 0 then
        world.queue:push({
            type = "ON_STATUS_GAIN",
            target = player,
            effectType = "mantra",
            amount = player.status.devotion
        })
        ProcessEventQueue.execute(world)
    end

    -- Deva Form: Gain increasing energy at start of turn
    if player.status and player.status.deva and player.status.deva > 0 then
        local energyGain = player.status.deva
        player.energy = player.energy + energyGain
        table.insert(world.log, playerName .. " gained " .. energyGain .. " energy from Deva Form")

        local growth = player.status.deva_growth or 0
        if growth > 0 then
            player.status.deva = player.status.deva + growth
            table.insert(world.log, playerName .. "'s Deva Form energy gain increased to " .. player.status.deva)
        end
    end

    -- Loop: Trigger next orb passive at start of turn
    if player.status and player.status.loop and player.status.loop > 0 and #player.orbs > 0 then
        local OrbPassive = require("Pipelines.OrbPassive")
        local triggers = player.status.loop
        table.insert(world.log, "Loop triggers leftmost orb passive " .. triggers .. " time(s)!")
        for i = 1, triggers do
            OrbPassive.triggerSingle(world, 1)  -- Trigger leftmost orb
        end
    end

    -- Inserter: Every 2 turns, gain 1 orb slot
    if Utils.hasRelic(player, "Inserter") then
        world.combat.turnCounter = world.combat.turnCounter + 1
        if world.combat.turnCounter >= 2 then
            player.maxOrbs = player.maxOrbs + 1
            world.combat.turnCounter = 0
            table.insert(world.log, playerName .. " gained 1 orb slot from Inserter")
        end
    end

    -- Emotion Chip: If lost HP last turn, trigger all orb passives
    if Utils.hasRelic(player, "EmotionChip") and world.combat.lastTurnLostHp and #player.orbs > 0 then
        local OrbPassive = require("Pipelines.OrbPassive")
        table.insert(world.log, "Emotion Chip triggers all orb passives!")
        for i = 1, #player.orbs do
            OrbPassive.executeSingle(world, player.orbs[i])
        end
    end

    -- Track HP at turn start for next turn's Emotion Chip
    world.combat.hpAtTurnStart = player.hp
    world.combat.lastTurnLostHp = false

    -- Plasma orbs: Gain 1 energy per Plasma orb at start of turn
    local plasmaCount = 0
    for _, orb in ipairs(player.orbs) do
        if orb.id == "Plasma" then
            plasmaCount = plasmaCount + 1
        end
    end
    if plasmaCount > 0 then
        player.energy = player.energy + plasmaCount
        table.insert(world.log, playerName .. " gained " .. plasmaCount .. " energy from " .. plasmaCount .. " Plasma orb(s)")
    end

    -- Reset block
    player.block = 0

    -- Check for turn-start effects that need context collection
    local needsForesight = player.status and player.status.foresight and player.status.foresight > 0
    local needsToolsOfTrade = player.status and player.status.tools_of_the_trade and player.status.tools_of_the_trade > 0
    local needsGamblingChip = world.combat.turnCounter == 0 and Utils.hasRelic(player, "GamblingChip")

    if needsForesight or needsToolsOfTrade or needsGamblingChip then
        -- Queue all the work including multiple context collections
        StartTurn.queueTurnStartWithContext(world, player, needsForesight, needsToolsOfTrade, needsGamblingChip)

        -- Process queue (will pause at first context request)
        local result = ProcessEventQueue.execute(world)
        if type(result) == "table" and result.needsContext then
            return result  -- Propagate pause to CombatEngine
        end
        return  -- All context collected, everything completed
    end

    -- Normal path (no context needed)
    StartTurn.drawCardsAndFinish(world, player)
end

return StartTurn

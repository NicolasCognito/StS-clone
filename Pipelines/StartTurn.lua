-- START TURN PIPELINE
-- world: the complete game state
-- player: the player character
--
-- Handles:
-- - Clear turn-based player flags (cannotDraw from Bullet Time)
-- - Reset block to 0
-- - Draw cards (5 base + Snecko Eye bonus)
-- - Trigger any start-of-turn power effects
-- - Combat logging
--
-- This centralizes all turn-start logic in one place

local StartTurn = {}

local DrawCard = require("Pipelines.DrawCard")
local ChangeStance = require("Pipelines.ChangeStance")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")

function StartTurn.execute(world, player)
    table.insert(world.log, "--- Start of Player Turn ---")

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

    -- Clear turn-based player flags
    player.cannotDraw = nil  -- Clear Bullet Time's "cannot draw" effect

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

    -- Calculate number of cards to draw
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

    if status.draw_reduction and status.draw_reduction > 0 then
        local reduction = status.draw_reduction
        cardsToDraw = math.max(0, cardsToDraw - reduction)
        status.draw_reduction = nil
        table.insert(world.log, playerName .. " draw reduced by " .. reduction .. " (" .. cardsToDraw .. " card(s) this turn)")
    end

    -- Draw cards
    DrawCard.execute(world, player, cardsToDraw)

    -- Process NIGHTMARE state cards (from Nightmare card)
    -- Move NIGHTMARE cards to hand, respecting max hand size (default 10)
    -- If hand is full, Nightmare cards are removed entirely
    local Utils = require("utils")
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

return StartTurn

-- END TURN PIPELINE
-- world: the complete game state
-- player: the player whose turn is ending
--
-- Handles:
-- - Trigger relics' onEndCombat effects
-- - Process effect queue
-- - Handle Retain mechanics (don't discard retained cards)
-- - Discard remaining hand
-- - Clear temporary turn flags
-- - Reset energy and turn counters
-- - Combat logging

local EndTurn = {}

local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local OrbPassive = require("Pipelines.OrbPassive")
local Utils = require("utils")

function EndTurn.execute(world, player)
    table.insert(world.log, "--- End of Player Turn ---")

    -- Trigger all relics' onEndCombat effects
    for _, relic in ipairs(player.relics) do
        if relic.onEndCombat then
            relic:onEndCombat(world, player)
        end
    end

    -- Process all queued events from relics
    ProcessEventQueue.execute(world)

    -- Trigger orb passive effects (Lightning damage, Frost block, Dark accumulation)
    OrbPassive.execute(world)

    -- Process all queued events from orb passives
    ProcessEventQueue.execute(world)

    -- Frozen Core: If empty orb slots, channel 1 Frost
    if Utils.hasRelic(player, "FrozenCore") and #player.orbs < player.maxOrbs then
        world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Frost"})
        ProcessEventQueue.execute(world)
    end

    -- Track HP loss for Emotion Chip
    if player.hp < world.combat.hpAtTurnStart then
        world.combat.lastTurnLostHp = true
    end

    -- Like Water: If in Calm stance, gain block at end of turn
    if player.status and player.status.like_water and player.status.like_water > 0 then
        if player.currentStance == "Calm" then
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                amount = player.status.like_water
            })
            ProcessEventQueue.execute(world)
        end
    end

    -- NOTE: Status effects (vulnerable, weak, frail, etc.) are now ticked down
    -- in the EndRound pipeline, not here. This is because they are "End of Round"
    -- effects, not "End of Turn" effects.

    -- Handle Retain mechanics and discard hand
    local hasEstablishment = Utils.hasPower(player, "Establishment")

    for _, card in ipairs(player.combatDeck) do
        if card.state == "HAND" then
            -- Check if card has Retain keyword
            if card.retain then
                -- Don't discard, but trigger retain effects
                card.timesRetained = (card.timesRetained or 0) + 1

                -- Establishment power: reduce cost by 1 for each turn retained
                if hasEstablishment then
                    card.retainCostReduction = (card.retainCostReduction or 0) + 1
                end

                -- Push ON_RETAIN event to trigger retention effects
                world.queue:push({
                    type = "ON_RETAIN",
                    card = card,
                    player = player
                })

                -- Card stays in hand (don't change state)
                table.insert(world.log, card.name .. " was retained")
            else
                -- Normal discard via event queue
                world.queue:push({
                    type = "ON_DISCARD",
                    card = card,
                    player = player
                })
            end
        end
    end

    -- Process all discard events
    ProcessEventQueue.execute(world)

    -- Clear temporary turn-based flags from ALL cards
    for _, card in ipairs(player.combatDeck) do
        -- Clear "this turn" effects
        if card.costsZeroThisTurn then
            card.costsZeroThisTurn = nil
        end
        if card.enlightenedThisTurn then
            card.enlightenedThisTurn = nil
        end
    end

    -- Reset turn-based combat trackers
    world.combat.cardsDiscardedThisTurn = 0

    -- Reset energy for next turn
    player.energy = player.maxEnergy

    table.insert(world.log, player.id .. " ended turn")
end

return EndTurn

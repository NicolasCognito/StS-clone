-- AFTER CARD PLAYED PIPELINE
-- Called after a card's onPlay effect has been executed
-- Used for cleanup actions that need to happen after card effects
--
-- Handles:
-- - Double Tap replay (play Attack cards twice)
-- - Pen Nib counter reset (when counter reaches trigger threshold)

local AfterCardPlayed = {}

local Utils = require("utils")

function AfterCardPlayed.execute(world, player)
    -- DOUBLE TAP: Replay Attack cards
    -- Check for Double Tap status (stackable effect from Double Tap skill)
    if player.status and player.status.doubleTap and player.status.doubleTap > 0 then
        local card = world.lastPlayedCard
        local context = world.lastPlayedContext

        if card and card.type == "ATTACK" then
            table.insert(world.log, "Double Tap triggers!")

            -- Clear lastPlayedCard to prevent infinite loop
            -- (the replay will trigger another AFTER_CARD_PLAYED event)
            world.lastPlayedCard = nil
            world.lastPlayedContext = nil

            -- Replay the bracketed section (steps 6-9)
            -- skipDiscard = true because card is already in discard/exhaust pile
            local PlayCard = require("Pipelines.PlayCard")
            PlayCard.executeCardEffect(world, player, card, context, true)

            -- Decrement Double Tap stacks
            player.status.doubleTap = player.status.doubleTap - 1
        end
    end

    -- Reset Pen Nib counter if it has reached trigger threshold
    local penNib = Utils.getRelic(player, "Pen_Nib")
    if penNib and world.penNibCounter >= penNib.triggerCount then
        world.penNibCounter = 0
        table.insert(world.log, "Pen Nib reset!")
    end
end

return AfterCardPlayed

-- AUTOCAST PIPELINE
-- Handles autocasting top cards from draw pile
-- Used by: Mayhem power, Distilled Chaos potion
--
-- Processes world.combat.autocastingNextTopCards counter
-- For each card to autocast:
-- - Get top card from DECK
-- - Play it with skipEnergyCost=true
-- - Process all effects fully (using auto mode)

local Autocast = {}

local PlayCard = require("Pipelines.PlayCard")

function Autocast.execute(world)
    if not world or not world.combat then
        return
    end

    local Utils = require("utils")
    local player = world.player

    -- Process all autocasts
    while world.combat.autocastingNextTopCards and world.combat.autocastingNextTopCards > 0 do
        -- Get top card from deck
        local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
        local topCard = deckCards[1]

        if not topCard then
            -- No more cards in deck
            table.insert(world.log, "Auto-casting: No more cards in draw pile.")
            world.combat.autocastingNextTopCards = 0
            break
        end

        -- Decrement counter BEFORE playing (in case card triggers more autocasts)
        world.combat.autocastingNextTopCards = world.combat.autocastingNextTopCards - 1

        table.insert(world.log, "Auto-casting: " .. topCard.name .. " (" .. world.combat.autocastingNextTopCards .. " remaining)")

        -- Check if card is playable
        if not topCard.onPlay or type(topCard.onPlay) ~= "function" then
            -- Card is unplayable - skip it
            table.insert(world.log, topCard.name .. " has no effect (Unplayable)")
            topCard.state = "DISCARD_PILE"
            -- Continue to next card in loop
        else
            -- Play card with auto mode (handles context collection automatically)
            PlayCard.execute(world, player, topCard, {
                auto = true,
                skipEnergyCost = true,
                playSource = "Autocast",
                energySpentOverride = player.energy  -- X-cost uses current energy
            })
        end
    end
end

return Autocast

-- RESOLVE CARD PIPELINE
-- Pops the next scheduled card execution from the card queue and resolves it.
-- Also handles auto-casting top cards from deck (Mayhem, Distilled Chaos)

local ResolveCard = {}

local PlayCard = require("Pipelines.PlayCard")

function ResolveCard.execute(world)
    if not world or not world.cardQueue then
        return nil
    end

    -- If CardQueue is empty, check for autocasting
    if world.cardQueue:isEmpty() then
        if world.combat and world.combat.autocastingNextTopCards and world.combat.autocastingNextTopCards > 0 then
            local Utils = require("utils")
            local player = world.player

            -- Get current top card
            local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
            local topCard = deckCards[1]

            if topCard then
                -- Decrement counter BEFORE playing (in case card triggers more autocasts)
                world.combat.autocastingNextTopCards = world.combat.autocastingNextTopCards - 1

                table.insert(world.log, "Auto-casting: " .. topCard.name .. " (" .. world.combat.autocastingNextTopCards .. " remaining)")

                -- Save state
                topCard._previousState = topCard.state
                topCard.state = "PROCESSING"

                -- Auto-play
                local success = PlayCard.autoExecute(world, player, topCard, {
                    skipEnergyCost = true,
                    playSource = "Mayhem",
                    energySpentOverride = player.energy  -- X-cost uses current energy
                })

                -- Restore on failure
                if not success then
                    topCard.state = topCard._previousState or "DECK"
                    topCard._previousState = nil
                    table.insert(world.log, "Failed to auto-cast " .. topCard.name)
                end

                -- ResolveCard will be called again after this card finishes
                return
            else
                -- No more cards in deck, clear counter
                table.insert(world.log, "Auto-casting: No more cards in draw pile.")
                world.combat.autocastingNextTopCards = 0
            end
        end

        return nil
    end

    local entry = world.cardQueue:pop()
    if not entry then
        return nil
    end

    -- Handle separator entries
    if entry.type == "SEPARATOR" then
        table.insert(world.log, "--- New Card ---")

        -- Clear context when transitioning between different cards
        if world.combat then
            world.combat.stableContext = nil
            world.combat.tempContext = nil
        end

        -- Continue to next entry if queue isn't empty
        if not world.cardQueue:isEmpty() then
            return ResolveCard.execute(world)
        end
        return nil
    end

    return PlayCard.resolveQueuedEntry(world, entry)
end

return ResolveCard

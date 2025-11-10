return {
    Omniscience = {
        id = "Omniscience",
        name = "Omniscience",
        cost = 4,
        type = "SKILL",
        description = "Choose a card in your draw pile. Play the chosen card twice and Exhaust it.",

        -- CONTEXT PROVIDER: Select 1 card from draw pile
        contextProvider = {
            source = "combat",
            count = {min = 1, max = 1},
            filter = function(world, player, card, candidateCard)
                -- Only show cards in DECK state (draw pile)
                return candidateCard.state == "DECK"
            end
        },

        -- ON PLAY: Play chosen card twice, then exhaust it
        onPlay = function(self, world, player, chosenCards)
            local chosenCard = chosenCards[1]
            local ContextProvider = require("Pipelines.ContextProvider")
            local PlayCard = require("Pipelines.PlayCard")
            local ProcessEffectQueue = require("Pipelines.ProcessEffectQueue")

            table.insert(world.log, "Omniscience: Playing " .. chosenCard.name .. " twice!")

            -- Collect context for the chosen card (e.g., enemy target, card selections, etc.)
            local chosenCardContext = ContextProvider.execute(world, player, chosenCard)

            -- Store energy spent as 0 (card is played for free via Omniscience)
            chosenCard.energySpent = 0
            chosenCard.costWhenPlayed = 0

            -- FIRST PLAY
            -- Execute the chosen card's effect (stats tracking, onPlay, queue processing, discard/exhaust)
            PlayCard.executeCardEffect(world, player, chosenCard, chosenCardContext, false)

            -- SECOND PLAY (forced by Omniscience, doesn't check duplication system)
            table.insert(world.log, "Omniscience plays " .. chosenCard.name .. " again!")
            -- skipDiscard = true because card is already in discard/exhaust pile from first play
            PlayCard.executeCardEffect(world, player, chosenCard, chosenCardContext, true)

            -- EXHAUST the chosen card
            -- Move card from wherever it is (discard pile) to exhaust pile
            chosenCard.state = "EXHAUSTED_PILE"
            world.queue:push({
                type = "ON_EXHAUST",
                card = chosenCard,
                source = "Omniscience"
            })
            ProcessEffectQueue.execute(world)

            table.insert(world.log, chosenCard.name .. " was exhausted by Omniscience")
        end,

        onUpgrade = function(self)
            self.cost = 2
            self.description = "Choose a card in your draw pile. Play the chosen card twice and Exhaust it."
        end
    }
}

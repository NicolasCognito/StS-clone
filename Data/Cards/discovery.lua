return {
    Discovery = {
        id = "Discovery",
        name = "Discovery",
        cost = 1,
        type = "SKILL",
        description = "Choose 1 of 3 random cards to add to your hand. It costs 0 this turn.",

        -- PRE-PLAY ACTION: Generate 3 random cards before player chooses
        prePlayAction = function(self, world, player)
            -- Get all available cards (for testing, use current deck cards)
            local Cards = require("Data.cards")
            local cardPool = {
                Cards.Strike,
                Cards.Defend,
                Cards.Bash,
                Cards.Catalyst,
                Cards.InfernalBlade,
                Cards.Corruption,
            }

            -- Generate 3 random cards and add to combatDeck with DRAFT state
            for i = 1, 3 do
                local randomCard = cardPool[math.random(1, #cardPool)]

                -- Create a copy of the card template
                local draftCard = {}
                for k, v in pairs(randomCard) do
                    draftCard[k] = v
                end

                -- Mark as DRAFT (temporary state for selection)
                draftCard.state = "DRAFT"

                -- Add to combat deck
                table.insert(player.combatDeck, draftCard)
            end

            table.insert(world.log, "Choose 1 of 3 cards...")
        end,

        -- CONTEXT PROVIDER: Filter for DRAFT cards
        contextProvider = {
            source = "combat",
            count = {min = 1, max = 1},
            filter = function(world, player, card, candidateCard)
                -- Only show cards in DRAFT state
                return candidateCard.state == "DRAFT"
            end
        },

        -- ON PLAY: Move chosen card to hand, remove other drafts
        onPlay = function(self, world, player, chosenCards)
            local chosenCard = chosenCards[1]

            -- Move chosen card to hand with cost 0 this turn
            chosenCard.state = "HAND"
            chosenCard.costsZeroThisTurn = 1

            table.insert(world.log, "Added " .. chosenCard.name .. " to hand (costs 0 this turn)")

            -- Remove other DRAFT cards from combatDeck
            for i = #player.combatDeck, 1, -1 do
                local card = player.combatDeck[i]
                if card.state == "DRAFT" and card ~= chosenCard then
                    table.remove(player.combatDeck, i)
                end
            end
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Choose 1 of 3 random cards to add to your hand. It costs 0 this turn."
        end
    }
}

return {
    Discovery = {
        id = "Discovery",
        name = "Discovery",
        cost = 1,
        type = "SKILL",
        character = "COLORLESS",
        rarity = "COMMON",
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

        -- ON PLAY: Request card selection, then move chosen card to hand
        onPlay = function(self, world, player)
            -- Request context collection for DRAFT cards
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "cards",
                    stability = "temp",
                    source = "combat",
                    count = {min = 1, max = 1},
                    filter = function(world, player, card, candidateCard)
                        return candidateCard.state == "DRAFT"
                    end
                }
            }, "FIRST")

            -- Resolve the choice after context has been collected
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local selectedCards = world.combat.tempContext or {}
                    local chosenCard = selectedCards[1]
                    if not chosenCard then
                        table.insert(world.log, "Discovery had no cards to choose from.")
                        return
                    end

                    chosenCard.state = "HAND"
                    chosenCard.costsZeroThisTurn = 1
                    table.insert(world.log, "Added " .. chosenCard.name .. " to hand (costs 0 this turn)")

                    for i = #player.combatDeck, 1, -1 do
                        local card = player.combatDeck[i]
                        if card.state == "DRAFT" and card ~= chosenCard then
                            table.remove(player.combatDeck, i)
                        end
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Choose 1 of 3 random cards to add to your hand. It costs 0 this turn."
        end
    }
}

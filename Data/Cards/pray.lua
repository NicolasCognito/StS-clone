return {
    Pray = {
        id = "Pray",
        name = "Pray",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Gain 3 Mantra. Shuffle an Insight into your draw pile.",
        mantra = 3,

        onPlay = function(self, world, player)
            local Cards = require("Data.cards")
            local Utils = require("utils")

            -- Gain mantra
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "mantra",
                amount = self.mantra
            })

            -- Shuffle Insight into draw pile
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local insightCard = Utils.copyCardTemplate(Cards.Insight)
                    insightCard.state = "DECK"
                    table.insert(player.combatDeck, insightCard)

                    -- Shuffle the draw pile
                    if not world.NoShuffle then
                        Utils.shuffleDeck(player.combatDeck, world)
                    end

                    table.insert(world.log, "Shuffled Insight into draw pile")
                end
            })
        end,

        onUpgrade = function(self)
            self.mantra = 4
            self.description = "Gain 4 Mantra. Shuffle an Insight into your draw pile."
            self.upgraded = true
        end
    }
}

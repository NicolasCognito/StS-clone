local Utils = require("utils")

return {
    Havoc = {
        id = "Havoc",
        name = "Havoc",
        cost = 1,
        type = "SKILL",
        character = "IRONCLAD",
        rarity = "UNCOMMON",
        exhausts = true,
        description = "Play the top card of your draw pile and Exhaust it.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    -- Lazy-load PlayCard to avoid circular dependency
                    local PlayCard = require("Pipelines.PlayCard")

                    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
                    local topCard = deckCards[1]

                    if not topCard then
                        table.insert(world.log, "Havoc found no card to play.")
                        return
                    end

                    topCard._previousState = topCard.state
                    topCard.state = "PROCESSING"

                    local success = PlayCard.execute(world, player, topCard, {
                        auto = true,
                        playSource = "Havoc",
                        energySpentOverride = 0,
                        forcedExhaust = "Havoc"  -- Force card to exhaust after play
                    })

                    if not success then
                        topCard.state = topCard._previousState or "DECK"
                        topCard._previousState = nil
                        topCard._forcedReplays = nil
                        table.insert(world.log, "Havoc failed to play " .. topCard.name .. ".")
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.cost = 0
            self.description = "Play the top card of your draw pile and Exhaust it."
        end
    }
}

local Utils = require("utils")
local PlayCard = require("Pipelines.PlayCard")

return {
    Havoc = {
        id = "Havoc",
        name = "Havoc",
        cost = 1,
        type = "SKILL",
        exhausts = true,
        description = "Play the top card of your draw pile. Exhaust.",

        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local deckCards = Utils.getCardsByState(player.combatDeck, "DECK")
                    local topCard = deckCards[1]

                    if not topCard then
                        table.insert(world.log, "Havoc found no card to play.")
                        return
                    end

                    topCard._previousState = topCard.state
                    topCard.state = "PROCESSING"

                    local success = PlayCard.autoExecute(world, player, topCard, {
                        skipEnergyCost = true,
                        playSource = "Havoc",
                        energySpentOverride = 0
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
            self.description = "Play the top card of your draw pile. Exhaust."
        end
    }
}

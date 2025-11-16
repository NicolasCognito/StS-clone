return {
    DistilledChaos = {
        id = "DistilledChaos",
        name = "Distilled Chaos",
        rarity = "UNCOMMON",
        description = "Play the top 3 cards of your draw pile.",

        onUse = function(self, world, player)
            local Utils = require("utils")

            -- Check for Sacred Bark relic (doubles potion effectiveness)
            local cardsToPlay = 3
            if Utils.hasRelic(player, "Sacred_Bark") then
                cardsToPlay = 6
                table.insert(world.log, "Sacred Bark! Playing 6 cards instead of 3.")
            end

            -- Set the autocasting counter
            world.combat.autocastingNextTopCards = (world.combat.autocastingNextTopCards or 0) + cardsToPlay
            table.insert(world.log, "Distilled Chaos will play top " .. cardsToPlay .. " cards.")
        end
    }
}

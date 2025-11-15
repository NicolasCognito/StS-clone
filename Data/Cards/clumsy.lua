-- Clumsy (Curse)
-- Unplayable. Ethereal.
-- Can be played with Blue Candle relic: Lose 1 HP, Exhaust.

return {
    Clumsy = {
        id = "Clumsy",
        name = "Clumsy",
        cost = 0,
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        ethereal = true,
        exhausts = true,
        description = "Unplayable. Ethereal. (Discarded at end of turn.)",

        -- Only playable with Blue Candle relic
        isPlayable = function(self, world, player)
            local Utils = require("utils")
            if Utils.hasRelic(player, "Blue_Candle") then
                return true
            end
            return false, "Clumsy is unplayable"
        end,

        -- When played (via Blue Candle): Lose 1 HP
        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = self,
                target = player,
                amount = 1,
                tags = {"ignoreBlock"}
            })
            table.insert(world.log, player.name .. " plays Clumsy, losing 1 HP")
        end
    }
}

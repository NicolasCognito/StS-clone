-- Pain (Curse)
-- Unplayable. When you exhaust this card, lose 1 HP.
-- Can be played with Blue Candle relic: Lose 1 HP, Exhaust (triggers onExhaust for additional 1 HP).

return {
    Pain = {
        id = "Pain",
        name = "Pain",
        cost = 0,
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        exhausts = true,
        description = "Unplayable. When you exhaust this card, lose 1 HP.",

        -- Only playable with Blue Candle relic
        isPlayable = function(self, world, player)
            local Utils = require("utils")
            if Utils.hasRelic(player, "Blue_Candle") then
                return true
            end
            return false, "Pain is unplayable"
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
            table.insert(world.log, player.name .. " plays Pain, losing 1 HP")
        end,

        -- Hook for onExhaust: Lose 1 HP (triggers when exhausted by any means, including Blue Candle play)
        onExhaust = function(self, world, player)
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = self,
                target = player,
                amount = 1,
                tags = {"ignoreBlock"}
            })
            table.insert(world.log, player.name .. " loses 1 HP from exhausting Pain!")
        end
    }
}

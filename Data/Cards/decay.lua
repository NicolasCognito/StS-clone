-- Decay (Curse)
-- Unplayable. At the end of your turn, lose 2 HP.
-- Can be played with Blue Candle relic: Lose 1 HP, Exhaust.

return {
    Decay = {
        id = "Decay",
        name = "Decay",
        cost = 0,
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        exhausts = true,
        description = "Unplayable. At the end of your turn, lose 2 HP.",

        -- Only playable with Blue Candle relic
        isPlayable = function(self, world, player)
            local Utils = require("utils")
            if Utils.hasRelic(player, "Blue_Candle") then
                return true
            end
            return false, "Decay is unplayable"
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
            table.insert(world.log, player.name .. " plays Decay, losing 1 HP")
        end,

        -- Hook for end of turn (would need to be checked in EndTurn pipeline)
        onEndOfTurn = function(self, world, player)
            -- Only trigger if this card is in hand at end of turn
            if self.state == "HAND" then
                world.queue:push({
                    type = "ON_NON_ATTACK_DAMAGE",
                    source = self,
                    target = player,
                    amount = 2,
                    tags = {"ignoreBlock"}
                })
                table.insert(world.log, player.name .. " loses 2 HP from Decay!")
            end
        end
    }
}

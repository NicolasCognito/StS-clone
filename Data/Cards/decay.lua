-- Decay (Curse)
-- Unplayable. At the end of your turn, lose 2 HP.
-- Can be played with Blue Candle relic (handled by StartCombat pipeline)

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

        -- Unplayable by default (Blue Candle overrides this in StartCombat)
        isPlayable = function(self, world, player)
            return false, "Decay is unplayable"
        end,

        -- No onPlay - Blue Candle adds this dynamically

        -- Hook for end of turn (checked in EndTurn pipeline)
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

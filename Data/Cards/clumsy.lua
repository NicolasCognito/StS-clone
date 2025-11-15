-- Clumsy (Curse)
-- Unplayable. Ethereal.
-- Can be played with Blue Candle relic (handled by StartCombat pipeline)

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

        -- Unplayable by default (Blue Candle overrides this in StartCombat)
        isPlayable = function(self, world, player)
            return false, "Clumsy is unplayable"
        end

        -- No onPlay - Blue Candle adds this dynamically
    }
}

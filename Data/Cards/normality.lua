-- Normality (Curse)
-- You cannot play more than 3 cards this turn.
-- Can be played with Blue Candle relic (handled by StartCombat pipeline)

return {
    Normality = {
        id = "Normality",
        name = "Normality",
        cost = 0,
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        exhausts = true,
        description = "Unplayable. You cannot play more than 3 cards this turn.",

        -- Unplayable by default (Blue Candle overrides this in StartCombat)
        isPlayable = function(self, world, player)
            return false, "Normality is unplayable"
        end

        -- No onPlay - Blue Candle adds this dynamically
    }
}

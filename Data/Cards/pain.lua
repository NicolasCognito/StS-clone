-- Pain (Curse)
-- Unplayable. While in hand, lose 1 HP whenever you play a card.
-- Can be played with Blue Candle relic (handled by StartCombat pipeline)
-- Pain's trigger-on-other-cards effect is handled in AfterCardPlayed pipeline

return {
    Pain = {
        id = "Pain",
        name = "Pain",
        cost = 0,
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        exhausts = true,
        description = "Unplayable. While in hand, lose 1 HP whenever you play a card.",

        -- Unplayable by default (Blue Candle overrides this in StartCombat)
        isPlayable = function(self, world, player)
            return false, "Pain is unplayable"
        end

        -- No onPlay - Blue Candle adds this dynamically
        -- Pain's "deal 1 HP when playing other cards" is handled in AfterCardPlayed pipeline
    }
}

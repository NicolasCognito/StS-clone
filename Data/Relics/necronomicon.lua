return {
    Necronomicon = {
        id = "Necronomicon",
        name = "Necronomicon",
        rarity = "EVENT",
        description = "The first Attack you play each turn that costs 2 or more is played twice.",

        -- No configuration values needed
        -- Duplication logic is entirely handled in PlayCard_DuplicationHelpers
        -- - Checks for relic presence via Utils.hasRelic(player, "Necronomicon")
        -- - Validates card.type == "ATTACK" and card.costWhenPlayed >= 2
        -- - Uses player.status.necronomiconThisTurn flag (reset each turn in StartTurn)
    }
}

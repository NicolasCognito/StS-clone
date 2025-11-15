return {
    GamblingChip = {
        id = "GamblingChip",
        name = "Gambling Chip",
        rarity = "RARE",
        description = "At the start of each combat, discard any number of cards, then draw that many.",

        -- Note: The actual effect is triggered in StartTurn.lua
        -- This relic doesn't need onTurnStart or onCombatStart hooks
        -- because it's handled specially in the turn-start context collection flow
    }
}

-- PAINFUL STABS STATUS EFFECT
-- Enemy buff that shuffles a Wound into the player's discard pile
-- whenever the enemy deals unblocked attack damage
return {
    painful_stabs = {
        id = "painful_stabs",
        name = "Painful Stabs",
        description = "Shuffle 1 Wound into discard pile whenever this enemy deals unblocked attack damage.",
        minValue = 0,
        maxValue = 999,
        stackType = "intensity",
        debuff = false

        -- NOTE: The actual triggering logic is in the DealAttackDamage pipeline
        -- This status is checked when damage is dealt to determine if a Wound should be added
    }
}

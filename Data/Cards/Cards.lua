-- CARDS DATA
-- Ironclad starting deck and basic cards
-- Each card is pure data with id, name, cost, type, and effect parameters

local Cards = {
    Strike = {
        id = "Strike",
        name = "Strike",
        cost = 1,
        type = "ATTACK",
        damage = 6,
        description = "Deal 6 damage."
    },

    Defend = {
        id = "Defend",
        name = "Defend",
        cost = 1,
        type = "SKILL",
        block = 5,
        description = "Gain 5 block."
    },

    Bash = {
        id = "Bash",
        name = "Bash",
        cost = 1,
        type = "ATTACK",
        damage = 8,
        description = "Deal 8 damage."
    },

    HeavyBlade = {
        id = "Heavy_Blade",
        name = "Heavy Blade",
        cost = 2,
        type = "ATTACK",
        damage = 14,
        strengthMultiplier = 3,
        description = "Deal 14 damage. Strength affects this card 3 times."
    }
}

return Cards

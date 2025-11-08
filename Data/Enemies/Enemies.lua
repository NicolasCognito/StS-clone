-- ENEMIES DATA
-- Enemy definitions with their stats and attack patterns

local Enemies = {
    Goblin = {
        id = "Goblin",
        name = "Goblin",
        hp = 12,
        maxHp = 12,

        -- Intent: what this enemy does each turn
        -- For now, very simple: just deal damage
        intent = {
            type = "ATTACK",
            damage = 5
        },

        description = "A basic goblin enemy."
    }
}

return Enemies

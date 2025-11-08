-- ENEMIES DATA
-- Enemy definitions with their stats and attack patterns
-- Each enemy has:
-- - Data parameters (hp, maxHp, damage values)
-- - executeIntent: pushes event to queue representing enemy's action

local Enemies = {
    Goblin = {
        id = "Goblin",
        name = "Goblin",
        hp = 12,
        maxHp = 12,
        block = 0,
        damage = 5,
        description = "A basic goblin enemy.",

        executeIntent = function(self, world, player)
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = self,
                defender = player,
                card = self  -- enemy acts like a "card" for pipeline purposes
            })
        end
    }
}

return Enemies

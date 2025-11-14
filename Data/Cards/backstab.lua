-- BACKSTAB
-- Silent Uncommon Attack
-- Innate. Deal 11 (15) damage. Exhaust.

return {
    Backstab = {
        id = "Backstab",
        name = "Backstab",
        cost = 0,
        type = "ATTACK",
        character = "SILENT",
        rarity = "UNCOMMON",
        innate = true,
        exhausts = true,
        damage = 11,
        upgraded = false,
        description = "Innate. Deal 11 damage. Exhaust.",

        onPlay = function(self, world, player)
            -- Request enemy target (stable context for duplications)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "enemy",
                    stability = "stable"
                }
            }, "FIRST")

            -- Deal damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 15
            self.upgraded = true
            self.description = "Innate. Deal 15 damage. Exhaust."
        end
    }
}

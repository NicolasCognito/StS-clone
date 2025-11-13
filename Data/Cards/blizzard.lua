-- BLIZZARD
-- Attack: Deal 2 damage to all enemies for each Frost Orb channeled this combat.
return {
    Blizzard = {
        id = "Blizzard",
        name = "Blizzard",
        cost = 1,
        type = "ATTACK",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Deal 2 damage to all enemies for each Frost channeled this combat.",

        onPlay = function(self, world, player)
            local damagePerFrost = self.upgraded and 3 or 2
            local frostCount = world.combat.frostChanneledThisCombat or 0
            local totalDamage = damagePerFrost * frostCount

            -- Deal AOE damage (override card's damage)
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local originalDamage = self.damage
                    self.damage = totalDamage

                    world.queue:push({
                        type = "ON_ATTACK_DAMAGE",
                        attacker = player,
                        defender = "all",
                        card = self
                    })

                    self.damage = originalDamage
                end
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Deal 3 damage to all enemies for each Frost channeled this combat."
        end
    }
}

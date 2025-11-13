return {
    Brilliance = {
        id = "Brilliance",
        name = "Brilliance",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "RARE",
        description = "Deal 12 damage. Add your Mantra count to the damage dealt.",
        damage = 12,

        onPlay = function(self, world, player)
            -- Collect target context
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "enemy",
                    stability = "stable"
                }
            }, "FIRST")

            -- Calculate total damage (base + mantra)
            local mantraCount = (player.status and player.status.mantra) or 0
            local totalDamage = self.damage + mantraCount

            -- Deal damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self,
                damageOverride = totalDamage
            })
        end,

        onUpgrade = function(self)
            self.damage = 16
            self.description = "Deal 16 damage. Add your Mantra count to the damage dealt."
            self.upgraded = true
        end
    }
}

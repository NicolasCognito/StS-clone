-- Thunderclap: Deal damage and apply Vulnerable to ALL enemies
-- Classic AOE attack card from Slay the Spire
-- Demonstrates combined AOE damage + AOE status effect

return {
    Thunderclap = {
        id = "Thunderclap",
        name = "Thunderclap",
        cost = 1,
        type = "ATTACK",
        rarity = "COMMON",
        damage = 7,
        description = "Deal 7 damage and apply 1 Vulnerable to ALL enemies.",
        keywords = {"Vulnerable"},
        upgraded = false,

        onPlay = function(self, world, player, context)
            -- Deal damage to all enemies
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = "all",  -- AOE damage
                card = self
            })

            -- Apply vulnerable to all enemies
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = "all",  -- AOE status effect
                effectType = "Vulnerable",
                amount = 1,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.damage = 10
            self.name = "Thunderclap+"
            self.description = "Deal 10 damage and apply 1 Vulnerable to ALL enemies."
        end
    }
}

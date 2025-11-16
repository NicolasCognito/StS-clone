-- Reaper: AOE attack that heals for HP lost
-- Rare Ironclad attack from Slay the Spire
-- Demonstrates healing based on actual damage dealt (no overkill)

return {
    Reaper = {
        id = "Reaper",
        name = "Reaper",
        cost = 2,
        type = "ATTACK",
        character = "IRONCLAD",
        rarity = "RARE",
        damage = 4,
        exhausts = true,
        reaperEffect = true,  -- Flag for DealAttackDamage pipeline to trigger healing
        description = "Deal 4 damage to ALL enemies. Heal HP equal to unblocked damage. Exhaust.",
        keywords = {"Exhaust"},
        upgraded = false,

        onPlay = function(self, world, player)
            -- Simple AOE attack - healing is automatically handled by DealAttackDamage pipeline
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = "all",  -- Hit all enemies
                card = self
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.cost = 1
            self.damage = 5
            self.name = "Reaper+"
            self.description = "Deal 5 damage to ALL enemies. Heal HP equal to unblocked damage. Exhaust."
        end
    }
}

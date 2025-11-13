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

            -- Set damage based on Frost count
            self.damage = damagePerFrost * frostCount

            -- Deal AOE damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = "all",
                card = self
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Deal 3 damage to all enemies for each Frost channeled this combat."
        end
    }
}

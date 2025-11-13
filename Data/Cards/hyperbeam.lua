-- HYPERBEAM
-- Attack: Deal 26 damage to all enemies. Lose 3 Focus.
return {
    Hyperbeam = {
        id = "Hyperbeam",
        name = "Hyperbeam",
        cost = 2,
        type = "ATTACK",
        character = "DEFECT",
        rarity = "RARE",
        damage = 26,
        upgraded = false,
        description = "Deal 26 damage to all enemies. Lose 3 Focus.",

        onPlay = function(self, world, player)
            -- Deal AOE damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = "all",
                card = self
            })

            -- Lose Focus
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                status = "focus",
                amount = -3
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.damage = 34
            self.description = "Deal 34 damage to all enemies. Lose 3 Focus."
        end
    }
}

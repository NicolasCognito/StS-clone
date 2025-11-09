return {
    BloodForBlood = {
        id = "Blood_for_Blood",
        name = "Blood for Blood",
        cost = 4,
        type = "ATTACK",
        damage = 18,
        costReductionPerHpLoss = 1,  -- Reduces cost by 1 for each time player lost HP
        Targeted = 1,
        description = "Deal 18 damage. Costs 1 less for each time you lose HP this combat.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.cost = 3
            self.damage = 22
            self.description = "Deal 22 damage. Costs 1 less for each time you lose HP this combat."
        end
    }
}

return {
    FirePotion = {
        id = "FirePotion",
        name = "Fire Potion",
        description = "Deal 15 damage to ALL enemies.",

        onUse = function(self, world, player)
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = self,
                target = "all",
                amount = 15
            })
        end
    }
}

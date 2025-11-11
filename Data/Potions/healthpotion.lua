return {
    HealthPotion = {
        id = "HealthPotion",
        name = "Health Potion",
        description = "Heal 20 HP.",

        onUse = function(self, world, player)
            world.queue:push({
                type = "ON_HEAL",
                target = player,
                amount = 20,
                source = self
            })
        end
    }
}

return {
    BlockPotion = {
        id = "BlockPotion",
        name = "Block Potion",
        description = "Gain 12 block.",
        block = 12,

        onUse = function(self, world, player)
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                source = self
            })
        end
    }
}

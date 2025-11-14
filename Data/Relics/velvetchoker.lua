return {
    VelvetChoker = {
        id = "Velvet_Choker",
        name = "Velvet Choker",
        rarity = "BOSS",
        description = "Gain 1 Energy at the start of each turn. You cannot play more than 6 cards per turn.",

        onTurnStart = function(self, world, player)
            player.energy = player.energy + 1
            table.insert(world.log, "Velvet Choker grants +1 energy")
        end
    }
}

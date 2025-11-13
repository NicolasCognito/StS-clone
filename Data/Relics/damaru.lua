return {
    Damaru = {
        id = "Damaru",
        name = "Damaru",
        rarity = "COMMON",
        character = "WATCHER",
        description = "At the start of your turn, gain 1 Mantra.",

        onTurnStart = function(self, world, player)
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = player,
                effectType = "mantra",
                amount = 1
            })
        end
    }
}

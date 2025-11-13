return {
    TeardropLocket = {
        id = "Teardrop_Locket",
        name = "Teardrop Locket",
        rarity = "UNCOMMON",
        character = "WATCHER",
        description = "Start each combat in Calm.",

        onCombatStart = function(self, world)
            -- Start in Calm (don't ENTER - no energy gain or other enter effects)
            world.player.currentStance = "Calm"
            table.insert(world.log, world.player.name .. " starts combat in Calm stance")
        end
    }
}

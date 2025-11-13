return {
    TeardropLocket = {
        id = "Teardrop_Locket",
        name = "Teardrop Locket",
        rarity = "UNCOMMON",
        character = "WATCHER",
        description = "Start each combat in Calm.",

        onCombatStart = function(self, world)
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Calm"
            })
        end
    }
}

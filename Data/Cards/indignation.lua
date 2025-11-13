return {
    Indignation = {
        id = "Indignation",
        name = "Indignation",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Enter Wrath. If you are already in Wrath, apply 3 Vulnerable to ALL enemies.",
        vulnerable = 3,

        onPlay = function(self, world, player)
            if player.currentStance == "Wrath" then
                -- Already in Wrath: apply vulnerable to all enemies
                world.queue:push({
                    type = "ON_STATUS_GAIN",
                    target = "all",
                    effectType = "vulnerable",
                    amount = self.vulnerable
                })
            else
                -- Not in Wrath: enter Wrath
                world.queue:push({
                    type = "CHANGE_STANCE",
                    newStance = "Wrath"
                })
            end
        end,

        onUpgrade = function(self)
            self.vulnerable = 4
            self.description = "Enter Wrath. If you are already in Wrath, apply 4 Vulnerable to ALL enemies."
            self.upgraded = true
        end
    }
}

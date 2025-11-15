-- TACTICIAN
-- Silent Uncommon Skill
-- Unplayable. When discarded: Gain 1 Energy.

return {
    Tactician = {
        id = "Tactician",
        name = "Tactician",
        cost = 0,
        type = "SKILL",
        character = "SILENT",
        rarity = "UNCOMMON",
        upgraded = false,
        description = "Unplayable. When discarded: Gain 1 Energy.",

        isPlayable = function(self, world, player)
            return false, "Tactician is unplayable"
        end,

        onDiscard = function(self, world, player)
            player.energy = player.energy + 1
            table.insert(world.log, "Tactician triggers! Gained 1 energy")
        end,

        onUpgrade = function(self)
            self.upgraded = true
            -- Effect stays the same when upgraded
        end
    }
}

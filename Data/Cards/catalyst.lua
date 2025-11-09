return {
    Catalyst = {
        id = "Catalyst",
        name = "Catalyst",
        cost = 1,
        type = "SKILL",
        poisonMultiplier = 2,
        Targeted = 1,
        description = "Double the target's Poison.",

        onPlay = function(self, world, player, target)
            -- Check if target has poison status
            if target.status and target.status.poison and target.status.poison > 0 then
                local oldPoison = target.status.poison
                local newPoison = oldPoison * self.poisonMultiplier
                target.status.poison = newPoison
                table.insert(world.log, target.name .. "'s Poison increased from " .. oldPoison .. " to " .. newPoison)
            else
                table.insert(world.log, target.name .. " has no Poison to multiply")
            end
        end,

        onUpgrade = function(self)
            self.poisonMultiplier = 3
            self.description = "Triple the target's Poison."
        end
    }
}

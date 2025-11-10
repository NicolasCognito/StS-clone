local function formatStackMessage(stacks)
    if stacks == 1 then
        return "next skill"
    end
    return "next " .. stacks .. " skills"
end

return {
    Burst = {
        id = "Burst",
        name = "Burst",
        cost = 1,
        type = "SKILL",
        burstStacks = 1,
        description = "Your next Skill is played twice.",

        onPlay = function(self, world, player)
            player.status = player.status or {}
            player.status.burst = (player.status.burst or 0) + self.burstStacks
            table.insert(world.log, player.name .. "'s Burst readied the " .. formatStackMessage(self.burstStacks) .. ".")
        end,

        onUpgrade = function(self)
            self.burstStacks = 2
            self.description = "Your next 2 Skills are played twice."
        end
    }
}

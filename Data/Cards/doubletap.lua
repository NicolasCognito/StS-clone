local function formatStackMessage(stacks)
    if stacks == 1 then
        return "next attack"
    end
    return "next " .. stacks .. " attacks"
end

return {
    DoubleTap = {
        id = "DoubleTap",
        name = "Double Tap",
        cost = 1,
        type = "SKILL",
        doubleTapStacks = 1,
        description = "Your next Attack is played twice.",

        onPlay = function(self, world, player)
            player.status = player.status or {}
            player.status.doubleTap = (player.status.doubleTap or 0) + self.doubleTapStacks
            table.insert(world.log, player.name .. "'s Double Tap readied the " .. formatStackMessage(self.doubleTapStacks) .. ".")
        end,

        onUpgrade = function(self)
            self.doubleTapStacks = 2
            self.description = "Your next 2 Attacks are played twice."
        end
    }
}

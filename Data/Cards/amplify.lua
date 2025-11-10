local function formatStackMessage(stacks)
    if stacks == 1 then
        return "next power"
    end
    return "next " .. stacks .. " powers"
end

return {
    Amplify = {
        id = "Amplify",
        name = "Amplify",
        cost = 1,
        type = "SKILL",
        character = "COLORLESS",
        rarity = "UNCOMMON",
        amplifyStacks = 1,
        description = "Your next Power is played twice.",

        onPlay = function(self, world, player)
            player.status = player.status or {}
            player.status.amplify = (player.status.amplify or 0) + self.amplifyStacks
            table.insert(world.log, player.name .. "'s Amplify readied the " .. formatStackMessage(self.amplifyStacks) .. ".")
        end,

        onUpgrade = function(self)
            self.amplifyStacks = 2
            self.description = "Your next 2 Powers are played twice."
        end
    }
}

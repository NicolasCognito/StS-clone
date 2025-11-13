-- CHILL
-- Skill: Channel 1 Frost for each enemy in combat. Exhaust.
local Utils = require("utils")

return {
    Chill = {
        id = "Chill",
        name = "Chill",
        cost = 0,
        type = "SKILL",
        character = "DEFECT",
        rarity = "UNCOMMON",
        upgraded = false,
        exhausts = true,
        innate = false,
        description = "Channel 1 Frost for each enemy. Exhaust.",

        onPlay = function(self, world, player)
            local enemyCount = 0
            for _, enemy in ipairs(world.enemies) do
                if enemy.hp > 0 and not enemy.dead then
                    enemyCount = enemyCount + 1
                end
            end

            for i = 1, enemyCount do
                world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Frost"})
            end
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.innate = true
            self.description = "Innate. Channel 1 Frost for each enemy. Exhaust."
        end
    }
}

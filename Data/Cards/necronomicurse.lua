-- Necronomicurse (Curse)
-- Unplayable. There is no escape from this Curse.
-- When exhausted, immediately returns to hand (or discard pile if hand is full).
-- Can be played with Blue Candle (like other curses).

return {
    Necronomicurse = {
        id = "Necronomicurse",
        name = "Necronomicurse",
        cost = 0,
        type = "CURSE",
        character = "CURSE",
        rarity = "CURSE",
        exhausts = true,
        description = "Unplayable. There is no escape from this Curse.",

        -- Only playable with Blue Candle relic (like other curses)
        isPlayable = function(self, world, player)
            local Utils = require("utils")
            if Utils.hasRelic(player, "Blue_Candle") then
                return true
            end
            return false, "Necronomicurse is unplayable"
        end,

        -- When played (via Blue Candle): Lose 1 HP
        onPlay = function(self, world, player)
            world.queue:push({
                type = "ON_NON_ATTACK_DAMAGE",
                source = self,
                target = player,
                amount = 1,
                tags = {"ignoreBlock"}
            })
            table.insert(world.log, player.name .. " plays Necronomicurse, losing 1 HP")
        end

        -- NOTE: The return-to-hand logic when exhausted is handled by
        -- the Exhaust pipeline (Pipelines/Exhaust.lua), not here!
    }
}

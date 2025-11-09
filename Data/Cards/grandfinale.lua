return {
    GrandFinale = {
        id = "Grand_Finale",
        name = "Grand Finale",
        cost = 0,
        type = "ATTACK",
        damage = 50,
        description = "Can only be played if there are no cards in your draw pile. Deal 50 damage to ALL enemies.",

        -- Custom playability check: deck must be empty
        isPlayable = function(self, world, player)
            local Utils = require("utils")
            local deckCount = Utils.getCardCountByState(player.combatDeck, "DECK")

            if deckCount > 0 then
                return false, "Grand Finale can only be played when draw pile is empty"
            end

            return true
        end,

        -- No context provider - doesn't target specific enemy, hits ALL enemies
        contextProvider = nil,

        onPlay = function(self, world, player, context)
            -- Deal damage to ALL enemies
            if world.enemies then
                for _, enemy in ipairs(world.enemies) do
                    if enemy.hp > 0 then
                        world.queue:push({
                            type = "ON_DAMAGE",
                            attacker = player,
                            defender = enemy,
                            card = self
                        })
                    end
                end
            end
        end,

        onUpgrade = function(self)
            self.damage = 60
            self.description = "Can only be played if there are no cards in your draw pile. Deal 60 damage to ALL enemies."
        end
    }
}

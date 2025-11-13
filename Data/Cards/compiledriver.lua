-- COMPILE DRIVER
-- Attack: Deal 7 damage. Draw 1 card for each unique Orb you have.
local ContextValidators = require("Utils.ContextValidators")

return {
    CompileDriver = {
        id = "Compile_Driver",
        name = "Compile Driver",
        cost = 1,
        type = "ATTACK",
        character = "DEFECT",
        rarity = "UNCOMMON",
        damage = 7,
        upgraded = false,
        description = "Deal 7 damage. Draw 1 card for each unique Orb you have.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request target
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "enemy",
                    stability = "stable"
                }
            }, "FIRST")

            -- Deal damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Count unique orb types
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local uniqueOrbs = {}
                    for _, orb in ipairs(player.orbs) do
                        uniqueOrbs[orb.id] = true
                    end

                    local uniqueCount = 0
                    for _ in pairs(uniqueOrbs) do
                        uniqueCount = uniqueCount + 1
                    end

                    -- Draw cards
                    for i = 1, uniqueCount do
                        world.queue:push({type = "ON_DRAW"})
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.damage = 10
            self.description = "Deal 10 damage. Draw 1 card for each unique Orb you have."
        end
    }
}

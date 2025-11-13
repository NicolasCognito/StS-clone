local ContextValidators = require("Utils.ContextValidators")

return {
    FearNoEvil = {
        id = "FearNoEvil",
        name = "Fear No Evil",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "UNCOMMON",
        damage = 8,
        description = "Deal 8 damage. If the target intends to Attack, enter Calm.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event with lazy-evaluated defender
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Check if target intends to attack, then enter Calm
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local target = world.combat.stableContext
                    if target and target.currentIntent and target.currentIntent.intentType == "ATTACK" then
                        world.queue:push({
                            type = "CHANGE_STANCE",
                            newStance = "Calm"
                        })
                        table.insert(world.log, "Enemy intends to attack - entering Calm!")
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.damage = 11
            self.description = "Deal 11 damage. If the target intends to Attack, enter Calm."
            self.upgraded = true
        end
    }
}

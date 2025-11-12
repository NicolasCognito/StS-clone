local ContextValidators = require("Utils.ContextValidators")

return {
    PressurePoints = {
        id = "PressurePoints",
        name = "Pressure Points",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "COMMON",
        mark = 2,
        description = "Apply 2 Mark. All enemies lose HP equal to their Mark.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = function()
                    return world.combat.stableContext
                end,
                effectType = "Mark",
                amount = self.mark,
                source = self
            })

            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function(w)
                    if not w.enemies then
                        return
                    end

                    for _, enemy in ipairs(w.enemies) do
                        if enemy.hp > 0 and enemy.status and enemy.status.mark and enemy.status.mark > 0 then
                            w.queue:push({
                                type = "ON_NON_ATTACK_DAMAGE",
                                source = player,
                                target = enemy,
                                amount = enemy.status.mark,
                                tags = {"ignoreBlock"}
                            })
                        end
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.mark = 3
            self.description = "Apply 3 Mark. All enemies lose HP equal to their Mark."
        end
    }
}

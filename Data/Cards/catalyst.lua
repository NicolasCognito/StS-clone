local ContextValidators = require("Utils.ContextValidators")

return {
    Catalyst = {
        id = "Catalyst",
        name = "Catalyst",
        cost = 1,
        type = "SKILL",
        character = "SILENT",
        rarity = "UNCOMMON",
        poisonMultiplier = 2,
        description = "Double the target's Poison.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onPlay = function(self, world, player)
            -- Request context collection
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local target = world.combat.stableContext
                    if not target then
                        table.insert(world.log, "Catalyst had no target.")
                        return
                    end

                    if target.status and target.status.poison and target.status.poison > 0 then
                        local oldPoison = target.status.poison
                        local newPoison = oldPoison * (self.poisonMultiplier or 2)
                        target.status.poison = newPoison
                        table.insert(world.log, target.name .. "'s Poison increased from " .. oldPoison .. " to " .. newPoison)
                    else
                        table.insert(world.log, target.name .. " has no Poison to multiply")
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.poisonMultiplier = 3
            self.description = "Triple the target's Poison."
        end
    }
}

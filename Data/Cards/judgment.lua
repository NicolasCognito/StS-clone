return {
    Judgment = {
        id = "Judgment",
        name = "Judgment",
        cost = 1,
        type = "SKILL",
        character = "WATCHER",
        rarity = "RARE",
        hpThreshold = 30,
        description = "If the enemy has 30 or less HP, set their HP to 0.",
        upgraded = false,

        onPlay = function(self, world, player)
            -- Request context collection (target selection)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Use custom effect to check HP and execute judgment
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    local target = world.combat.stableContext
                    if not target then
                        table.insert(world.log, "Judgment had no target.")
                        return
                    end

                    -- Check if enemy HP is at or below threshold
                    if target.hp <= self.hpThreshold then
                        -- Set HP to 0 (instant kill)
                        local damageDealt = target.hp
                        target.hp = 0
                        table.insert(world.log, player.name .. " used Judgment! " .. target.name .. " is instantly defeated!")

                        -- Queue death event
                        world.queue:push({
                            type = "ON_DEATH",
                            entity = target,
                            source = player,
                            damage = damageDealt,
                            card = self
                        }, "FIRST")
                    else
                        table.insert(world.log, player.name .. " used Judgment, but " .. target.name .. " has more than " .. self.hpThreshold .. " HP.")
                    end
                end
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.name = "Judgment+"
            self.hpThreshold = 40
            self.description = "If the enemy has 40 or less HP, set their HP to 0."
        end
    }
}

local ContextValidators = require("Utils.ContextValidators")

return {
    EndlessAgony = {
        id = "EndlessAgony",
        name = "Endless Agony",
        cost = 0,
        type = "ATTACK",
        character = "SILENT",
        rarity = "UNCOMMON",
        damage = 4,
        exhausts = true,
        description = "Whenever you draw this card, add a copy of it into your hand. Deal 4 damage. Exhaust.",
        stableContextValidator = ContextValidators.specificEnemyAlive,

        onDraw = function(self, world, player)
            local AcquireCard = require("Pipelines.AcquireCard")

            table.insert(world.log, "Endless Agony splits into another copy!")

            -- Call AcquireCard directly rather than enqueueing; probably fine now but could misbehave if future draw hooks expect queued resolution
            AcquireCard.execute(world, player, self, {
                destination = "HAND"
            })
        end,

        onPlay = function(self, world, player)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 6
            self.description = "Whenever you draw this card, add a copy of it into your hand. Deal 6 damage. Exhaust."
        end
    }
}

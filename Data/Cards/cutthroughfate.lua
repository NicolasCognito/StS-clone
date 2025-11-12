return {
    CutThroughFate = {
        id = "CutThroughFate",
        name = "Cut Through Fate",
        cost = 1,
        type = "ATTACK",
        character = "SILENT",
        rarity = "UNCOMMON",
        damage = 7,
        scryAmount = 3,
        description = "Deal 7 damage. Scry 3.",

        onPlay = function(self, world, player)
            -- Request enemy context for damage
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Request scry context (show top 3 cards)
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {
                    type = "cards",
                    stability = "temp",
                    scry = self.scryAmount,
                    count = {min = 0, max = self.scryAmount}
                }
            })

            -- Process scry (move selected cards to discard)
            world.queue:push({
                type = "ON_SCRY"
            })
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.scryAmount = 5
            self.description = "Deal 10 damage. Scry 5."
        end
    }
}

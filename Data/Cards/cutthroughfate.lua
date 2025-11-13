return {
    CutThroughFate = {
        id = "CutThroughFate",
        name = "Cut Through Fate",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "COMMON",
        damage = 7,
        scryAmount = 2,
        cardsToDraw = 1,
        description = "Deal 7 damage. Scry 2. Draw 1 card.",

        onPlay = function(self, world, player)
            -- Request enemy context for damage
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Push damage event
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = function() return world.combat.stableContext end,
                card = self
            })

            -- Request scry context (show top 2 cards)
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

            -- Draw 1 card
            world.queue:push({
                type = "ON_DRAW",
                player = player,
                count = self.cardsToDraw
            })
        end,

        onUpgrade = function(self)
            self.damage = 9
            self.scryAmount = 3
            self.description = "Deal 9 damage. Scry 3. Draw 1 card."
        end
    }
}

local ContextValidators = require("Utils.ContextValidators")

return {
    Tantrum = {
        id = "Tantrum",
        name = "Tantrum",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Deal 3 damage 3 times. Enter Wrath. Shuffle this card into your draw pile.",
        damage = 3,
        hits = 3,
        shuffleOnDiscard = true,  -- Special flag: shuffle into draw pile when discarded

        onPlay = function(self, world, player)
            -- Request enemy context
            world.queue:push({
                type = "COLLECT_CONTEXT",
                card = self,
                contextProvider = {type = "enemy", stability = "stable"}
            }, "FIRST")

            -- Deal damage multiple times to the same target
            for i = 1, self.hits do
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = player,
                    defender = function() return world.combat.stableContext end,
                    card = self
                })
            end

            -- Enter Wrath stance
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Wrath"
            })
        end,

        onUpgrade = function(self)
            self.hits = 4
            self.description = "Deal 3 damage 4 times. Enter Wrath. Shuffle this card into your draw pile."
            self.upgraded = true
        end
    }
}

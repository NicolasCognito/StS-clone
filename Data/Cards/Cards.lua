-- CARDS DATA
-- Ironclad starting deck and basic cards
-- Each card contains data parameters and delta functions:
-- - onPlay: pushes event to queue when card is played
-- - onUpgrade: modifies card parameters for upgraded versions

local Cards = {
    Strike = {
        id = "Strike",
        name = "Strike",
        cost = 1,
        type = "ATTACK",
        damage = 6,
        Targeted = 1,
        description = "Deal 6 damage.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 8
            self.description = "Deal 8 damage."
        end
    },

    Defend = {
        id = "Defend",
        name = "Defend",
        cost = 1,
        type = "SKILL",
        block = 5,
        Targeted = 0,
        description = "Gain 5 block.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_BLOCK",
                target = player,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.block = 8
            self.description = "Gain 8 block."
        end
    },

    Bash = {
        id = "Bash",
        name = "Bash",
        cost = 1,
        type = "ATTACK",
        damage = 8,
        Targeted = 1,
        description = "Deal 8 damage. Apply 2 Vulnerable.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
            world.queue:push({
                type = "ON_STATUS_GAIN",
                target = target,
                effectType = "Vulnerable",
                amount = 2,
                source = self
            })
        end,

        onUpgrade = function(self)
            self.damage = 10
            self.description = "Deal 10 damage. Apply 2 Vulnerable."
        end
    },

    HeavyBlade = {
        id = "Heavy_Blade",
        name = "Heavy Blade",
        cost = 2,
        type = "ATTACK",
        damage = 14,
        strengthMultiplier = 3,
        Targeted = 1,
        description = "Deal 14 damage. Strength affects this card 3 times.",

        onPlay = function(self, world, player, target)
            world.queue:push({
                type = "ON_DAMAGE",
                attacker = player,
                defender = target,
                card = self
            })
        end,

        onUpgrade = function(self)
            self.strengthMultiplier = 5
            self.description = "Deal 14 damage. Strength affects this card 5 times."
        end
    }
}

return Cards

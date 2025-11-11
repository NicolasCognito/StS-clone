return {
    AcidSlime = {
        id = "AcidSlime",
        name = "Acid Slime (M)",
        hp = 28,
        maxHp = 28,
        block = 0,
        damage = 7,
        description = "A medium-sized acidic slime.",

        -- Intent functions
        intents = {
            tackle = function(self, world, player)
                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end,

            corrosiveSpit = function(self, world, player)
                -- Deal damage and apply Weak
                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
                world.queue:push({
                    type = "APPLY_STATUS_EFFECT",
                    target = player,
                    effect = "weak",
                    stacks = 1
                })
            end,

            prepare = function(self, world, player)
                -- Gain block (preparing for next turn)
                world.queue:push({
                    type = "APPLY_BLOCK",
                    target = self,
                    amount = 8
                })
            end
        },

        -- Selector function
        selectIntent = function(self, world, player)
            -- Slime AI: Cycles between attacks and occasionally prepares
            if not self.turnCount then
                self.turnCount = 0
            end
            self.turnCount = self.turnCount + 1

            -- Every 3rd turn, prepare
            if self.turnCount % 3 == 0 then
                self.currentIntent = {
                    name = "Prepare",
                    description = "Gain 8 block",
                    execute = self.intents.prepare
                }
            -- Use corrosive spit every other attack
            elseif self.turnCount % 2 == 0 then
                self.currentIntent = {
                    name = "Corrosive Spit",
                    description = "Deal " .. self.damage .. " damage and apply 1 Weak",
                    execute = self.intents.corrosiveSpit
                }
            else
                self.currentIntent = {
                    name = "Tackle",
                    description = "Deal " .. self.damage .. " damage",
                    execute = self.intents.tackle
                }
            end
        end,

        executeIntent = function(self, world, player)
            if self.currentIntent and self.currentIntent.execute then
                self.currentIntent.execute(self, world, player)
            else
                -- Fallback to simple attack
                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end
        end
    },

    SpikeSlime = {
        id = "SpikeSlime",
        name = "Spike Slime (S)",
        hp = 10,
        maxHp = 10,
        block = 0,
        damage = 5,
        description = "A small spiky slime.",

        -- Intent functions
        intents = {
            tackle = function(self, world, player)
                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end
        },

        -- Selector function - always attacks
        selectIntent = function(self, world, player)
            self.currentIntent = {
                name = "Tackle",
                description = "Deal " .. self.damage .. " damage",
                execute = self.intents.tackle
            }
        end,

        executeIntent = function(self, world, player)
            if self.currentIntent and self.currentIntent.execute then
                self.currentIntent.execute(self, world, player)
            else
                -- Fallback to simple attack
                world.queue:push({
                    type = "ON_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end
        end
    }
}

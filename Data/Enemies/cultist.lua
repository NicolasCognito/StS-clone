return {
    Cultist = {
        id = "Cultist",
        name = "Cultist",
        hp = 48,
        maxHp = 48,
        block = 0,
        damage = 6,
        description = "A dark cultist gathering power.",

        -- Intent functions
        intents = {
            ritual = function(self, world, player)
                -- Gain strength (using a power-like mechanic)
                if not self.ritualStacks then
                    self.ritualStacks = 0
                end
                self.ritualStacks = self.ritualStacks + 3
                self.damage = self.damage + 3

                table.insert(world.log, self.name .. " performs a ritual and gains 3 strength!")
            end,

            darkStrike = function(self, world, player)
                -- Attack with bonus damage from ritual stacks
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end
        },

        -- Selector function
        selectIntent = function(self, world, player)
            if not self.hasRitualed then
                -- First turn: always ritual
                self.hasRitualed = true
                self.currentIntent = {
                    name = "Ritual",
                    description = "Gain 3 Strength",
                    execute = self.intents.ritual
                }
            else
                -- After ritual: always attack
                self.currentIntent = {
                    name = "Dark Strike",
                    description = "Deal " .. self.damage .. " damage",
                    intentType = "ATTACK",
                    execute = self.intents.darkStrike
                }
            end
        end,

        executeIntent = function(self, world, player)
            if self.currentIntent and self.currentIntent.execute then
                self.currentIntent.execute(self, world, player)
            else
                -- Fallback to simple attack
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end
        end
    }
}

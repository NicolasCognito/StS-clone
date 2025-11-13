return {
    Goblin = {
        id = "Goblin",
        name = "Goblin",
        hp = 12,
        maxHp = 12,
        block = 0,
        damage = 5,
        description = "A basic goblin enemy.",

        -- Intent functions - each represents a possible action
        intents = {
            attack = function(self, world, player)
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self  -- enemy acts like a "card" for pipeline purposes
                })
            end,

            defend = function(self, world, player)
                world.queue:push({
                    type = "APPLY_BLOCK",
                    target = self,
                    amount = 5
                })
            end
        },

        -- Selector function - chooses which intent to use this turn
        selectIntent = function(self, world, player)
            -- Simple AI: 70% attack, 30% defend
            if math.random() < 0.7 then
                self.currentIntent = {
                    name = "Attack",
                    description = "Deal " .. self.damage .. " damage",
                    intentType = "ATTACK",
                    execute = self.intents.attack
                }
            else
                self.currentIntent = {
                    name = "Defend",
                    description = "Gain 5 block",
                    execute = self.intents.defend
                }
            end
        end,

        -- Execute the currently selected intent
        executeIntent = function(self, world, player)
            if self.currentIntent and self.currentIntent.execute then
                self.currentIntent.execute(self, world, player)
            else
                -- Fallback to simple attack if no intent selected
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

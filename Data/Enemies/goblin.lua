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
            -- Get last intent from history
            local lastIntent = self.intentHistory and #self.intentHistory > 0
                and self.intentHistory[#self.intentHistory] or nil

            -- AI: 70% attack, 30% defend
            -- But avoid repeating the same move twice in a row (StS-like behavior)
            local chosenIntent

            if math.random() < 0.7 then
                chosenIntent = "Attack"
            else
                chosenIntent = "Defend"
            end

            -- If we'd repeat the last move, switch to the other one
            if lastIntent and lastIntent == chosenIntent then
                chosenIntent = (chosenIntent == "Attack") and "Defend" or "Attack"
            end

            -- Set the intent based on choice
            if chosenIntent == "Attack" then
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

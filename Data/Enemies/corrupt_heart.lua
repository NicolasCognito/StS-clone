return {
    CorruptHeart = {
        id = "CorruptHeart",
        name = "Corrupt Heart",
        hp = 750,
        maxHp = 750,
        block = 0,
        damage = 12,  -- Base damage for Blood Shots
        description = "The final boss. Invincible protects it from burst damage.",

        -- Intent functions
        intents = {
            debilitate = function(self, world, player)
                -- Apply 2 Vulnerable, 2 Weak, 2 Frail
                world.queue:push({
                    type = "APPLY_STATUS_EFFECT",
                    target = player,
                    effectType = "vulnerable",
                    stacks = 2
                })
                world.queue:push({
                    type = "APPLY_STATUS_EFFECT",
                    target = player,
                    effectType = "weak",
                    stacks = 2
                })
                world.queue:push({
                    type = "APPLY_STATUS_EFFECT",
                    target = player,
                    effectType = "frail",
                    stacks = 2
                })

                -- TODO: Implement Dazed, Slimed, Burn, Void status cards
                -- For now, shuffle 5 Wounds into the deck as proxy
                local Cards = require("Data.cards")
                local AcquireCard = require("Pipelines.AcquireCard")

                if Cards.Wound then
                    for i = 1, 5 do
                        AcquireCard.execute(world, player, Cards.Wound, {
                            destination = "DISCARD_PILE",
                            targetDeck = "combat"
                        })
                    end
                    table.insert(world.log, "Debilitate: 5 Wounds shuffled into deck")
                end
            end,

            blood_shots = function(self, world, player)
                -- Deal 2x12 damage (two separate hits)
                for i = 1, 2 do
                    world.queue:push({
                        type = "ON_ATTACK_DAMAGE",
                        attacker = self,
                        defender = player,
                        card = self
                    })
                end
            end,

            echo = function(self, world, player)
                -- Deal 40 damage (single hit)
                local echoDamage = 40
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = {damage = echoDamage, strengthMultiplier = 1}
                })
            end,

            buff = function(self, world, player)
                -- Remove all Strength Down (negative strength)
                if self.status.strength and self.status.strength < 0 then
                    self.status.strength = 0
                    table.insert(world.log, self.name .. " removed all Strength Down")
                end

                -- Gain +2 Strength baseline
                world.queue:push({
                    type = "APPLY_STATUS_EFFECT",
                    target = self,
                    effectType = "strength",
                    stacks = 2
                })

                -- Increment buff count
                self.buffCount = (self.buffCount or 0) + 1

                -- Apply buff-specific effects
                if self.buffCount == 1 then
                    -- 1st Buff: Artifact +2
                    world.queue:push({
                        type = "APPLY_STATUS_EFFECT",
                        target = self,
                        effectType = "artifact",
                        stacks = 2
                    })
                    table.insert(world.log, "Buff 1: Gained Artifact")

                elseif self.buffCount == 2 then
                    -- 2nd Buff: Beat of Death 1
                    world.queue:push({
                        type = "APPLY_STATUS_EFFECT",
                        target = self,
                        effectType = "beat_of_death",
                        stacks = 1
                    })
                    table.insert(world.log, "Buff 2: Beat of Death activated")

                elseif self.buffCount == 3 then
                    -- 3rd Buff: Painful Stabs
                    world.queue:push({
                        type = "APPLY_STATUS_EFFECT",
                        target = self,
                        effectType = "painful_stabs",
                        stacks = 1
                    })
                    table.insert(world.log, "Buff 3: Painful Stabs activated")

                elseif self.buffCount == 4 then
                    -- 4th Buff: +10 Strength (in addition to +2 baseline)
                    world.queue:push({
                        type = "APPLY_STATUS_EFFECT",
                        target = self,
                        effectType = "strength",
                        stacks = 10
                    })
                    table.insert(world.log, "Buff 4: Massive Strength gain (+10)")

                else
                    -- 5th+ Buff: +50 Strength (in addition to +2 baseline)
                    world.queue:push({
                        type = "APPLY_STATUS_EFFECT",
                        target = self,
                        effectType = "strength",
                        stacks = 50
                    })
                    table.insert(world.log, "Buff " .. self.buffCount .. ": Overwhelming Strength gain (+50)")
                end
            end
        },

        -- Selector function: Choose next intent
        selectIntent = function(self, world, player)
            -- Initialize status on first call (combat start)
            if not self.initialized then
                self.initialized = true
                self.status = self.status or {}
                -- Invincible: Cap damage to 300 per turn
                self.status.invincible_max = 300
                self.status.invincible = 300
                -- Track buff count for escalating buffs
                self.buffCount = 0
                -- Track attack pattern (for Blood Shots/Echo alternation)
                self.nextAttack = "blood_shots"
            end

            -- Initialize turn counter
            if not self.turnCount then
                self.turnCount = 0
            end
            self.turnCount = self.turnCount + 1

            -- Turn 1: Always Debilitate
            if self.turnCount == 1 then
                self.currentIntent = {
                    name = "Debilitate",
                    description = "Apply 2 Vulnerable, Weak, Frail. Shuffle 5 status cards.",
                    execute = self.intents.debilitate
                }
                return
            end

            -- Every 3rd turn starting from turn 4 (turns 4, 7, 10, ...): Buff
            -- Turn 4 = turnCount 4, turn 7 = turnCount 7, etc.
            if self.turnCount >= 4 and (self.turnCount - 1) % 3 == 0 then
                self.currentIntent = {
                    name = "Buff",
                    description = "Gain Strength and special buffs",
                    execute = self.intents.buff
                }
                return
            end

            -- Otherwise: Alternate between Blood Shots and Echo
            -- Initialize pattern tracker if not set
            if not self.nextAttack then
                self.nextAttack = "blood_shots"
            end

            if self.nextAttack == "blood_shots" then
                self.currentIntent = {
                    name = "Blood Shots",
                    description = "Deal " .. (self.damage * 2) .. " damage (2x" .. self.damage .. ")",
                    intentType = "ATTACK",
                    execute = self.intents.blood_shots
                }
                self.nextAttack = "echo"
            else
                self.currentIntent = {
                    name = "Echo",
                    description = "Deal 40 damage",
                    intentType = "ATTACK",
                    execute = self.intents.echo
                }
                self.nextAttack = "blood_shots"
            end
        end,

        executeIntent = function(self, world, player)
            if self.currentIntent and self.currentIntent.execute then
                self.currentIntent.execute(self, world, player)
            end
        end
    }
}

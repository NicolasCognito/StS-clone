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
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end,

            corrosiveSpit = function(self, world, player)
                -- Deal damage and apply Weak
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
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
                    type = "ON_ATTACK_DAMAGE",
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
                    type = "ON_ATTACK_DAMAGE",
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
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end
        end
    },

    SlimeBoss = {
        id = "SlimeBoss",
        name = "Slime Boss",
        hp = 60,
        maxHp = 60,
        block = 0,
        damage = 12,
        description = "A powerful slime that splits when damaged.",

        -- Intent functions
        intents = {
            slam = function(self, world, player)
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self
                })
            end,

            prepare = function(self, world, player)
                world.queue:push({
                    type = "APPLY_BLOCK",
                    target = self,
                    amount = 15
                })
            end,

            split = function(self, world, player)
                -- Spawn 2 SpikeSlimes
                local Utils = require("utils")
                local Enemies = require("Data.Enemies.slime")
                for i = 1, 2 do
                    local newSlime = Utils.copyEnemyTemplate(Enemies.SpikeSlime)
                    table.insert(world.enemies, newSlime)
                end

                -- Remove boss from enemies array
                for i, enemy in ipairs(world.enemies) do
                    if enemy == self then
                        table.remove(world.enemies, i)
                        break
                    end
                end

                table.insert(world.log, self.name .. " splits into 2 slimes!")
            end
        },

        -- Called when taking damage - checks if should change intent to split
        ChangeIntentOnDamage = function(self, world, source)
            -- Split if HP drops to half or below
            if self.hp <= self.maxHp / 2 and not self.hasSplit then
                self.hasSplit = true
                self.currentIntent = {
                    name = "Split",
                    description = "Split into 2 slimes",
                    execute = self.intents.split
                }
                -- Execute split immediately on next turn
            end
        end,

        -- Selector function
        selectIntent = function(self, world, player)
            -- If already marked to split, keep the split intent
            if self.hasSplit then
                return
            end

            -- Simple AI: alternates between slam and prepare
            if not self.turnCount then
                self.turnCount = 0
            end
            self.turnCount = self.turnCount + 1

            if self.turnCount % 2 == 0 then
                self.currentIntent = {
                    name = "Prepare",
                    description = "Gain 15 block",
                    execute = self.intents.prepare
                }
            else
                self.currentIntent = {
                    name = "Slam",
                    description = "Deal " .. self.damage .. " damage",
                    execute = self.intents.slam
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

-- DARKLING ENEMIES
-- Act 3 enemy encounter with revival mechanic (Life Link)
-- When a Darkling dies, it enters a revival state for 2 turns
-- If other Darklings are alive at the end of the countdown, it revives with half HP

return {
    Darkling = {
        id = "Darkling",
        name = "Darkling",
        hp = 48,  -- Will be randomized to 48-56 in combat setup
        maxHp = 48,
        block = 0,
        damage = 8,  -- Base damage for Nip (will be randomized to 7-11)
        chompDamage = 8,  -- Base damage for Chomp (8x2)
        description = "A dark creature that can revive when allies are present.",

        -- CRITICAL: Enables revival mechanic
        reviveType = "darkling",

        -- Position in the encounter (left, middle, right)
        -- Middle Darkling has different move pattern (never uses Chomp)
        position = "middle",  -- Will be overridden when creating the encounter

        -- Intent functions
        intents = {
            nip = function(self, world, player)
                world.queue:push({
                    type = "ON_ATTACK_DAMAGE",
                    attacker = self,
                    defender = player,
                    card = self,
                    damage = self.damage  -- Use Darkling's random D value
                })
            end,

            chomp = function(self, world, player)
                -- Multi-hit attack (2 hits)
                for i = 1, 2 do
                    world.queue:push({
                        type = "ON_ATTACK_DAMAGE",
                        attacker = self,
                        defender = player,
                        card = self,
                        damage = self.chompDamage
                    })
                end
            end,

            harden = function(self, world, player)
                world.queue:push({
                    type = "ON_BLOCK",
                    target = self,
                    amount = 12
                })
                -- TODO: On Ascension 17+, also gain 2 Strength
            end
        },

        -- AI selector function
        selectIntent = function(self, world, player)
            -- Initialize intent history if needed
            if not self.intentHistory then
                self.intentHistory = {}
            end

            -- First turn: 50% Nip, 50% Harden
            if #self.intentHistory == 0 then
                if math.random() < 0.5 then
                    self.currentIntent = {
                        name = "Nip",
                        description = "Deal " .. self.damage .. " damage",
                        intentType = "ATTACK",
                        execute = self.intents.nip
                    }
                else
                    self.currentIntent = {
                        name = "Harden",
                        description = "Gain 12 Block",
                        intentType = "DEFEND",
                        execute = self.intents.harden
                    }
                end
                return
            end

            -- Get last 2 moves for pattern checking
            local lastMove = self.intentHistory[#self.intentHistory]
            local secondLastMove = #self.intentHistory >= 2 and self.intentHistory[#self.intentHistory - 1] or nil

            -- Middle Darkling: 50% Nip, 50% Harden (never Chomp)
            if self.position == "middle" then
                if math.random() < 0.5 then
                    self.currentIntent = {
                        name = "Nip",
                        description = "Deal " .. self.damage .. " damage",
                        intentType = "ATTACK",
                        execute = self.intents.nip
                    }
                else
                    self.currentIntent = {
                        name = "Harden",
                        description = "Gain 12 Block",
                        intentType = "DEFEND",
                        execute = self.intents.harden
                    }
                end
                return
            end

            -- Outer Darklings (left/right): 30% Nip, 40% Chomp, 30% Harden
            -- With move restrictions
            local validMoves = {}

            -- Check Nip (cannot be used 3 times in a row)
            if not (lastMove == "Nip" and secondLastMove == "Nip") then
                validMoves.nip = 30
            end

            -- Check Chomp (cannot be used twice in a row)
            if lastMove ~= "Chomp" then
                validMoves.chomp = 40
            end

            -- Check Harden (cannot be used twice in a row)
            if lastMove ~= "Harden" then
                validMoves.harden = 30
            end

            -- Calculate total weight and select move
            local totalWeight = 0
            for _, weight in pairs(validMoves) do
                totalWeight = totalWeight + weight
            end

            local roll = math.random() * totalWeight
            local cumulative = 0

            for move, weight in pairs(validMoves) do
                cumulative = cumulative + weight
                if roll <= cumulative then
                    if move == "nip" then
                        self.currentIntent = {
                            name = "Nip",
                            description = "Deal " .. self.damage .. " damage",
                            intentType = "ATTACK",
                            execute = self.intents.nip
                        }
                    elseif move == "chomp" then
                        self.currentIntent = {
                            name = "Chomp",
                            description = "Deal " .. self.chompDamage .. " damage 2 times",
                            intentType = "ATTACK",
                            execute = self.intents.chomp
                        }
                    elseif move == "harden" then
                        self.currentIntent = {
                            name = "Harden",
                            description = "Gain 12 Block",
                            intentType = "DEFEND",
                            execute = self.intents.harden
                        }
                    end
                    return
                end
            end

            -- Fallback (should never happen)
            self.currentIntent = {
                name = "Nip",
                description = "Deal " .. self.damage .. " damage",
                intentType = "ATTACK",
                execute = self.intents.nip
            }
        end,

        executeIntent = function(self, world, player)
            if self.currentIntent and self.currentIntent.execute then
                self.currentIntent.execute(self, world, player)
            end
        end
    }
}

return {
    Tantrum = {
        id = "Tantrum",
        name = "Tantrum",
        cost = 1,
        type = "ATTACK",
        character = "WATCHER",
        rarity = "UNCOMMON",
        description = "Deal 3 damage to a random enemy 3 times. Enter Wrath. Shuffle this card into your draw pile.",
        damage = 3,
        hits = 3,

        onPlay = function(self, world, player)
            local Utils = require("utils")

            -- Deal damage multiple times to random enemies
            for i = 1, self.hits do
                world.queue:push({
                    type = "ON_CUSTOM_EFFECT",
                    effect = function()
                        -- Get all living enemies
                        local livingEnemies = {}
                        for _, enemy in ipairs(world.enemies) do
                            if not enemy.dead then
                                table.insert(livingEnemies, enemy)
                            end
                        end

                        -- Pick a random enemy
                        if #livingEnemies > 0 then
                            local randomEnemy = livingEnemies[math.random(1, #livingEnemies)]
                            world.queue:push({
                                type = "ON_ATTACK_DAMAGE",
                                attacker = player,
                                defender = randomEnemy,
                                card = self
                            })
                        end
                    end
                })
            end

            -- Enter Wrath stance
            world.queue:push({
                type = "CHANGE_STANCE",
                newStance = "Wrath"
            })

            -- Shuffle this card back into draw pile
            world.queue:push({
                type = "ON_CUSTOM_EFFECT",
                effect = function()
                    -- Card should be in discard pile at this point
                    -- Move it to the draw pile
                    self.state = "DECK"

                    -- Shuffle the draw pile
                    if not world.NoShuffle then
                        Utils.shuffleDeck(player.combatDeck, world)
                    end

                    table.insert(world.log, "Tantrum was shuffled into the draw pile")
                end
            })
        end,

        onUpgrade = function(self)
            self.hits = 4
            self.description = "Deal 3 damage to a random enemy 4 times. Enter Wrath. Shuffle this card into your draw pile."
            self.upgraded = true
        end
    }
}

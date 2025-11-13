-- DOOM AND GLOOM
-- Attack: Deal 10 damage to all enemies. Channel 1 Dark.
return {
    DoomAndGloom = {
        id = "Doom_and_Gloom",
        name = "Doom and Gloom",
        cost = 2,
        type = "ATTACK",
        character = "DEFECT",
        rarity = "UNCOMMON",
        damage = 10,
        upgraded = false,
        description = "Deal 10 damage to all enemies. Channel 1 Dark.",

        onPlay = function(self, world, player)
            -- Deal AOE damage
            world.queue:push({
                type = "ON_ATTACK_DAMAGE",
                attacker = player,
                defender = "all",
                card = self
            })

            -- Channel Dark
            world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Dark"})
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.damage = 14
            self.description = "Deal 14 damage to all enemies. Channel 1 Dark."
        end
    }
}

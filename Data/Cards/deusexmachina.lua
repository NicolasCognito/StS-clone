-- DEUS EX MACHINA
-- Watcher Rare Skill
-- Unplayable. When drawn: Add 2 (3) Miracles to hand. Exhaust.

return {
    DeusExMachina = {
        id = "DeusExMachina",
        name = "Deus Ex Machina",
        cost = 0,
        type = "SKILL",
        character = "WATCHER",
        rarity = "RARE",
        upgraded = false,
        description = "Unplayable. When drawn: Add 2 Miracles to hand. Exhaust.",

        isPlayable = function(self, world, player)
            return false, "Deus Ex Machina is unplayable"
        end,

        onDraw = function(self, world, player)
            local AcquireCard = require("Pipelines.AcquireCard")
            local Cards = require("Data.cards")
            local count = self.upgraded and 3 or 2

            table.insert(world.log, "Deus Ex Machina triggers! Adding " .. count .. " Miracles to hand")

            -- Add Miracles to hand
            AcquireCard.execute(world, player, Cards.Miracle, {
                destination = "HAND",
                count = count
            })

            -- Exhaust Deus Ex Machina
            world.queue:push({
                type = "ON_EXHAUST",
                card = self
            })
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.description = "Unplayable. When drawn: Add 3 Miracles to hand. Exhaust."
        end
    }
}

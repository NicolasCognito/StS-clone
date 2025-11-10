-- VAULT (Watcher - Rare Skill)
-- End your turn. Skip enemies' turn. Start a new turn.
--
-- This card has complex interactions with various buffs/debuffs:
--
-- When Vault is played:
-- 1. Player's turn ends normally (EndTurn pipeline executes)
--    - Player's "End of Turn" effects trigger (if any exist)
--    - Hand is discarded (unless Retained)
--
-- 2. Enemies' turns are SKIPPED entirely
--    - Enemy block does NOT reset to 0
--    - Enemy intents do NOT execute
--    - Enemy "End of Turn" effects do NOT trigger
--
-- 3. End of Round phase is SKIPPED
--    - Status effects (vulnerable, weak, frail, blur, intangible) do NOT tick down
--    - This applies to both player AND enemies
--
-- 4. New player turn starts (StartTurn pipeline executes)
--    - Player block resets to 0 (unless Blur)
--    - Draw new hand
--
-- See PROJECT_MAP.md for details on turn flow and status effect timing.

return {
    Vault = {
        id = "Vault",
        name = "Vault",
        cost = 2,
        type = "SKILL",
        rarity = "RARE",
        character = "WATCHER",
        description = "End your turn. Skip enemies' turn. Start a new turn.",
        upgraded = false,

        onPlay = function(self, world, player, target)
            -- Set flag to trigger special turn-skipping logic in CombatEngine
            world.combat.vaultPlayed = true
            table.insert(world.log, "Vault! Skipping enemies' turn...")
        end,

        onUpgrade = function(self)
            self.upgraded = true
            self.name = "Vault+"
            self.cost = 1
            self.description = "End your turn. Skip enemies' turn. Start a new turn. (Costs 1)"
        end
    }
}

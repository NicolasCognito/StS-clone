-- END TURN PIPELINE
-- world: the complete game state
-- player: the player whose turn is ending
--
-- Handles:
-- - Apply end-of-turn effects (Poison damage, debuff decay, etc.)
-- - Discard remaining hand
-- - Prepare for enemy turn
-- - Process effect queue

local EndTurn = {}

function EndTurn.execute(world, player)
    -- TODO: implement
end

return EndTurn

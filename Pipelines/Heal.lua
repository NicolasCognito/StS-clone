-- HEAL PIPELINE
-- world: the complete game state
-- target: character being healed
-- amount: healing amount
--
-- Handles:
-- - Adding HP to character
-- - Capping at max HP
-- - Pushes ON_HEAL event to queue

local Heal = {}

function Heal.execute(world, target, amount)
    -- TODO: implement
end

return Heal

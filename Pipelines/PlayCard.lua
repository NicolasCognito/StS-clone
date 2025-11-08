-- PLAY CARD PIPELINE
-- world: the complete game state
-- player: the player character
-- card: the card from hand to play
-- target: target of the card (can be null for some cards)
--
-- Handles:
-- - Pay energy cost
-- - Resolve card effects (calls appropriate pipelines)
-- - Discard or exhaust the card
-- - Combat logging

local PlayCard = {}

function PlayCard.execute(world, player, card, target)
    -- TODO: implement
end

return PlayCard

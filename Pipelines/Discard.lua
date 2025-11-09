-- DISCARD PIPELINE
-- Handles discarding cards from hand to discard pile
--
-- Event should have:
-- - card: the card to discard (must be in hand)
-- - player: the player discarding the card
--
-- Handles:
-- - Moving card from HAND to DISCARD_PILE
-- - Combat logging
-- - Future: Discard-triggered effects (e.g., Eviscerate, Tingsha, Tough Bandages)

local Discard = {}

function Discard.execute(world, event)
    local card = event.card
    local player = event.player

    -- Validate card is in hand
    if card.state ~= "HAND" then
        table.insert(world.log, "Cannot discard " .. card.name .. " - not in hand")
        return
    end

    -- Move card to discard pile
    card.state = "DISCARD_PILE"
    table.insert(world.log, player.id .. " discarded " .. card.name)

    -- TODO: Trigger discard effects (Eviscerate, Tingsha, Tough Bandages, etc.)
end

return Discard

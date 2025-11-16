-- MAP UPGRADE CARD PIPELINE
-- Delegates to the shared UpgradeCard pipeline so special cards (Searing Blow)
-- can bypass one-and-done restrictions without duplicating logic.

local Map_UpgradeCard = {}
local UpgradeCard = require("Pipelines.UpgradeCard")

function Map_UpgradeCard.execute(world, event)
    if not world or not world.player or not world.player.masterDeck then
        return false
    end

    local card = event and event.card
    if type(card) == "function" then
        card = card(world)
    end

    if not card then
        return false
    end

    local success = UpgradeCard.execute(world, card, {source = "Smith"})

    if success and world.log then
        -- Already logged inside UpgradeCard, no need for extra entry
    elseif success then
        print("Upgraded " .. (card.name or card.id or "card"))
    end

    return success
end

return Map_UpgradeCard

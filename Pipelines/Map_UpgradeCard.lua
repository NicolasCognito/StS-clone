-- MAP UPGRADE CARD PIPELINE
-- Upgrades a card in the master deck, mirroring Smith actions.

local Map_UpgradeCard = {}

local function upgradeCard(card)
    if not card then
        return false
    end

    if card.upgraded then
        return false
    end

    if type(card.onUpgrade) == "function" then
        card:onUpgrade()
    end

    card.upgraded = true
    return true
end

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

    local success = upgradeCard(card)

    if success and world.log then
        table.insert(world.log, "Upgraded " .. (card.name or card.id or "card"))
    elseif success then
        print("Upgraded " .. (card.name or card.id or "card"))
    end

    return success
end

return Map_UpgradeCard

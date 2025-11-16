-- UPGRADE CARD PIPELINE
-- Centralizes upgrade logic so cards with special behavior (like Searing Blow)
-- can bypass the normal "one upgrade only" rule without sprinkling conditionals.
--
-- Exposed helpers:
--   UpgradeCard.canUpgrade(card) -> boolean
--   UpgradeCard.execute(world, card, options) -> boolean (success)
--
-- Cards may set `allowMultipleUpgrades = true` to opt into unlimited upgrades.
-- Searing Blow is also handled by ID for convenience once it is implemented.
-- TODO: This upgrade flow is HORRIBLY implemented; needs manual review/rewrite.

local UpgradeCard = {}

local unlimitedIds = {
    SearingBlow = true,
    Searing_Blow = true
}

local function allowsMultiple(card)
    if not card then
        return false
    end
    if card.allowMultipleUpgrades then
        return true
    end
    if card.id and unlimitedIds[card.id] then
        return true
    end
    return false
end

function UpgradeCard.canUpgrade(card)
    if not card or type(card.onUpgrade) ~= "function" then
        return false
    end

    if allowsMultiple(card) then
        return true
    end

    return not card.upgraded
end

function UpgradeCard.execute(world, card, options)
    if not UpgradeCard.canUpgrade(card) then
        return false
    end

    local upgradeCount
    if card.trackUpgradeCount then
        card.numberOfUpgrades = (card.numberOfUpgrades or 0) + 1
        upgradeCount = card.numberOfUpgrades
    end

    card:onUpgrade(upgradeCount)
    card.upgraded = true

    if world and world.log then
        local source = options and options.source
        local name = card.name or card.id or "card"
        if source then
            table.insert(world.log, string.format("%s upgraded %s.", source, name))
        else
            table.insert(world.log, "Upgraded " .. name)
        end
    end

    return true
end

return UpgradeCard

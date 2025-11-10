-- MAP REMOVE CARD PIPELINE
-- Removes cards from the master's deck outside combat.

local Map_RemoveCard = {}

local function matchCard(card, target)
    if not card or not target then
        return false
    end
    if card == target then
        return true
    end
    if type(target) == "table" and target.id and card.id == target.id then
        return true
    end
    if type(target) == "string" and card.id == target then
        return true
    end
    return false
end

local function removeByPredicate(deck, predicate, count)
    local removed = {}
    local i = 1

    while i <= #deck and #removed < count do
        if predicate(deck[i]) then
            table.insert(removed, table.remove(deck, i))
        else
            i = i + 1
        end
    end

    return removed
end

function Map_RemoveCard.execute(world, event)
    if not world or not world.player or not world.player.masterDeck then
        return {}
    end

    if not event then
        return {}
    end

    local deck = world.player.masterDeck
    local removed = {}
    local count = (event and event.count) or 1

    if event.card == nil and (not event.cards or #event.cards == 0) and not event.filter then
        return {}
    end

    if event.card then
        removed = removeByPredicate(deck, function(card)
            return matchCard(card, event.card)
        end, count)
    elseif event.cards and #event.cards > 0 then
        for _, target in ipairs(event.cards) do
            local res = removeByPredicate(deck, function(card)
                return matchCard(card, target)
            end, 1)
            for _, card in ipairs(res) do
                table.insert(removed, card)
            end
        end
    elseif event.filter then
        removed = removeByPredicate(deck, event.filter, count)
    end

    if world.log and #removed > 0 then
        for _, card in ipairs(removed) do
            table.insert(world.log, "Removed " .. (card.name or card.id or "card") .. " from deck")
        end
    end

    return removed
end

return Map_RemoveCard

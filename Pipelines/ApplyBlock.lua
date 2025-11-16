-- APPLY BLOCK PIPELINE
-- Processes ON_BLOCK events from the queue
--
-- Event should have:
-- - target: character gaining block
-- - card: the card/source with block value
--
-- Handles:
-- - Adding block to character
-- - Combat logging

local ApplyBlock = {}

function ApplyBlock.execute(world, event)
    local target = event.target
    local card = event.card
    local source = event.source or card

    local amount = event.amount or (card and card.block) or 0
    target.status = target.status or {}

    local displayName = target.name or target.id or "Target"
    local sourceName = "unknown source"

    if type(source) == "table" then
        sourceName = source.name or source.id or sourceName
    elseif type(source) == "string" then
        sourceName = source
    end

    if target.status.no_block and target.status.no_block > 0 then
        table.insert(world.log, displayName .. " cannot gain block from " .. sourceName)
        return
    end

    local dexterity = target.status.dexterity or 0
    amount = amount + dexterity

    if target.status.frail and target.status.frail > 0 then
        amount = math.floor(amount * 0.75)
    end

    amount = math.max(0, amount)

    if amount <= 0 then
        table.insert(world.log, displayName .. " gained no block from " .. sourceName)
        return
    end

    target.block = target.block + amount

    table.insert(world.log, displayName .. " gained " .. amount .. " block from " .. sourceName)
end

return ApplyBlock

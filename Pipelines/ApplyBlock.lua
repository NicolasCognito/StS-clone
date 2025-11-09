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

    local amount = card.block or 0

    target.block = target.block + amount

    -- Apply caps to target (HP, block, status effects)
    world.queue:push({
        type = "ON_APPLY_CAPS",
        character = target
    })

    table.insert(world.log, target.name .. " gained " .. amount .. " block")
end

return ApplyBlock

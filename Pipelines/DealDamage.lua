-- DEAL DAMAGE PIPELINE
-- Processes ON_DAMAGE events from the queue
--
-- Event should have:
-- - attacker: character dealing damage
-- - defender: character taking damage OR "all" for all enemies
-- - card: the card/source with damage value and scaling flags
-- - damage: optional damage value (if not present, uses card.damage)
-- - tags: optional array of tags (e.g., ["ignoreBlock"])
--
-- Handles:
-- - Base damage from event.damage (if present) or card.damage
-- - Attacker's Strength multiplier (when added)
-- - Defender's Vulnerable/Weak modifiers (when added)
-- - Block absorption (unless "ignoreBlock" tag is present)
-- - HP reduction
-- - Combat logging
-- - AOE damage (defender = "all")

local DealDamage = {}

local Utils = require("utils")

function DealDamage.execute(world, event)
    local attacker = event.attacker
    local defender = event.defender
    local card = event.card
    local tags = event.tags or {}

    -- Handle AOE: defender = "all" means hit all enemies
    if defender == "all" then
        -- Add "aoe" tag so relics/powers can detect AOE attacks (e.g., Pen Nib)
        local aoeTags = {}
        for _, tag in ipairs(tags) do
            table.insert(aoeTags, tag)
        end
        table.insert(aoeTags, "aoe")

        if world.enemies then
            for _, enemy in ipairs(world.enemies) do
                if enemy.hp > 0 then
                    -- Call with aoe tag added
                    DealDamage.executeSingle(world, attacker, enemy, card, aoeTags, event.damage)
                end
            end
        end
        return
    end

    -- Single target damage
    DealDamage.executeSingle(world, attacker, defender, card, tags, event.damage)
end

-- Execute damage against a single target
function DealDamage.executeSingle(world, attacker, defender, card, tags, eventDamage)
    -- Start with base damage (use event damage if provided, otherwise use card.damage)
    local damage = eventDamage or card.damage or 0

    -- Apply strength multiplier if card has it and attacker has strength
    if card.strengthMultiplier and attacker.strength then
        damage = damage + (attacker.strength * card.strengthMultiplier)
    end

    -- Apply Vulnerable: 50% more damage (75% with Paper Phrog, rounded down)
    if defender.status and defender.status.vulnerable and defender.status.vulnerable > 0 then
        local vulnerableMultiplier = 1.5  -- default 50%

        -- Check if attacker has Paper Phrog relic
        local paperPhrog = Utils.getRelic(attacker, "Paper_Phrog")
        if paperPhrog then
            vulnerableMultiplier = paperPhrog.vulnerableMultiplier
        end

        damage = math.floor(damage * vulnerableMultiplier)
    end

    -- Apply Pen Nib: Double damage on 10th attack
    local penNib = Utils.getRelic(attacker, "Pen_Nib")
    if penNib and world.penNibCounter >= penNib.triggerCount then
        damage = damage * penNib.damageMultiplier
        table.insert(world.log, "Pen Nib activated! (x" .. penNib.damageMultiplier .. " damage)")
    end

    -- Apply Intangible: Reduce damage to 1 if defender has Intangible status
    if defender.status and defender.status.intangible and defender.status.intangible > 0 then
        damage = 1
    end

    -- Apply The Boot: If damage is 4 or less, increase it to 5
    -- This is applied AFTER Intangible so The Boot bypasses Intangible damage reduction
    -- (matching Slay the Spire behavior)
    if damage <= 4 and Utils.hasRelic(attacker, "The_Boot") then
        damage = 5
    end

    local blockAbsorbed = 0

    -- Check if this damage ignores block
    if not Utils.hasTag(tags, "ignoreBlock") then
        -- Apply block absorption
        blockAbsorbed = math.min(defender.block, damage)
        defender.block = defender.block - blockAbsorbed
        damage = damage - blockAbsorbed
    end

    -- Apply remaining damage to HP
    defender.hp = defender.hp - damage

    -- Track HP loss for Blood for Blood (only if player lost HP)
    if defender == world.player and damage > 0 then
        world.combat.timesHpLost = world.combat.timesHpLost + 1
    end

    -- Log
    local logMsg = attacker.name .. " dealt " .. damage .. " damage to " .. defender.name
    if blockAbsorbed > 0 then
        logMsg = logMsg .. " (blocked " .. blockAbsorbed .. ")"
    end
    table.insert(world.log, logMsg)

    -- Queue death event if defender died (FIFO - added to front of queue)
    if defender.hp <= 0 then
        -- Build tags for death event
        local deathTags = {}
        if card and card.feedEffect then
            table.insert(deathTags, "feed")
        end

        world.queue:push({
            type = "ON_DEATH",
            entity = defender,
            source = attacker,
            damage = damage + blockAbsorbed,
            card = card,
            tags = deathTags
        }, "FIRST")
    end

    -- Trigger Thorns counter-damage (if defender has Thorns status)
    -- Thorns triggers on any attack, even if fully blocked
    -- Thorns damage can be blocked (use ignoreBlock tag for HP loss effects like Bloodletting)
    if defender.status and defender.status.thorns and defender.status.thorns > 0 then
        world.queue:push({
            type = "ON_NON_ATTACK_DAMAGE",
            source = defender,
            target = attacker,
            amount = defender.status.thorns
            -- No tags - Thorns respects block
        })
    end
end

return DealDamage

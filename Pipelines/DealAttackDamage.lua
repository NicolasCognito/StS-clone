-- DEAL DAMAGE PIPELINE
-- Processes ON_ATTACK_DAMAGE events from the queue
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

local DealAttackDamage = {}

local Utils = require("utils")
local Cards = require("Data.cards")
local AcquireCard = require("Pipelines.AcquireCard")

function DealAttackDamage.execute(world, event)
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
                    DealAttackDamage.executeSingle(world, attacker, enemy, card, aoeTags, event.damage)
                end
            end
        end
        return
    end

    -- Single target damage
    DealAttackDamage.executeSingle(world, attacker, defender, card, tags, event.damage)
end

-- Execute damage against a single target
function DealAttackDamage.executeSingle(world, attacker, defender, card, tags, eventDamage)
    -- Safety check: Skip if defender is invalid or already dead
    if not defender or not defender.hp or defender.hp <= 0 then
        table.insert(world.log, "Damage skipped - target no longer valid")
        return
    end

    -- Start with base damage (use event damage if provided, otherwise use card.damage)
    local damage = eventDamage or (card and card.damage or 0)

    local attackerStatus = attacker and attacker.status or nil
    local defenderStatus = defender.status or nil

    local strengthStacks = 0
    if attackerStatus and attackerStatus.strength then
        strengthStacks = strengthStacks + attackerStatus.strength
    elseif attacker and attacker.strength then
        strengthStacks = strengthStacks + attacker.strength
    end

    local strengthMultiplier = 1
    if card and card.strengthMultiplier then
        strengthMultiplier = card.strengthMultiplier
    end

    if strengthStacks ~= 0 and (card or eventDamage) then
        damage = damage + strengthStacks * strengthMultiplier
    end

    if attackerStatus and attackerStatus.weak and attackerStatus.weak > 0 and damage > 0 then
        damage = math.floor(damage * 0.75)
    end

    -- Apply Vulnerable: 50% more damage (75% with Paper Phrog, rounded down)
    damage = math.max(0, damage)

    if defenderStatus and defenderStatus.vulnerable and defenderStatus.vulnerable > 0 then
        local vulnerableMultiplier = 1.5  -- default 50%

        -- Check if attacker has Paper Phrog relic
        local paperPhrog = attacker and Utils.getRelic(attacker, "Paper_Phrog") or nil
        if paperPhrog then
            vulnerableMultiplier = paperPhrog.vulnerableMultiplier
        end

        damage = math.floor(damage * vulnerableMultiplier)
    end

    if defenderStatus and defenderStatus.slow and defenderStatus.slow > 0 and damage > 0 then
        damage = math.floor(damage * (1 + 0.1 * defenderStatus.slow))
    end

    -- Apply Pen Nib: Double damage on 10th attack
    local penNib = attacker and Utils.getRelic(attacker, "Pen_Nib") or nil
    if penNib and world.penNibCounter >= penNib.triggerCount then
        damage = damage * penNib.damageMultiplier
        table.insert(world.log, "Pen Nib activated! (x" .. penNib.damageMultiplier .. " damage)")
    end

    -- Apply Wrath stance: Double damage dealt/taken
    if attacker.currentStance == "Wrath" then
        damage = damage * 2
    end
    if defender.currentStance == "Wrath" then
        damage = damage * 2
    end

    -- Apply Divinity stance: Triple damage dealt
    if attacker.currentStance == "Divinity" then
        damage = damage * 3
    end

    -- Apply Double Damage status: 2x damage on all attacks this turn
    if attackerStatus and attackerStatus.double_damage and attackerStatus.double_damage > 0 then
        damage = damage * 2
    end

    -- Apply Intangible: Reduce damage to 1 if defender has Intangible status
    if defenderStatus and defenderStatus.intangible and defenderStatus.intangible > 0 and damage > 0 then
        damage = 1
    end

    -- Apply The Boot: If damage is 4 or less, increase it to 5
    -- This is applied AFTER Intangible so The Boot bypasses Intangible damage reduction
    -- (matching Slay the Spire behavior)
    if damage <= 4 and Utils.hasRelic(attacker, "The_Boot") then
        damage = 5
    end

    -- Apply Tungsten Rod: Reduce all incoming damage by 1 (minimum 0)
    -- Applied after all damage multipliers but before block absorption
    local tungstenRod = Utils.getRelic(defender, "Tungsten_Rod")
    if tungstenRod and damage > 0 then
        damage = math.max(0, damage - tungstenRod.damageReduction)
    end

    -- Apply Invincible: Cap damage to remaining invincible value
    -- Applied after all damage multipliers but before block absorption
    if defenderStatus and defenderStatus.invincible and defenderStatus.invincible > 0 and damage > 0 then
        local cappedDamage = math.min(damage, defenderStatus.invincible)
        if cappedDamage < damage then
            local defenderName = defender.name or defender.id or "Unknown"
            table.insert(world.log, defenderName .. "'s Invincible capped damage from " .. damage .. " to " .. cappedDamage)
        end
        damage = cappedDamage
        -- Reduce invincible by damage dealt (will be further reduced after block absorption)
        -- Note: We'll update this after final damage calculation
    end

    local blockAbsorbed = 0

    -- Check if this damage ignores block
    if not Utils.hasTag(tags, "ignoreBlock") then
        -- Apply block absorption
        defender.block = defender.block or 0
        blockAbsorbed = math.min(defender.block, damage)
        defender.block = defender.block - blockAbsorbed
        damage = damage - blockAbsorbed
    end

    local damageDealt = damage

    -- Calculate actual HP that will be lost (accounting for 0 cap, no overkill)
    -- This is useful for effects like Reaper that care about real HP lost
    local actualHpLost = math.min(damage, defender.hp)

    -- Apply remaining damage to HP
    defender.hp = defender.hp - damage

    -- Reduce Invincible by damage dealt (after block absorption)
    -- Invincible caps total damage/HP loss per turn, not just pre-block damage
    if defenderStatus and defenderStatus.invincible and defenderStatus.invincible > 0 and damage > 0 then
        defenderStatus.invincible = defenderStatus.invincible - damage
        -- Clamp to 0 minimum
        if defenderStatus.invincible < 0 then
            defenderStatus.invincible = 0
        end
    end

    -- Reaper effect: Heal attacker for actual HP lost by defender
    if card and card.reaperEffect and attacker and actualHpLost > 0 then
        world.queue:push({
            type = "ON_HEAL",
            target = attacker,
            amount = actualHpLost,
            source = card
        })
    end

    -- Allow enemies to change intent on damage (e.g., Slime Boss splitting)
    if defender.ChangeIntentOnDamage and damage > 0 then
        defender.ChangeIntentOnDamage(defender, world, attacker)
    end

    -- Track HP loss for Blood for Blood (only if player lost HP)
    if defender == world.player and damage > 0 then
        world.combat.timesHpLost = world.combat.timesHpLost + 1

        -- Static Discharge: Channel Lightning when player takes attack damage
        if world.player.status and world.player.status.static_discharge and world.player.status.static_discharge > 0 then
            local channelCount = world.player.status.static_discharge
            for i = 1, channelCount do
                world.queue:push({type = "ON_CHANNEL_ORB", orbType = "Lightning"})
            end
            table.insert(world.log, "Static Discharge triggered! Channeling " .. channelCount .. " Lightning")
        end
    end

    -- Log
    local attackerName = attacker.name or attacker.id or "Unknown"
    local defenderName = defender.name or defender.id or "Unknown"
    local logMsg = attackerName .. " dealt " .. damage .. " damage to " .. defenderName
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

    local defenderIsEnemy = false
    if world.enemies then
        for _, enemy in ipairs(world.enemies) do
            if enemy == defender then
                defenderIsEnemy = true
                break
            end
        end
    end

    if card and card.type == "ATTACK" and attackerStatus and attackerStatus.block_return and attackerStatus.block_return > 0 and damageDealt > 0 and defenderIsEnemy then
        local blockGain = attackerStatus.block_return
        world.queue:push({
            type = "ON_BLOCK",
            target = defender,
            amount = blockGain,
            source = "Block Return"
        })
    end

    -- Trigger Thorns counter-damage (if defender has Thorns status)
    -- Thorns triggers on any attack, even if fully blocked
    -- Thorns damage can be blocked (use ignoreBlock tag for HP loss effects like Bloodletting)
    if defenderStatus and defenderStatus.thorns and defenderStatus.thorns > 0 then
        world.queue:push({
            type = "ON_NON_ATTACK_DAMAGE",
            source = defender,
            target = attacker,
            amount = defenderStatus.thorns
            -- No tags - Thorns respects block
        })
    end

    -- Trigger Painful Stabs (if attacker has Painful Stabs status)
    -- Painful Stabs shuffles a Wound into the defender's discard pile whenever unblocked attack damage is dealt
    if attackerStatus and attackerStatus.painful_stabs and attackerStatus.painful_stabs > 0 and damage > 0 then
        -- Only add Wound if defender is the player (enemies don't have discard piles)
        if defender == world.player and Cards.Wound then
            AcquireCard.execute(world, defender, Cards.Wound, {
                destination = "DISCARD_PILE",
                targetDeck = "combat"
            })
            table.insert(world.log, "Painful Stabs: Wound shuffled into discard pile")
        end
    end
end

return DealAttackDamage

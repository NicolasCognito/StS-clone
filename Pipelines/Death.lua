-- DEATH PIPELINE
-- Processes ON_DEATH events from the queue
--
-- Event should have:
-- - entity: the character that died (hp <= 0)
-- - tags: optional array of tags for on-death effects (e.g., ["feed"])
--
-- Handles:
-- - Logging death
-- - Setting combat result flags (victory/defeat)
-- - Triggering on-death card effects (Feed, etc.)
-- - Future: triggering on-death effects, relics, powers, etc.
--
-- Note: This pipeline does NOT remove enemies from combat.enemies
-- That will be handled in part 2 of the death system refactor

local Death = {}
local Utils = require("utils")

function Death.execute(world, event)
    local entity = event.entity
    local source = event.source
    local damage = event.damage
    local card = event.card

    if not entity then
        table.insert(world.log, "Warning: Death event with no entity")
        return
    end

    -- Log the death with details
    local deathMsg = entity.name .. " has been defeated"
    if source then
        deathMsg = deathMsg .. " by " .. source.name
    end
    if card and card.name then
        deathMsg = deathMsg .. " (" .. card.name .. ")"
    end
    deathMsg = deathMsg .. "!"
    table.insert(world.log, deathMsg)

    -- Set player death flag if player died
    if entity == world.player then
        world.combat.playerDied = true
    else
        -- Mark enemy as dead
        entity.dead = true

        if entity.status and entity.status.corpse_explosion and entity.status.corpse_explosion > 0 then
            local stacks = entity.status.corpse_explosion
            local damageAmount = math.floor((entity.maxHp or 0) * stacks)
            if damageAmount > 0 and world.enemies then
                for _, enemy in ipairs(world.enemies) do
                    if enemy ~= entity and enemy.hp > 0 then
                        world.queue:push({
                            type = "ON_NON_ATTACK_DAMAGE",
                            source = entity,
                            target = enemy,
                            amount = damageAmount,
                            tags = {"ignoreBlock"}
                        })
                    end
                end
                table.insert(world.log, entity.name .. " explodes for " .. damageAmount .. " damage due to Corpse Explosion")
            end
            entity.status.corpse_explosion = nil
        end

        -- Trigger card on-kill effects based on tags
        local tags = event.tags or {}

        -- Feed: heal and increase max HP on kill
        if Utils.hasTag(tags, "feed") and card and source and entity ~= source then
            world.queue:push({
                type = "ON_HEAL",
                target = source,
                amount = card.healAmount,
                maxHpIncrease = card.maxHpGain,
                source = card
            })
        end

        -- Lesson Learned: upgrade a random card in deck on kill
        if Utils.hasTag(tags, "lessonLearned") and card and source and entity ~= source then
            -- Get random upgradeable card from master deck
            local upgradeableCards = {}
            for _, deckCard in ipairs(world.player.masterDeck) do
                if not deckCard.upgraded and not deckCard.disallowUpgrade then
                    table.insert(upgradeableCards, deckCard)
                end
            end

            if #upgradeableCards > 0 then
                local randomCard = upgradeableCards[math.random(#upgradeableCards)]
                local UpgradeCard = require("Pipelines.UpgradeCard")
                UpgradeCard.execute(world, randomCard, { source = "LessonLearned" })
                table.insert(world.log, "Lesson Learned upgraded " .. randomCard.name .. "!")
            else
                table.insert(world.log, "Lesson Learned has no cards to upgrade.")
            end
        end

        -- Ritual Dagger: increase damage permanently on kill
        if Utils.hasTag(tags, "ritualDagger") and card and source and entity ~= source then
            -- Increase combat card damage
            local damageBonus = card.damageIncrease or 3
            card.damage = (card.damage or 15) + damageBonus

            -- Find and update masterDeck version to persist across combats
            for _, deckCard in ipairs(world.player.masterDeck) do
                if deckCard.id == "RitualDagger" then
                    deckCard.damage = card.damage
                    break  -- Only update first match
                end
            end

            table.insert(world.log, "Ritual Dagger's damage increased to " .. card.damage .. "!")
        end
    end

    -- Future: Trigger on-death effects, relics, powers, etc.
    -- Example: "When an enemy dies, gain 1 energy" or "When you kill an enemy with poison, draw a card"
end

return Death

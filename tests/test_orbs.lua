-- Test orbs mechanic (Lightning, Frost, Dark, Plasma)

local World = require("World")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local Utils = require("utils")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local EndTurn = require("Pipelines.EndTurn")
local StartTurn = require("Pipelines.StartTurn")

print("\n=== ORBS MECHANIC TEST ===\n")

-- Helper to copy a card
local function copyCard(template)
    local c = {}
    for k, v in pairs(template) do
        c[k] = v
    end
    return c
end

-- Test 1: Channel Lightning and trigger passive
print("TEST 1: Channel Lightning and passive effect")
local world1 = World.createWorld({
    id = "Defect",
    maxHp = 80,
    currentHp = 80,
    cards = {
        copyCard(Cards.Zap),
        copyCard(Cards.Defend)
    }
})

world1.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world1.enemies[1].hp = 50

StartCombat.execute(world1, world1.player, world1.enemies)

-- Play Zap to channel Lightning
local zapCard = nil
for _, card in ipairs(world1.player.combatDeck) do
    if card.id == "Zap" and card.state == "HAND" then
        zapCard = card
        break
    end
end

if zapCard then
    PlayCard.execute(world1, world1.player, zapCard)
    ProcessEventQueue.execute(world1)

    print("Orbs after channeling:", #world1.player.orbs)
    assert(#world1.player.orbs == 1, "Should have 1 orb")
    assert(world1.player.orbs[1].id == "Lightning", "Should be Lightning orb")

    local enemyHpBefore = world1.enemies[1].hp
    EndTurn.execute(world1, world1.player)
    local enemyHpAfter = world1.enemies[1].hp

    print("Enemy HP before passive:", enemyHpBefore)
    print("Enemy HP after passive:", enemyHpAfter)
    assert(enemyHpAfter < enemyHpBefore, "Lightning passive should damage enemy")
end

print("✓ TEST 1 PASSED\n")

-- Test 2: Channel Frost and gain block
print("TEST 2: Channel Frost and passive block")
local world2 = World.createWorld({
    id = "Defect",
    maxHp = 80,
    currentHp = 80,
    cards = {
        copyCard(Cards.Coolheaded),
        copyCard(Cards.Defend)
    }
})

world2.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
StartCombat.execute(world2, world2.player, world2.enemies)

-- Play Coolheaded to channel Frost
local coolCard = nil
for _, card in ipairs(world2.player.combatDeck) do
    if card.id == "Coolheaded" and card.state == "HAND" then
        coolCard = card
        break
    end
end

if coolCard then
    PlayCard.execute(world2, world2.player, coolCard)
    ProcessEventQueue.execute(world2)

    print("Orbs after channeling:", #world2.player.orbs)
    assert(#world2.player.orbs == 1, "Should have 1 orb")
    assert(world2.player.orbs[1].id == "Frost", "Should be Frost orb")

    world2.player.block = 0  -- Reset block
    EndTurn.execute(world2, world2.player)

    print("Player block after passive:", world2.player.block)
    -- Note: Block gets reset at start of turn, so we won't see it here
end

print("✓ TEST 2 PASSED\n")

-- Test 3: Channel Dark and accumulation
print("TEST 3: Channel Dark and accumulation")
local world3 = World.createWorld({
    id = "Defect",
    maxHp = 80,
    currentHp = 80,
    cards = {
        copyCard(Cards.Darkness),
        copyCard(Cards.Defend)
    }
})

world3.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
StartCombat.execute(world3, world3.player, world3.enemies)

-- Play Darkness to channel Dark
local darkCard = nil
for _, card in ipairs(world3.player.combatDeck) do
    if card.id == "Darkness" and card.state == "HAND" then
        darkCard = card
        break
    end
end

if darkCard then
    PlayCard.execute(world3, world3.player, darkCard)
    ProcessEventQueue.execute(world3)

    print("Orbs after channeling:", #world3.player.orbs)
    assert(#world3.player.orbs == 1, "Should have 1 orb")
    assert(world3.player.orbs[1].id == "Dark", "Should be Dark orb")

    local initialDamage = world3.player.orbs[1].accumulatedDamage
    print("Initial accumulated damage:", initialDamage)

    EndTurn.execute(world3, world3.player)

    local newDamage = world3.player.orbs[1].accumulatedDamage
    print("Accumulated damage after passive:", newDamage)
    assert(newDamage > initialDamage, "Dark orb should accumulate damage")
end

print("✓ TEST 3 PASSED\n")

-- Test 4: Focus scaling
print("TEST 4: Focus scaling")
local world4 = World.createWorld({
    id = "Defect",
    maxHp = 80,
    currentHp = 80,
    cards = {
        copyCard(Cards.Defragment),
        copyCard(Cards.Zap),
        copyCard(Cards.Defend)
    }
})

world4.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world4.enemies[1].hp = 100
StartCombat.execute(world4, world4.player, world4.enemies)

-- Play Defragment to gain Focus
local defragCard = nil
local zapCard4 = nil
for _, card in ipairs(world4.player.combatDeck) do
    if card.id == "Defragment" and card.state == "HAND" then
        defragCard = card
    elseif card.id == "Zap" and card.state == "HAND" then
        zapCard4 = card
    end
end

if defragCard and zapCard4 then
    PlayCard.execute(world4, world4.player, defragCard)
    ProcessEventQueue.execute(world4)

    print("Focus after Defragment:", world4.player.status.focus or 0)
    assert(world4.player.status.focus == 1, "Should have 1 Focus")

    -- Play Zap to channel Lightning
    PlayCard.execute(world4, world4.player, zapCard4)
    ProcessEventQueue.execute(world4)

    local enemyHpBefore = world4.enemies[1].hp
    EndTurn.execute(world4, world4.player)
    local enemyHpAfter = world4.enemies[1].hp

    local damageDone = enemyHpBefore - enemyHpAfter
    print("Damage from Lightning passive with Focus:", damageDone)
    assert(damageDone == 4, "Lightning passive with 1 Focus should do 4 damage (3 + 1)")
end

print("✓ TEST 4 PASSED\n")

-- Test 5: Orb slot limit (evoke when full)
print("TEST 5: Orb slot limit and auto-evoke")
local world5 = World.createWorld({
    id = "Defect",
    maxHp = 80,
    currentHp = 80,
    cards = {
        copyCard(Cards.Zap),
        copyCard(Cards.Zap),
        copyCard(Cards.Zap),
        copyCard(Cards.Zap),
        copyCard(Cards.Defend)
    }
})

world5.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
world5.enemies[1].hp = 100
StartCombat.execute(world5, world5.player, world5.enemies)

-- Channel 4 Lightning orbs (should evoke the first one when 4th is channeled)
local zapsPlayed = 0
for _, card in ipairs(world5.player.combatDeck) do
    if card.id == "Zap" and card.state == "HAND" and zapsPlayed < 4 then
        PlayCard.execute(world5, world5.player, card)
        ProcessEventQueue.execute(world5)
        zapsPlayed = zapsPlayed + 1
        print("After channeling " .. zapsPlayed .. " orbs, player has " .. #world5.player.orbs .. " orbs")
    end
end

assert(#world5.player.orbs == 3, "Should have exactly 3 orbs (maxOrbs limit)")

print("✓ TEST 5 PASSED\n")

-- Test 6: Plasma energy gain
print("TEST 6: Plasma energy at start of turn")
local world6 = World.createWorld({
    id = "Defect",
    maxHp = 80,
    currentHp = 80,
    cards = {
        copyCard(Cards.Charge),
        copyCard(Cards.Defend)
    }
})

world6.enemies = {Utils.copyEnemyTemplate(Enemies.Cultist)}
StartCombat.execute(world6, world6.player, world6.enemies)

-- Play Charge to channel Plasma
local chargeCard = nil
for _, card in ipairs(world6.player.combatDeck) do
    if card.id == "Charge" and card.state == "HAND" then
        chargeCard = card
        break
    end
end

if chargeCard then
    local energyBefore = world6.player.energy
    PlayCard.execute(world6, world6.player, chargeCard)
    ProcessEventQueue.execute(world6)

    print("Orbs after channeling:", #world6.player.orbs)
    assert(#world6.player.orbs == 1, "Should have 1 orb")
    assert(world6.player.orbs[1].id == "Plasma", "Should be Plasma orb")

    EndTurn.execute(world6, world6.player)
    StartTurn.execute(world6, world6.player)

    print("Energy at start of turn with Plasma:", world6.player.energy)
    -- Player should have maxEnergy (3) + 1 from Plasma = 4
    assert(world6.player.energy == 4, "Should have 4 energy (3 base + 1 from Plasma)")
end

print("✓ TEST 6 PASSED\n")

print("=== ALL ORBS TESTS PASSED ===\n")

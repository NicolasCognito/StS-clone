local World = require("World")
local Utils = require("utils")
local Cards = require("Data.cards")
local Relics = require("Data.relics")
local Enemies = require("Data.enemies")
local StartCombat = require("Pipelines.StartCombat")
local PlayCard = require("Pipelines.PlayCard")
local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
local ContextProvider = require("Pipelines.ContextProvider")

math.randomseed(1337)

local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local function copyRelic(template)
    local relic = {}
    for k, v in pairs(template) do
        relic[k] = v
    end
    return relic
end

local function fulfillContext(world, player, override)
    local request = world.combat.contextRequest
    assert(request, "Context request should exist")

    local context = override or ContextProvider.execute(world, player, request.contextProvider, request.card)
    assert(context, "ContextProvider failed to supply context")

    if request.stability == "stable" then
        world.combat.stableContext = context
    else
        world.combat.tempContext = context
    end

    world.combat.contextRequest = nil
    return context
end

-- Test 1: Champion's Belt should apply Weak when Vulnerable is applied
do
    print("\n=== TEST 1: Champion's Belt applies Weak when Vulnerable is applied ===")

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        cards = {copyCard(Cards.Bash)},
        relics = {copyRelic(Relics.ChampionsBelt)},
        masterPotions = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    StartCombat.execute(world)

    local player = world.player
    local enemy = world.enemies[1]

    -- Verify relic is equipped
    assert(Utils.hasRelic(player, "Champions_Belt"), "Player should have Champion's Belt")

    -- Verify enemy starts with no status effects
    assert(not enemy.status.vulnerable or enemy.status.vulnerable == 0, "Enemy should start with no Vulnerable")
    assert(not enemy.status.weak or enemy.status.weak == 0, "Enemy should start with no Weak")

    -- Find Bash in hand
    local bashCard = nil
    for _, card in ipairs(player.combatDeck) do
        if card.id == "Bash" and card.state == "HAND" then
            bashCard = card
            break
        end
    end
    assert(bashCard, "Bash should be in hand")

    -- Play Bash (will request context)
    local result = PlayCard.execute(world, player, bashCard)

    -- Fulfill context with the enemy
    if world.combat.contextRequest then
        fulfillContext(world, player, enemy)
        -- Continue playing the card
        result = PlayCard.execute(world, player, bashCard)
    end

    -- Process any remaining events
    ProcessEventQueue.execute(world)

    -- Verify enemy has both Vulnerable and Weak
    assert(enemy.status.vulnerable == 2, "Enemy should have 2 Vulnerable (was " .. (enemy.status.vulnerable or 0) .. ")")
    assert(enemy.status.weak == 1, "Enemy should have 1 Weak from Champion's Belt (was " .. (enemy.status.weak or 0) .. ")")

    print("✓ Champion's Belt correctly applies 1 Weak when Vulnerable is applied")
end

-- Test 2: Champion's Belt should not apply Weak to the player
do
    print("\n=== TEST 2: Champion's Belt should not apply Weak to the player ===")

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        cards = {},
        relics = {copyRelic(Relics.ChampionsBelt)},
        masterPotions = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    StartCombat.execute(world)

    local player = world.player

    -- Manually apply Vulnerable to the player (simulating enemy attack)
    world.queue:push({
        type = "ON_STATUS_GAIN",
        target = player,
        effectType = "Vulnerable",
        amount = 2,
        source = "Test"
    })
    ProcessEventQueue.execute(world)

    -- Verify player has Vulnerable but NOT Weak
    assert(player.status.vulnerable == 2, "Player should have 2 Vulnerable")
    assert(not player.status.weak or player.status.weak == 0, "Player should NOT have Weak from Champion's Belt (was " .. (player.status.weak or 0) .. ")")

    print("✓ Champion's Belt correctly does not apply Weak to the player")
end

-- Test 3: Champion's Belt should not trigger on negative Vulnerable amounts
do
    print("\n=== TEST 3: Champion's Belt should not trigger on negative Vulnerable ===")

    local world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        cards = {},
        relics = {copyRelic(Relics.ChampionsBelt)},
        masterPotions = {}
    })

    world.enemies = {copyEnemy(Enemies.Cultist)}
    StartCombat.execute(world)

    local enemy = world.enemies[1]

    -- Give enemy some Vulnerable first
    enemy.status.vulnerable = 5

    -- Apply negative Vulnerable (removing it)
    world.queue:push({
        type = "ON_STATUS_GAIN",
        target = enemy,
        effectType = "Vulnerable",
        amount = -2,
        source = "Test"
    })
    ProcessEventQueue.execute(world)

    -- Verify enemy Vulnerable decreased but no Weak was added
    assert(enemy.status.vulnerable == 3, "Enemy should have 3 Vulnerable (5 - 2)")
    assert(not enemy.status.weak or enemy.status.weak == 0, "Enemy should NOT have Weak (was " .. (enemy.status.weak or 0) .. ")")

    print("✓ Champion's Belt correctly does not trigger on negative Vulnerable amounts")
end

print("\n=== ALL CHAMPION'S BELT TESTS PASSED ===")

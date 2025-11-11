local World = require("World")
local MapEvents = require("Data.mapevents")
local MapEngine = require("MapEngine")
local Relics = require("Data.relics")

math.randomseed(1337)

local Campfire = MapEvents.Campfire

local function createWorld(options)
    options = options or {}
    local relics = {}
    for _, relicId in ipairs(options.relics or {}) do
        local relic = Relics[relicId]
        assert(relic, "Unknown relic id: " .. tostring(relicId))
        table.insert(relics, relic)
    end

    local world = World.createWorld({
        id = "IronClad",
        maxHp = options.maxHp or 80,
        currentHp = options.hp or options.maxHp or 80,
        cards = {},
        relics = relics,
        act4Unlocked = options.act4Unlocked or false,
        rubyKeyObtained = options.rubyKeyObtained or false
    })

    world.player.masterDeck = {}
    world.log = {}
    return world
end

-- Test 1: Baseline rest heals 30% of max HP
do
    local world = createWorld({hp = 40})
    Campfire.nodes.arrival.onEnter(world)
    Campfire.nodes.rest.onEnter(world)
    MapEngine.drainMapQueue(world)

    assert(world.player.currentHp == 64, "Rest should heal 24 HP (30% of 80)")

    local foundMessage = false
    for _, entry in ipairs(world.log) do
        if entry:find("Campfire Rest: Healed 24 HP") then
            foundMessage = true
            break
        end
    end
    assert(foundMessage, "Rest should log the heal amount")
end

-- Test 2: Coffee Dripper blocks rest healing
do
    local world = createWorld({hp = 40, relics = {"CoffeeDripper"}})
    Campfire.nodes.arrival.onEnter(world)
    Campfire.nodes.rest.onEnter(world)
    MapEngine.drainMapQueue(world)

    assert(world.player.currentHp == 40, "Coffee Dripper should prevent resting")

    local foundMessage = false
    for _, entry in ipairs(world.log) do
        if entry:find("Coffee Dripper hums loudly") then
            foundMessage = true
            break
        end
    end
    assert(foundMessage, "Coffee Dripper denial message should be logged")
end

-- Test 3: Regal Pillow bonus and Dream Catcher reward
do
    local world = createWorld({hp = 40, relics = {"RegalPillow", "DreamCatcher"}})
    Campfire.nodes.arrival.onEnter(world)
    Campfire.nodes.rest.onEnter(world)
    MapEngine.drainMapQueue(world)

    assert(world.player.currentHp == 79, "Rest should heal 24 + 15 HP with Regal Pillow")
    assert(#world.player.masterDeck == 1, "Dream Catcher should add one card to the deck")
end

-- Test 4: Entry effects for Ancient Tea Set and Eternal Feather
do
    local world = createWorld({hp = 40, relics = {"AncientTeaSet", "EternalFeather"}})
    -- Populate deck so Eternal Feather heals
    for _ = 1, 10 do
        table.insert(world.player.masterDeck, {})
    end

    Campfire.nodes.arrival.onEnter(world)
    MapEngine.drainMapQueue(world)

    assert(world.pendingRestSiteEnergy == 2, "Ancient Tea Set should queue +2 energy next combat")
    assert(world.player.currentHp == 46, "Eternal Feather should heal 6 HP for 10-card deck")
end

-- Test 5: Girya Lift grants permanent strength and tracks uses
do
    local world = createWorld({relics = {"Girya"}})
    Campfire.nodes.arrival.onEnter(world)
    Campfire.nodes.lift.onEnter(world)
    MapEngine.drainMapQueue(world)

    assert(world.player.permanentStrength == 1, "Girya Lift should add 1 permanent strength")
    assert(world.giryaLiftsUsed == 1, "Girya Lift count should increment")
end

-- Test 6: Shovel dig grants an additional relic
do
    local world = createWorld({relics = {"Shovel"}})
    local initialRelicCount = #world.player.relics

    Campfire.nodes.arrival.onEnter(world)
    Campfire.nodes.dig.onEnter(world)
    MapEngine.drainMapQueue(world)

    assert(#world.player.relics == initialRelicCount + 1, "Dig should add a random relic")

    local foundMessage = false
    for _, entry in ipairs(world.log) do
        if entry:find("You dig up") then
            foundMessage = true
            break
        end
    end
    assert(foundMessage, "Dig result should be logged")
end

-- Test 7: Smith upgrades the selected card via map context
do
    local world = createWorld()
    local smithTarget = {
        id = "TEST_SMITH",
        name = "Proto Smith Target",
        cost = 2,
        upgraded = false,
        onUpgrade = function(self)
            self.cost = (self.cost or 2) - 1
        end
    }

    table.insert(world.player.masterDeck, smithTarget)

    Campfire.nodes.arrival.onEnter(world)
    Campfire.nodes.smith.onEnter(world)

    MapEngine.drainMapQueue(world)

    assert(smithTarget.upgraded, "Smith should upgrade the selected card")
    assert(smithTarget.cost == 1, "onUpgrade callback should run for the smith target")
    assert(not world.mapEvent or world.mapEvent.tempContext == nil, "Temp context should be cleared after smith completes")

    local loggedUpgrade = false
    for _, entry in ipairs(world.log) do
        if entry:find("Upgraded Proto Smith Target") then
            loggedUpgrade = true
            break
        end
    end
    assert(loggedUpgrade, "Smith should log the upgrade result")
end

print("Campfire map event tests passed.")

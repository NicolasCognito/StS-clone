-- LOVE 2D MAIN ENTRY POINT
-- Simple primitive-based UI for Kill the Tower

local World = require("World")
local CombatLove = require("UIs.love_gui.CombatLove")
local MapLove = require("UIs.love_gui.MapLove")
local DeckbuilderLove = require("UIs.love_gui.DeckbuilderLove")
local Cards = require("Data.cards")
local Enemies = require("Data.enemies")
local Maps = require("Data.maps")
local Utils = require("utils")
local StartCombat = require("Pipelines.StartCombat")

-- Helper function
local function copyCard(template)
    return Utils.copyCardTemplate(template)
end

-- Game state
local world = nil
local gameMode = "menu" -- "menu", "combat", "map", "deckbuilder"
local menuSelection = 1

function love.load()
    love.window.setTitle("Kill the Tower - LOVE 2D")
    love.window.setMode(1024, 768)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
end

function love.draw()
    if gameMode == "menu" then
        drawMenu()
    elseif gameMode == "combat" then
        CombatLove.draw(world)
    elseif gameMode == "map" then
        MapLove.draw(world)
    elseif gameMode == "deckbuilder" then
        DeckbuilderLove.draw()
    end
end

function love.update(dt)
    if gameMode == "combat" then
        CombatLove.update(world, dt)
    elseif gameMode == "map" then
        MapLove.update(world, dt)
    elseif gameMode == "deckbuilder" then
        DeckbuilderLove.update(dt)
    end
end

function love.keypressed(key)
    if gameMode == "menu" then
        handleMenuInput(key)
    elseif gameMode == "combat" then
        CombatLove.keypressed(world, key)
    elseif gameMode == "map" then
        MapLove.keypressed(world, key)
    elseif gameMode == "deckbuilder" then
        DeckbuilderLove.keypressed(key)
    end
end

function love.textinput(text)
    if gameMode == "combat" then
        CombatLove.textinput(world, text)
    elseif gameMode == "map" then
        MapLove.textinput(world, text)
    elseif gameMode == "deckbuilder" then
        DeckbuilderLove.textinput(text)
    end
end

function love.mousepressed(x, y, button)
    if gameMode == "combat" then
        CombatLove.mousepressed(world, x, y, button)
    elseif gameMode == "map" then
        -- MapLove.mousepressed could be added later
    elseif gameMode == "deckbuilder" then
        DeckbuilderLove.mousepressed(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if gameMode == "deckbuilder" then
        DeckbuilderLove.wheelmoved(x, y)
    end
end

function drawMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("KILL THE TOWER", 50, 50, 0, 2, 2)

    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Select a mode:", 50, 150)

    -- Menu options
    local options = {
        {text = "1. Start Combat (Demo)", action = startCombatDemo},
        {text = "2. Start Map (Demo)", action = startMapDemo},
        {text = "3. Deckbuilder Mode", action = startDeckbuilder},
        {text = "4. Test Combat", action = startTestCombat},
        {text = "5. Quit", action = function() love.event.quit() end}
    }

    for i, option in ipairs(options) do
        local y = 200 + (i - 1) * 40
        if i == menuSelection then
            love.graphics.setColor(1, 1, 0)
            love.graphics.rectangle("fill", 40, y - 5, 500, 30)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.print(option.text, 50, y)
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Use UP/DOWN arrows to navigate, ENTER to select", 50, 550)
end

function handleMenuInput(key)
    if key == "up" then
        menuSelection = math.max(1, menuSelection - 1)
    elseif key == "down" then
        menuSelection = math.min(5, menuSelection + 1)
    elseif key == "return" then
        if menuSelection == 1 then
            startCombatDemo()
        elseif menuSelection == 2 then
            startMapDemo()
        elseif menuSelection == 3 then
            startDeckbuilder()
        elseif menuSelection == 4 then
            startTestCombat()
        elseif menuSelection == 5 then
            love.event.quit()
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

function startCombatDemo()
    -- Create a simple combat scenario
    -- Create world with IronClad starter deck
    world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        masterDeck = {
            copyCard(Cards.Strike), copyCard(Cards.Strike), copyCard(Cards.Strike),
            copyCard(Cards.Strike), copyCard(Cards.Strike),
            copyCard(Cards.Defend), copyCard(Cards.Defend), copyCard(Cards.Defend),
            copyCard(Cards.Defend), copyCard(Cards.WellLaidPlans),
            copyCard(Cards.Bash), copyCard(Cards.FlameBarrier), copyCard(Cards.Bloodletting)
        },
        relics = {}
    })

    -- Set up enemies
    world.enemies = {
        Utils.copyEnemyTemplate(Enemies.SlimeBoss)
    }

    -- Initialize combat
    StartCombat.execute(world)

    -- Switch to combat mode
    gameMode = "combat"
    CombatLove.init(world)
end

function startMapDemo()
    -- Create a simple map scenario
    world = World.createWorld({
        id = "IronClad",
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        masterDeck = {
            copyCard(Cards.Strike), copyCard(Cards.Strike), copyCard(Cards.Strike),
            copyCard(Cards.Strike), copyCard(Cards.Strike),
            copyCard(Cards.Defend), copyCard(Cards.Defend), copyCard(Cards.Defend),
            copyCard(Cards.Defend),
            copyCard(Cards.Bash)
        },
        relics = {},
        map = Maps.TestMap,
        startNode = Maps.TestMap.startNode
    })

    -- Switch to map mode
    gameMode = "map"
    MapLove.init(world)
end

function startDeckbuilder()
    gameMode = "deckbuilder"
    DeckbuilderLove.init()
end

function startTestCombat()
    gameMode = "deckbuilder"
    DeckbuilderLove.initTestCombat()
end

function startTestCombatWithDeck(masterDeck, relics, character, enemyData)
    -- Create world with the custom deck
    local characterData = {
        id = character,
        maxHp = 80,
        currentHp = 80,
        maxEnergy = 3,
        masterDeck = masterDeck,
        relics = relics  -- Use provided relics
    }

    world = World.createWorld(characterData)

    -- Set up enemy
    world.enemies = {
        Utils.copyEnemyTemplate(enemyData)
    }

    -- Initialize combat with error handling
    local success, err = pcall(StartCombat.execute, world)
    if not success then
        error("StartCombat failed: " .. tostring(err))
    end

    -- Process any queued events from relics/combat start
    local ProcessEventQueue = require("Pipelines.ProcessEventQueue")
    success, err = pcall(ProcessEventQueue.execute, world)
    if not success then
        error("ProcessEventQueue failed: " .. tostring(err))
    end

    -- Switch to combat mode
    gameMode = "combat"
    CombatLove.init(world)
end

function returnToMenu()
    gameMode = "menu"
    menuSelection = 1
    world = nil
end

-- Export for use by other modules
_G.returnToMenu = returnToMenu
_G.startTestCombatWithDeck = startTestCombatWithDeck

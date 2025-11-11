-- SIMPLE COMBAT EVENT
-- Basic combat encounter that can be triggered from any combat node

local MapQueue = require("Pipelines.Map_MapQueue")
local Utils = require("utils")
local Enemies = require("Data.enemies")

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

return {
    SimpleCombat = {
        id = "SIMPLE_COMBAT",
        name = "Simple Combat",
        tags = {"combat"},
        entryNode = "start",
        nodes = {
            start = {
                onEnter = function(world)
                    -- Setup enemies based on node difficulty
                    local enemies = {}
                    local currentNode = world.map and world.map.nodes[world.currentNode]
                    local difficulty = currentNode and currentNode.difficulty or "normal"

                    if difficulty == "easy" or difficulty == "normal" then
                        -- 2 goblins for normal fights
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                    elseif difficulty == "elite" then
                        -- 3 goblins for elite
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                    elseif difficulty == "boss" then
                        -- 4 goblins for boss (placeholder)
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                        table.insert(enemies, copyEnemy(Enemies.Goblin))
                    end

                    -- Queue combat start
                    MapQueue.push(world, {
                        type = "MAP_START_COMBAT",
                        enemies = enemies,
                        onVictory = "continue",  -- Continue map after victory
                        onDefeat = "exit"        -- Exit map on defeat
                    })

                    -- Complete the event after combat is queued
                    MapQueue.push(world, {
                        type = "MAP_EVENT_COMPLETE",
                        result = "combat_queued"
                    })

                    return "exit"
                end
            },

            exit = {
                exit = { result = "complete" }
            }
        }
    }
}

-- ENCOUNTERS TABLE
-- Defines individual enemy encounters that can be referenced by maps
-- Each encounter specifies a set of enemies for different difficulty levels

local Enemies = require("Data.enemies")
local Utils = require("utils")

local function copyEnemy(template)
    return Utils.copyEnemyTemplate(template)
end

local Encounters = {
    -- Easy encounters
    ["goblin_duo"] = {
        easy = function()
            return {
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.Goblin)
            }
        end,
        normal = function()
            return {
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.Goblin)
            }
        end,
        elite = function()
            return {
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.Goblin)
            }
        end
    },

    ["small_slimes"] = {
        easy = function()
            return {
                copyEnemy(Enemies.SpikeSlime),
                copyEnemy(Enemies.SpikeSlime)
            }
        end,
        normal = function()
            return {
                copyEnemy(Enemies.SpikeSlime),
                copyEnemy(Enemies.SpikeSlime),
                copyEnemy(Enemies.SpikeSlime)
            }
        end,
        elite = function()
            return {
                copyEnemy(Enemies.AcidSlime),
                copyEnemy(Enemies.SpikeSlime),
                copyEnemy(Enemies.SpikeSlime)
            }
        end
    },

    ["lots_of_slimes"] = {
        easy = function()
            return {
                copyEnemy(Enemies.AcidSlime)
            }
        end,
        normal = function()
            return {
                copyEnemy(Enemies.AcidSlime),
                copyEnemy(Enemies.SpikeSlime)
            }
        end,
        elite = function()
            return {
                copyEnemy(Enemies.AcidSlime),
                copyEnemy(Enemies.AcidSlime)
            }
        end
    },

    ["slime_boss"] = {
        easy = function()
            return {
                copyEnemy(Enemies.SlimeBoss)
            }
        end,
        normal = function()
            return {
                copyEnemy(Enemies.SlimeBoss)
            }
        end,
        elite = function()
            return {
                copyEnemy(Enemies.SlimeBoss),
                copyEnemy(Enemies.AcidSlime)
            }
        end
    },

    ["cultist_solo"] = {
        easy = function()
            return {
                copyEnemy(Enemies.Cultist)
            }
        end,
        normal = function()
            return {
                copyEnemy(Enemies.Cultist)
            }
        end,
        elite = function()
            return {
                copyEnemy(Enemies.Cultist),
                copyEnemy(Enemies.Goblin)
            }
        end
    },

    ["mixed_encounter"] = {
        easy = function()
            return {
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.SpikeSlime)
            }
        end,
        normal = function()
            return {
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.SpikeSlime)
            }
        end,
        elite = function()
            return {
                copyEnemy(Enemies.AcidSlime),
                copyEnemy(Enemies.Goblin),
                copyEnemy(Enemies.Goblin)
            }
        end
    },

    ["corrupt_heart"] = {
        easy = function()
            return {
                copyEnemy(Enemies.CorruptHeart)
            }
        end,
        normal = function()
            return {
                copyEnemy(Enemies.CorruptHeart)
            }
        end,
        elite = function()
            return {
                copyEnemy(Enemies.CorruptHeart)
            }
        end
    }
}

-- Helper function to get a random encounter for a given difficulty
function Encounters.getRandomEncounter(difficulty)
    difficulty = difficulty or "normal"

    local encounterKeys = {}
    for key, _ in pairs(Encounters) do
        if type(Encounters[key]) == "table" and Encounters[key][difficulty] then
            table.insert(encounterKeys, key)
        end
    end

    if #encounterKeys == 0 then
        -- Fallback to goblin_duo if no encounters found
        local fallbackEncounter = Encounters.goblin_duo[difficulty]
        if not fallbackEncounter then
            print("WARNING: Unsupported difficulty '" .. difficulty .. "', defaulting to 'normal'")
            fallbackEncounter = Encounters.goblin_duo["normal"]
        end
        return fallbackEncounter()
    end

    local randomKey = encounterKeys[math.random(#encounterKeys)]
    local encounterGenerator = Encounters[randomKey][difficulty]
    if not encounterGenerator then
        print("WARNING: Encounter '" .. randomKey .. "' has no '" .. difficulty .. "' difficulty, defaulting to 'normal'")
        encounterGenerator = Encounters[randomKey]["normal"]
    end
    return encounterGenerator()
end

-- Helper function to get a specific encounter by name
function Encounters.getEncounter(encounterName, difficulty)
    difficulty = difficulty or "normal"

    if Encounters[encounterName] and Encounters[encounterName][difficulty] then
        return Encounters[encounterName][difficulty]()
    end

    -- Fallback
    return Encounters.goblin_duo[difficulty]()
end

return Encounters

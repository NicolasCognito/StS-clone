-- AUTO-LOADING ENEMIES AGGREGATOR
-- Automatically loads all enemy files from Data/Enemies/ directory

local Enemies = {}

local enemyFiles = {
    "goblin"
}

for _, fileName in ipairs(enemyFiles) do
    local enemy = require("Data.Enemies." .. fileName)
    for key, value in pairs(enemy) do
        Enemies[key] = value
    end
end

return Enemies

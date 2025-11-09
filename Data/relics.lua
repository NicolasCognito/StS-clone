-- AUTO-LOADING RELICS AGGREGATOR
-- Automatically loads all relic files from Data/Relics/ directory

local Relics = {}

local relicFiles = {
    "burningblood",
    "paperphrog",
    "sneckoeye",
    "theboot",
    "wingedboots"
}

for _, fileName in ipairs(relicFiles) do
    local relic = require("Data.Relics." .. fileName)
    for key, value in pairs(relic) do
        Relics[key] = value
    end
end

return Relics

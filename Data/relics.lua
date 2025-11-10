-- AUTO-LOADING RELICS AGGREGATOR
-- Automatically loads all relic files from Data/Relics/ directory

local Relics = {}

local relicFiles = {
    "burningblood",
    "paperphrog",
    "pennib",
    "sneckoeye",
    "theboot",
    "wingedboots",
    "chemicalx",
    "necronomicon"
}

for _, fileName in ipairs(relicFiles) do
    local relic = require("Data.Relics." .. fileName)
    for key, value in pairs(relic) do
        Relics[key] = value
    end
end

return Relics

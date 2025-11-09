-- AUTO-LOADING MAPS AGGREGATOR
-- Automatically loads map definition files from Data/Maps/

local Maps = {}

local mapFiles = {
    "testmap"
}

for _, fileName in ipairs(mapFiles) do
    local mapModule = require("Data.Maps." .. fileName)
    for key, value in pairs(mapModule) do
        Maps[key] = value
    end
end

return Maps


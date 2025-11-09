-- AUTO-LOADING POWERS AGGREGATOR
-- Automatically loads all power files from Data/Powers/ directory

local Powers = {}

local powerFiles = {
    "corruption"
}

for _, fileName in ipairs(powerFiles) do
    local power = require("Data.Powers." .. fileName)
    for key, value in pairs(power) do
        Powers[key] = value
    end
end

return Powers

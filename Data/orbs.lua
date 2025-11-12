-- AUTO-LOADING ORBS AGGREGATOR
-- Automatically loads all orb files from Data/Orbs/ directory

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local Orbs = {}
LoaderUtils.loadModules(Orbs, "Data.Orbs", "Orbs", {moduleName = moduleName})

return Orbs

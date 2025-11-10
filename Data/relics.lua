-- AUTO-LOADING RELICS AGGREGATOR
-- Automatically loads all relic files from Data/Relics/ directory

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local Relics = {}
LoaderUtils.loadModules(Relics, "Data.Relics", "Relics", {moduleName = moduleName})

return Relics

-- AUTO-LOADING POTIONS AGGREGATOR
-- Automatically loads all potion files from Data/Potions/ directory

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local Potions = {}
LoaderUtils.loadModules(Potions, "Data.Potions", "Potions", {moduleName = moduleName})

return Potions

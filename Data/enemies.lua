-- AUTO-LOADING ENEMIES AGGREGATOR
-- Automatically loads all enemy files from Data/Enemies/ directory

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local Enemies = {}
LoaderUtils.loadModules(Enemies, "Data.Enemies", "Enemies", {moduleName = moduleName})

return Enemies

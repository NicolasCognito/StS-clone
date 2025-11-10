-- AUTO-LOADING MAPS AGGREGATOR
-- Automatically loads map definition files from Data/Maps/

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local Maps = {}
LoaderUtils.loadModules(Maps, "Data.Maps", "Maps", {moduleName = moduleName})

return Maps

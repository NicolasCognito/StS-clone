-- AUTO-LOADING MAP EVENTS AGGREGATOR
-- Automatically loads map event definition files from Data/MapEvents/

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local MapEvents = {}
LoaderUtils.loadModules(MapEvents, "Data.MapEvents", "MapEvents", {moduleName = moduleName})

return MapEvents

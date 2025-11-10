-- AUTO-LOADING POWERS AGGREGATOR
-- Automatically loads all power files from Data/Powers/ directory

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local Powers = {}
LoaderUtils.loadModules(Powers, "Data.Powers", "Powers", {moduleName = moduleName})

return Powers

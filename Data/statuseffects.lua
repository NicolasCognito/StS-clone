-- AUTO-LOADING STATUS EFFECTS AGGREGATOR
-- Automatically loads all status effect files from Data/StatusEffects/ directory

local LoaderUtils = require("Data.loader_utils")
local moduleName = ...

local StatusEffects = {}
LoaderUtils.loadModules(StatusEffects, "Data.StatusEffects", "StatusEffects", {moduleName = moduleName})

return StatusEffects

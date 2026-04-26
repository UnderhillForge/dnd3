-- dnd3 Weather Subsystem bootstrap.
-- Sets up dnd3.weather namespace and loads sub-modules.

dnd3.weather = dnd3.weather or {}

local modpath     = dnd3.modpath
local weatherpath = modpath .. "/systems/weather"

dofile(weatherpath .. "/types.lua")
dofile(weatherpath .. "/engine.lua")
dofile(weatherpath .. "/gm_control.lua")

core.log("action", "[dnd3_core] weather subsystem loaded")

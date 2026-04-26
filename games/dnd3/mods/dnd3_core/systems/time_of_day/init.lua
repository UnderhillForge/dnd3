-- dnd3 Time-of-Day Subsystem bootstrap.
-- Sets up dnd3.tod namespace and loads sub-modules.
-- Weather integration hooks are called from here once weather/ is loaded.

dnd3.tod = dnd3.tod or {}

local modpath  = dnd3.modpath
local todpath  = modpath .. "/systems/time_of_day"

dofile(todpath .. "/cycle.lua")
dofile(todpath .. "/gm_control.lua")

core.log("action", "[dnd3_core] time_of_day subsystem loaded")

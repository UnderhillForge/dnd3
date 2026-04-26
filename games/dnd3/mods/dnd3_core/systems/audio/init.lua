-- dnd3 Audio Subsystem bootstrap.
-- Loaded by dnd3_core/init.lua via dofile.
-- Sets up the dnd3.audio namespace and loads sub-modules.

dnd3.audio = dnd3.audio or {}

local modpath = dnd3.modpath
local audiopath = modpath .. "/systems/audio"

dofile(audiopath .. "/emitters.lua")
dofile(audiopath .. "/streaming.lua")

core.log("action", "[dnd3_core] audio subsystem loaded")

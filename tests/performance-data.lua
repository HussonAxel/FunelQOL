-- Optional locally imported data; do not redistribute it with the tests.
local file = io.open("RareData.lua", "r")
if not file then print("SKIP: RareData.lua is not imported"); return end
file:close()
collectgarbage("collect")
local before = collectgarbage("count")
local addon = { panelText = {} }
assert(loadfile("RareData.lua"))("FunelQOL", addon)
collectgarbage("collect")
local startup = collectgarbage("count") - before
GetLocale = function() return "enUS" end
assert(loadfile("RareContent.lua"))("FunelQOL", addon)
local data = addon.GetRareData and addon.GetRareData() or addon.rareData
local zones, npcs = 0, 0
for _ in pairs(data.zones) do zones = zones + 1 end
for _ in pairs(data.npcs) do npcs = npcs + 1 end
collectgarbage("collect")
print(("PERF rare data: startup=%.1f KiB, loaded=%.1f KiB, zones=%d, npcs=%d"):format(startup, collectgarbage("count") - before, zones, npcs))
if not FUNEL_PERF_BASELINE then
    assert(startup < 2000, "Rare data allocates all tables at startup")
    assert(addon.GetRareData() == data and not addon.LoadRareData, "Data loader is retained or reloads tables")
end

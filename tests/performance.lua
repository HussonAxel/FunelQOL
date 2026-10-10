-- Run from the addon directory. Uses the smoke test's UI mock, not WoW timings.
local file = assert(io.open("tests/smoke.lua", "r"))
local source = file:read("*a"); file:close()
local boundary = assert(source:find("local core = frames[#frames]", 1, true))
local fixture = source:sub(1, boundary - 1) .. "\nreturn addon, frames, LEM\n"
local addon, frames, LEM = assert(loadstring(fixture))()
local timers = {}
C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
local function Flush()
    local callbacks = timers; timers = {}
    for _, callback in ipairs(callbacks) do callback() end
end
local function Event(event, ...)
    for _, frame in ipairs(frames) do
        if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
    end
end
Event("ADDON_LOADED", "FunelQOL"); Event("PLAYER_LOGIN"); Flush()
local layout = FunelQOLDB.panels.layouts[LEM.active]
layout.panel1.content, layout.panel2.content = "quests", "custom"
layout.panel1.questReadable, layout.panel1.questTracker = false, false
layout.panel2.customRows = { { name = "Static", valueText = "42" } }
local calls, timed, pending = {}, false, false
addon.GetPanelRows = function(settings)
    calls[settings.content] = (calls[settings.content] or 0) + 1
    if settings.content == "quests" then addon.questHasTimers = timed end
    if settings.content == "raidsets" then addon.raidUpgradePending = pending end
    local rows = {}
    for i = 1, 8 do rows[i] = { name = "Row " .. i, valueText = "42" } end
    return rows
end
local function Reset() calls = {} end
local function Count() local n = 0; for _, value in pairs(calls) do n = n + value end; return n end
local function Check(condition, message)
    if not FUNEL_PERF_BASELINE then assert(condition, message) end
end
addon.RefreshPanels(); Reset()
UIParent.scaleHook(UIParent, 1)
Check(Count() == 2, "Scale hook forwards its frame as a content filter")
Reset()
for _ = 1, 100 do Event("QUEST_LOG_UPDATE"); Event("UNIT_AURA", "player") end
local queued = #timers
Flush()
print(("PERF event burst: timers=%d, quests=%d, unrelated=%d"):format(queued, calls.quests or 0, calls.custom or 0))
Check(queued == 1 and calls.quests == 1 and not calls.custom, "Overlapping handlers render unrelated panels or enqueue duplicate refreshes")
Reset(); Event("PLAYER_MONEY"); Flush()
Check(calls.quests == 1 and not calls.custom, "Money updates redraw unrelated panels")
Reset(); Event("UPDATE_FACTION"); Flush()
Check(Count() == 0 and #timers == 0, "Unused content still schedules work")
layout.panel1.enabled = false
addon.RefreshPanels(); Reset()
Event("QUEST_LOG_UPDATE"); Event("UNIT_AURA", "player"); Flush()
print("PERF disabled quest panel: renders=" .. Count())
Check(Count() == 0, "Disabled panels still refresh on quest/aura events")
layout.panel1.enabled = true
local polling
for _, frame in ipairs(frames) do if frame.events.QUEST_POI_UPDATE then polling = frame end end
addon.RefreshPanels()
local callbacks = 0
for _ = 1, 600 do
    if polling:IsShown() then callbacks = callbacks + 1; polling.scripts.OnUpdate(polling, 1 / 60) end
end
print("PERF idle 600 frames: callbacks=" .. callbacks)
Check(callbacks == 0, "Idle polling frame remains active")
timed = true; addon.RefreshPanels(); Reset()
polling.scripts.OnUpdate(polling, 1)
print(("PERF timer tick: quests=%d, unrelated=%d"):format(calls.quests or 0, calls.custom or 0))
Check(calls.quests == 1 and not calls.custom, "Quest timer redraws unrelated panels")
timed = false
Event("QUEST_LOG_UPDATE"); Flush()
Check(not addon.questHasTimers and not polling:IsShown(), "Partial refresh leaves stale timer flags")
timed, pending = true, true
layout.panel2.content = "raidsets"
addon.RefreshPanels(); Reset()
polling.scripts.OnUpdate(polling, 1)
Check(calls.quests == 1 and calls.raidsets == 1 and addon.raidUpgradePending, "Combined quest/raid polling loses pending state")
pending, timed = false, false
addon.RefreshPanels()
Check(not polling:IsShown(), "Polling does not stop after async completion")
layout.panel2.content = "custom"
Reset()
for _ = 1, 50 do Event("QUEST_LOG_UPDATE"); Event("UI_SCALE_CHANGED") end
Check(#timers == 1, "Full and partial refreshes do not share the queue")
Flush()
Check(calls.quests == 1 and calls.custom == 1, "Full refresh is lost when merged with a partial refresh")
layout.panel1.enabled, layout.panel2.enabled = false, false
LEM.callbacks.enter(); Reset()
Event("QUEST_LOG_UPDATE"); Flush()
Check(calls.quests == 1, "Disabled panels are not refreshed while editing")
LEM.callbacks.exit()
layout.panel1.enabled, layout.panel2.enabled = true, true
layout.panel2.content = "custom"
addon.RefreshPanels()
collectgarbage("collect")
local frameCount, start = #frames, os.clock()
for _ = 1, 1000 do addon.RefreshPanels() end
print(("PERF mock 1000 full refreshes: %.2f ms; new frames=%d"):format((os.clock() - start) * 1000, #frames - frameCount))
Check(#frames == frameCount, "Steady refresh creates frames")
print("PASS: performance scenarios (mock UI; timings are not client CPU/FPS measurements).")

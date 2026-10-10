local clock, combat, scans, calls = 0, false, 0, 0
local metrics = { SessionAverageTime = 0, RecentAverageTime = 1, EncounterAverageTime = 2, PeakTime = 4,
    CountTimeOver1Ms = 5, CountTimeOver5Ms = 6, CountTimeOver10Ms = 7, CountTimeOver50Ms = 8 }
Enum = { AddOnProfilerMetric = metrics }
GetTime = function() return clock end
GetBuildInfo = function() return "12.1.0", "123", "", 120100 end
InCombatLockdown = function() return combat end
UpdateAddOnMemoryUsage = function() scans = scans + 1 end
GetAddOnMemoryUsage = function(name) assert(name == "FunelQOL"); return 1024 + clock end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
C_AddOnProfiler = {
    GetAddOnMetric = function(name, metric) assert(name == "FunelQOL"); return metric >= 5 and clock or 0.2 end,
    MeasureCall = function(fn) fn(); return { elapsedMilliseconds = 0.5, allocatedBytes = 1024 } end,
}
local addon = { db = {}, RefreshPanels = function() calls = calls + 1 end }
assert(loadfile("Performance.lua"))("FunelQOL", addon)
assert(scans == 0 and calls == 0, "Profiler performs work at startup")
addon.HandlePerformanceCommand("start repos")
addon.HandlePerformanceCommand("start duplicate")
assert(scans == 1)
clock = 60
addon.HandlePerformanceCommand("stop")
local run = addon.db.performance.runs[1]
assert(run.label == "repos" and run.duration == 60 and run.build == 120100)
assert(run.finish.metrics.CountTimeOver1Ms - run.start.metrics.CountTimeOver1Ms == 60)
addon.HandlePerformanceCommand(""); addon.HandlePerformanceCommand("report")
assert(scans == 2, "Reporting refreshes global memory statistics unnecessarily")
addon.HandlePerformanceCommand("bench 2")
assert(calls == 2 and addon.db.performance.benchmark.meanMS == 0.5 and addon.db.performance.benchmark.allocatedKB == 1)
combat = true; addon.HandlePerformanceCommand("bench 20"); assert(calls == 2)
combat = false; addon.HandlePerformanceCommand("bench 999"); assert(calls == 22)
for _ = 1, 12 do addon.HandlePerformanceCommand("start repeat"); clock = clock + 1; addon.HandlePerformanceCommand("stop") end
assert(#addon.db.performance.runs == 10, "Profiling history grows indefinitely")
C_AddOnProfiler, Enum = nil, nil
addon.HandlePerformanceCommand("start fallback"); addon.HandlePerformanceCommand("stop")
addon.HandlePerformanceCommand("bench"); assert(calls == 22)
print("PASS: on-demand profiling, native metrics/allocations, snapshots/history limit, combat guard and unavailable API fallback.")

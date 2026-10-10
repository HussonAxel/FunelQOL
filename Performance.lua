local addonName, addon = ...
-- On-demand snapshots only: no event frame, ticker or persistent hooks.
local active
local metricNames = { "SessionAverageTime", "RecentAverageTime", "EncounterAverageTime", "PeakTime",
    "CountTimeOver1Ms", "CountTimeOver5Ms", "CountTimeOver10Ms", "CountTimeOver50Ms" }
local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffFunelQOL perf|r: " .. message)
end
local function Snapshot()
    local snapshot = { time = GetTime(), metrics = {} }
    local profiler, metrics = C_AddOnProfiler, Enum and Enum.AddOnProfilerMetric
    if profiler and profiler.GetAddOnMetric and metrics then
        for _, name in ipairs(metricNames) do
            if metrics[name] then snapshot.metrics[name] = profiler.GetAddOnMetric(addonName, metrics[name]) end
        end
    end
    if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
        snapshot.memoryKB = GetAddOnMemoryUsage(addonName)
    end
    return snapshot
end
local function History()
    local db = addon.db
    if type(db.performance) ~= "table" then db.performance = {} end
    if type(db.performance.runs) ~= "table" then db.performance.runs = {} end
    return db.performance
end
local function Report(run)
    if not run then Print("Aucun test enregistré. /funelqol perf start <scénario>, puis /funelqol perf stop."); return end
    Print(("%s · %.1f s"):format(run.label, run.duration))
    if run.finish.memoryKB and run.start.memoryKB then
        Print(("Mémoire : %.1f → %.1f Kio (variation %+.1f ; GC naturel inclus)"):format(run.start.memoryKB, run.finish.memoryKB, run.finish.memoryKB - run.start.memoryKB))
    end
    local values = run.finish.metrics
    if values.SessionAverageTime then
        Print(("CPU : session %.4f ms/tick ; récent %.4f ; pic session %.3f"):format(values.SessionAverageTime, values.RecentAverageTime or 0, values.PeakTime or 0))
        Print(("Ticks durant le test >1/>5/>10/>50 ms : %d / %d / %d / %d"):format(
            (values.CountTimeOver1Ms or 0) - (run.start.metrics.CountTimeOver1Ms or 0),
            (values.CountTimeOver5Ms or 0) - (run.start.metrics.CountTimeOver5Ms or 0),
            (values.CountTimeOver10Ms or 0) - (run.start.metrics.CountTimeOver10Ms or 0),
            (values.CountTimeOver50Ms or 0) - (run.start.metrics.CountTimeOver50Ms or 0)))
    else Print("C_AddOnProfiler indisponible : mesure mémoire uniquement.") end
end
local function Bench(count)
    if InCombatLockdown() then Print("Lance le benchmark hors combat."); return end
    if not (C_AddOnProfiler and C_AddOnProfiler.MeasureCall) then Print("MeasureCall indisponible sur ce client."); return end
    count = math.max(1, math.min(20, math.floor(tonumber(count) or 5)))
    local total, peak, allocated = 0, 0, 0
    for _ = 1, count do
        local result = C_AddOnProfiler.MeasureCall(addon.RefreshPanels)
        total = total + result.elapsedMilliseconds
        peak = math.max(peak, result.elapsedMilliseconds)
        allocated = allocated + result.allocatedBytes
    end
    local result = { calls = count, meanMS = total / count, peakMS = peak, allocatedKB = allocated / count / 1024 }
    History().benchmark = result
    Print(("%d rendus complets : moyenne %.3f ms ; max %.3f ms ; allocations moyennes %.1f Kio/appel"):format(count, result.meanMS, peak, result.allocatedKB))
end
function addon.HandlePerformanceCommand(arguments)
    local command, rest = string.match(arguments or "", "^(%S+)%s*(.*)$")
    command = string.lower(command or "report")
    if command == "start" then
        if active then Print("Un test est déjà actif. Termine-le avec /funelqol perf stop."); return end
        active = { label = rest ~= "" and rest:sub(1, 80) or "scénario", start = Snapshot() }
        Print("Test démarré : " .. active.label .. ". Termine avec /funelqol perf stop.")
    elseif command == "stop" then
        if not active then Print("Aucun test actif."); return end
        active.finish = Snapshot()
        active.duration = active.finish.time - active.start.time
        active.build = GetBuildInfo and select(4, GetBuildInfo())
        local runs = History().runs
        runs[#runs + 1] = active
        if #runs > 10 then table.remove(runs, 1) end
        Report(active); active = nil
    elseif command == "bench" then Bench(rest)
    elseif command == "report" then
        local runs = History().runs
        Report(runs[#runs])
    else Print("/funelqol perf start <scénario> | stop | report | bench [1-20]") end
end

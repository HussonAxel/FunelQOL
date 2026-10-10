-- Reuse the stateful UI fixture, then exercise the real RefineUI/FunelQOL seam.
local file = assert(io.open("tests/smoke.lua", "r"))
local fixture = file:read("*a"); file:close()
assert(load(fixture .. [[
local timers = {}
C_Timer = { After = function(_, fn) timers[#timers+1] = fn end }
function LibStub() return LEM end
function methods:GetName() return self == first and "FirstTracker" or self == second and "SecondTracker" or "Fixture" end
function methods:GetPoint() return table.unpack(self.point or {}) end
function hooksecurefunc(frame, key, callback)
    local original = frame[key]
    frame[key] = function(self, ...) original(self, ...); callback(self, ...) end
end
LEM.frameSettings, LEM.frameSelections = LEM.settings, {}
local anchors = {}
local refine = { DB = {} }
function refine:RegisterModule() return anchors end
function refine:Print() end
assert(loadfile("../RefineUI/Core/EditModeAnchors.lua"))("RefineUI", refine)
_G.RefineUI = refine
FunelQOLDB.panels.layouts[LEM.active].panel1.anchorTarget = "screen"
FunelQOLDB.panels.layouts[LEM.active].panel2.anchorTarget = "screen"
persistedAddon.RefreshPanels()
local firstID = anchors:RegisterFrame(first, LEM)
local secondID = anchors:RegisterFrame(second, LEM, nil, function() end)
assert(anchors:Set(firstID, "target", secondID))
assert(first.point[2] == second)
-- Collapse redraws used to apply the obsolete screen position until the next timer.
for i = 1, 10 do
    first.header.scripts.OnClick(first.header)
    assert(first.point[2] == second, "Click teleports globally anchored tracker to its old screen position before the next frame")
end
persistedAddon.RefreshPanels()
assert(first.point[2] == second, "Refresh temporarily replaces the global link")
assert(anchors:OwnsPosition(first) and not anchors:OwnsPosition(second))
second:StartMoving()
second:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 400, -200)
local movingPoint = second.point
persistedAddon.RefreshPanels()
anchors:Refresh()
assert(second.point == movingPoint, "global refresh resets moving tracker target")
assert(first.point[2] == second, "global follower loses its moving target")
second:StopMovingOrSizing()
LEM.positions[second](second, LEM.active, "TOPLEFT", 400, -200)
anchors:Refresh()
assert(first.point[2] == second, "global follower loses link after drag stop")
print("PASS: global tracker anchor stays active synchronously through header clicks and redraws.")
]]))()

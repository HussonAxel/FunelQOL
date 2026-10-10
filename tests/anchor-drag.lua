local file = assert(io.open("tests/smoke.lua", "r"))
local fixture = file:read("*a"); file:close()
assert(load(fixture .. [[
local settings = FunelQOLDB.panels.layouts[LEM.active]
settings.panel1.anchorTarget = "panel2"
settings.panel2.anchorTarget = "screen"
persistedAddon.RefreshPanels()
second:StartMoving()
second:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 400, -200)
local movingPoint = second.point
persistedAddon.RefreshPanels()
assert(second.point == movingPoint, "redraw resets the dragged anchor target and its followers")
assert(first.point[2] == second, "follower detached during target drag")
second:StopMovingOrSizing()
LEM.positions[second](second, LEM.active, "TOPLEFT", 400, -200)
assert(first.point[2] == second, "follower detached after target drag")
print("PASS: panel redraw preserves moving targets and follower links during and after drag.")
]]))()

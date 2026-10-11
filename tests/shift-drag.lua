local file = assert(io.open("tests/smoke.lua", "r"))
local fixture = file:read("*a"); file:close()
assert(load(fixture .. [[
(function()
local addon = persistedAddon
LEM.active = "Modern"
LEM.callbacks.layout("Modern")
LEM.callbacks.exit()
local layout = FunelQOLDB.panels.layouts.Modern
local a, b = addon.panels[1], addon.panels[2]
layout.panel1.enabled, layout.panel2.enabled = true, true
layout.panel1.anchorTarget, layout.panel2.anchorTarget = "screen", "screen"
addon.RefreshPanels()
local shift = false
function IsShiftKeyDown() return shift end
local function Start()
    a.header.scripts.OnMouseDown(a.header, "LeftButton")
    a.header.scripts.OnDragStart(a.header, "LeftButton")
end
Start()
assert(not a.moving, "ordinary drag moves a tracker")
shift, combat = true, true
Start()
assert(not a.moving, "shortcut drag starts in combat")
combat = false
local collapsed = layout.panel1.collapsed
a.header.scripts.OnClick(a.header, "LeftButton")
assert(layout.panel1.collapsed == collapsed, "shift click folds the tracker")

-- Coordinates are supplied in frame units, as the real API does.
local left, top = 0, 0
function a:GetLeft() return left / (self:GetEffectiveScale() / UIParent:GetEffectiveScale()) end
function a:GetTop() return top / (self:GetEffectiveScale() / UIParent:GetEffectiveScale()) end
function b:GetLeft() return 500 / (self:GetEffectiveScale() / UIParent:GetEffectiveScale()) end
function b:GetTop() return 600 / (self:GetEffectiveScale() / UIParent:GetEffectiveScale()) end
local function Drop(x, y)
    Start(); assert(a.moving and a.movable)
    left, top = x, y
    a.scripts.OnUpdate(a, 0.04)
    local preview = addon.anchorPreview
    local candidate = preview and preview:IsShown() and preview.candidate
    -- Modifier release before mouse release must still complete the drag.
    shift = false
    a.header.scripts.OnDragStop(a.header)
    assert(not a.moving and not a.shortcutDrag)
    assert(not a.scripts.OnUpdate, "drag update persists after release")
    assert(not preview or not preview:IsShown(), "preview persists after release")
    if candidate then
        assert(layout.panel1.anchorTarget == candidate.target.definition.id)
        assert(layout.panel1.anchorSide == candidate.side and layout.panel1.anchorAlign == candidate.align,
            "release differs from preview")
    end
    a.header.scripts.OnClick(a.header, "LeftButton")
    assert(layout.panel1.collapsed == collapsed, "drag release folds the tracker")
    shift = true
end
for _, scale in ipairs({ 0.7, 1, 1.5 }) do
    layout.panel1.scale = scale
    addon.RefreshPanels()
    local w = a:GetWidth() * scale
    local h = a:GetHeight() * scale
    local bw = b:GetWidth() * (b:GetEffectiveScale() / UIParent:GetEffectiveScale())
    local bh = b:GetHeight() * (b:GetEffectiveScale() / UIParent:GetEffectiveScale())
    for _, side in ipairs({ "BOTTOM", "TOP", "LEFT", "RIGHT" }) do
        for index, align in ipairs({ "start", "center", "finish" }) do
            local fraction = (index - 1) / 2
            local x, y
            if side == "BOTTOM" or side == "TOP" then
                x = 500 + (bw - w) * fraction
                y = side == "BOTTOM" and 600 - bh - 8 or 600 + h + 8
            else
                x = side == "LEFT" and 500 - w - 8 or 500 + bw + 8
                y = 600 - (bh - h) * fraction
            end
            Drop(x + 1, y + 1)
            assert(layout.panel1.anchorTarget == "panel2", "nearby tracker did not snap")
            assert(layout.panel1.anchorSide == side and layout.panel1.anchorAlign == align)
            assert(layout.panel1.anchorGap == 8 and a.point[2] == b)
        end
    end
end
-- The wider capture zone gives visible feedback before the old 20-unit limit.
layout.panel1.scale = 1
addon.RefreshPanels()
left, top = 500 + b:GetWidth() * (b:GetEffectiveScale() / UIParent:GetEffectiveScale()) + 8 + 45, 600
Start()
a.scripts.OnUpdate(a, 0.04)
local preview = assert(addon.anchorPreview)
assert(preview:IsShown() and preview.candidate.side == "RIGHT", "wide capture zone has no feedback")
assert(preview.point[4] == left - 45 and preview.point[5] == top, "ghost does not show snapped position")
assert(preview.label:GetText():find("Relâchez pour ancrer", 1, true))
left = left + 100
a.scripts.OnUpdate(a, 0.04)
assert(not preview:IsShown(), "preview stays visible outside capture zone")
a.header.scripts.OnDragStop(a.header)
Drop(50, 50)
assert(layout.panel1.anchorTarget == "screen", "distant drop remains linked")
local x, y = layout.panel1.x, layout.panel1.y
LEM.callbacks.layout("Classic")
LEM.callbacks.layout("Modern")
assert(layout.panel1.x == x and layout.panel1.y == y, "position lost on layout switch")
layout.panel2.anchorTarget = "panel1"
Drop(501, 600 - b:GetHeight() * (b:GetEffectiveScale() / UIParent:GetEffectiveScale()) - 7)
assert(layout.panel1.anchorTarget == "screen", "snap creates a cycle")
layout.panel2.anchorTarget = "screen"
b:Hide()
Drop(501, 600 - b:GetHeight() * (b:GetEffectiveScale() / UIParent:GetEffectiveScale()) - 7)
assert(layout.panel1.anchorTarget == "screen", "snap targets a hidden tracker")
b:Show()
Start(); combat = true
a.scripts.OnUpdate(a, 0.04)
assert(not preview:IsShown(), "combat shows an anchor candidate")
a.header.scripts.OnEvent(a.header, "PLAYER_REGEN_DISABLED")
assert(not a.moving and layout.panel1.anchorTarget == "screen")
combat = false
-- The LibEditMode stop/normalize/callback sequence also keeps a new link.
LEM.callbacks.enter()
a:StartMoving()
left, top = 500, 600 - b:GetHeight() * (b:GetEffectiveScale() / UIParent:GetEffectiveScale()) - 8
a:StopMovingOrSizing()
LEM.positions[a](a, "Modern", "TOPLEFT", 30, -40)
assert(layout.panel1.anchorTarget == "panel2" and a.point[2] == b)
LEM.callbacks.create("Drag copy", nil, "Modern")
assert(FunelQOLDB.panels.layouts["Drag copy"].panel1.anchorTarget == "panel2")
assert(FunelQOLDB.panels.layouts["Drag copy"].panel1 ~= layout.panel1)
print("PASS: shift dragging, scaled edge snapping, wide capture zone, live preview/release agreement, cleanup, cycle/hidden/combat guards and Edit Mode persistence.")
end)()
]]))()

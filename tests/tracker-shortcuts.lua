local file = assert(io.open("tests/smoke.lua", "r"))
local fixture = file:read("*a"); file:close()
assert(load(fixture .. [[
(function()
local addon = persistedAddon
LEM.callbacks.exit()
local ctrl = true
function IsControlKeyDown() return ctrl end
local base = addon.panels[1]
local layout = FunelQOLDB.panels.layouts[LEM.active]
local count = #addon.panels
local collapsed, content = layout.panel1.collapsed, layout.panel1.content
local function Click(frame, button)
    frame.header.scripts.OnMouseDown(frame.header, button)
    frame.header.scripts.OnClick(frame.header, button)
end
combat = true
Click(base, "LeftButton"); Click(base, "RightButton")
assert(#addon.panels == count, "combat shortcuts changed trackers")
combat = false
Click(base, "LeftButton")
assert(#addon.panels == count + 1 and addon.panelDB.panelCount == count + 1)
local child = addon.panels[count + 1]
local settings = layout[child.definition.id]
assert(settings.anchorTarget == base.definition.id and settings.anchorSide == "RIGHT")
assert(settings.anchorAlign == "start" and settings.anchorGap == 8 and settings.anchorOffset == 0)
assert(child.point[2] == base, "created tracker is not anchored to its base")
assert(layout.panel1.collapsed == collapsed and layout.panel1.content == content)
LEM.callbacks.create("Shortcut copy", nil, LEM.active)
assert(FunelQOLDB.panels.layouts["Shortcut copy"][child.definition.id].anchorTarget == base.definition.id)
Click(child, "RightButton")
assert(#addon.panels == count and not layout[child.definition.id])
Click(base, "LeftButton")
local replacement = addon.panels[count + 1]
assert(layout[replacement.definition.id].anchorTarget == base.definition.id, "reused tracker lost link")
-- Delete a base in a middle slot: its follower survives as a free tracker.
local second = addon.panels[2]
Click(second, "LeftButton")
local follower = addon.panels[#addon.panels]
local followerSettings = layout[follower.definition.id]
Click(second, "RightButton")
assert(layout.panel2 == followerSettings and followerSettings.anchorTarget == "screen")
assert(addon.panels[2].point[2] == UIParent, "deleted base leaves stale frame anchor")
while #addon.panels > 1 do Click(addon.panels[#addon.panels], "RightButton") end
Click(base, "RightButton")
assert(#addon.panels == 1, "shortcut deleted the final tracker")
ctrl = false
collapsed = layout.panel1.collapsed
Click(base, "LeftButton")
assert(layout.panel1.collapsed ~= collapsed, "ordinary click no longer folds")
print("PASS: Ctrl creation anchored to clicked base, deletion, slot reuse, follower detachment, layout copy and combat/last-tracker guards.")
end)()
]]))()

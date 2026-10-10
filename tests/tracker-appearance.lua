local file = assert(io.open("tests/smoke.lua", "r"))
local fixture = file:read("*a"); file:close()
assert(load(fixture .. [=[
do
    local first, second = persistedAddon.panels[1], persistedAddon.panels[2]
    local layout = FunelQOLDB.panels.layouts[LEM.active]
    SetSetting(first, "content", "weekly")
    SetSetting(second, "content", "rares")
    local originalRows = persistedAddon.GetPanelRows
    persistedAddon.GetPanelRows = function(settings)
        return {
            { name = "Short name", valueText = "1 / 3", icon = settings.content == "weekly" and 134400 or nil },
            { name = "A much longer name", valueText = "15 / 39" },
        }
    end
    for _, spec in ipairs({ {"width", 300}, {"scale", 1.1}, {"fontSize", 14}, {"rowHeight", 28}, {"style", "refine"}, {"opacity", .7} }) do
        SetSetting(first, spec[1], spec[2])
        assert(layout.panel2[spec[1]] == layout.panel1[spec[1]], "Visual setting is not shared: " .. spec[1])
    end
    assert(first.width == second.width and first.scale == second.scale and first.header.height == second.header.height)
    for index = 1, 2 do
        local a, b = first.rows[index], second.rows[index]
        assert(a.height == b.height and a.label.fontSize == b.label.fontSize and a.label.font == b.label.font)
        assert(a.label.width == b.label.width and a.value.width == b.value.width, "Content changes the column widths")
        assert(a.separator.height == b.separator.height)
    end
    assert(first.rows[1].label.width == first.rows[2].label.width, "Rows do not share the label column")
    assert(layout.panel1.content == "weekly" and layout.panel2.content == "rares", "Appearance changes content")
    SetSetting(second, "fontSize", 12)
    assert(layout.panel1.fontSize == 12 and first.rows[1].label.fontSize == 12, "Appearance sync is not bidirectional")
    local third = persistedAddon.panels[persistedAddon.AddPanel()]
    local thirdSettings = layout[third.definition.id]
    for _, key in ipairs({"width", "scale", "fontSize", "rowHeight", "style", "opacity"}) do
        assert(thirdSettings[key] == layout.panel1[key], "New tracker has a different appearance: " .. key)
    end
    persistedAddon.GetPanelRows = originalRows
    -- Previously independent saved profiles are aligned on load without
    -- changing which content they track or where they are anchored.
    layout.panel2.width, layout.panel2.fontSize, layout.panel2.style = 180, 18, "pixels"
    local position = layout.panel2.x
    FunelQOLDB.panels.appearanceRevision = nil
    local reloaded = {}
    for key, value in pairs(persistedAddon) do reloaded[key] = value end
    assert(loadfile("Panels.lua"))("FunelQOL", reloaded)
    reloaded.InitializePanels()
    assert(layout.panel2.width == layout.panel1.width and layout.panel2.fontSize == layout.panel1.fontSize and layout.panel2.style == layout.panel1.style)
    assert(layout.panel2.content == "rares" and layout.panel2.x == position)
    assert(FunelQOLDB.panels.appearanceRevision == 1)
    print("PASS: shared tracker appearance, uniform columns with/without icons, typography, bidirectional settings and new tracker inheritance.")
end
]=]))()

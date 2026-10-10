local file = assert(io.open("tests/smoke.lua", "r"))
local fixture = file:read("*a"); file:close()
assert(load(fixture .. [=[
do
    local panel = persistedAddon.panels[1]
    physicalHeight = 1080
    UIParent:SetScale(768 / physicalHeight)
    local originalRows = persistedAddon.GetPanelRows
    persistedAddon.GetPanelRows = function()
        return { {name="Currency", valueText="1 / 3", icon=134400}, {name="No icon", valueText="1 / 3"} }
    end
    SetSetting(panel, "content", "weekly")
    SetSetting(panel, "scale", 1)
    SetSetting(panel, "rowHeight", 22)
    SetSetting(panel, "fontSize", 11)
    local icon = panel.rows[1].icon
    assert(icon.width >= 18 and icon.width == icon.height, "Tracker icon is too small or distorted")
    assert(icon.texCoords[1] == 4 / 64 and icon.texCoords[2] == 60 / 64, "Icon crop does not use whole source texels")
    for _, scale in ipairs({.7,1,1.5}) do
        SetSetting(panel, "scale", scale)
        for _, height in ipairs({22,23,27,34}) do
            SetSetting(panel, "rowHeight", height)
            local row = panel.rows[1]
            local pixel = (768 / physicalHeight) / panel:GetEffectiveScale()
            OnGrid(row.icon.width, pixel); OnGrid(row.icon.height, pixel)
            assert(row.icon.point[1] == "TOPRIGHT")
            OnGrid(row.icon.point[4], pixel); OnGrid(row.icon.point[5], pixel)
            assert(row.icon.width == row.icon.height and row.icon.height <= row.height - 2 * pixel)
            assert(row.label.width == panel.rows[2].label.width, "Larger icons break the shared columns")
        end
    end
    persistedAddon.GetPanelRows = originalRows
    print("PASS: larger square tracker icons, exact source crop, pixel-aligned placement and shared columns across scales and odd/even row heights.")
end
]=]))()

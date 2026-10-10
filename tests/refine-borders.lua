local file = assert(io.open("tests/smoke.lua", "r"))
local fixture = file:read("*a"); file:close()
assert(load(fixture .. [=[
do
    local panel = persistedAddon.panels[1]
    SetSetting(panel, "content", "weekly")
    local originalRows = persistedAddon.GetPanelRows
    persistedAddon.GetPanelRows = function()
        return {
            { name = "First", valueText = "1 / 3" },
            { name = "Second", valueText = "2 / 3" },
        }
    end
    SetSetting(panel, "style", "refine")
    local separator = panel.rows[1].separator
    assert(separator.texture == persistedAddon.media.refine.border, "Refine separator is a generic solid line")
    assert(#separator.texCoords == 8 and separator.height > 1, "Refine border edge was not sampled at its native thickness")
    assert(separator.texCoords[1] == 66 / 256 and separator.texCoords[3] == 94 / 256, "Wrong Refine border atlas cell")
    assert(math.abs(separator.point[3] + separator.height / 2) < .0001, "Refine separator is not centered on its boundary")
    SetSetting(panel, "content", "rares")
    SetSetting(panel, "questHeight", 150)
    persistedAddon.GetPanelRows = function()
        local rows = {}
        for index = 1, 12 do rows[index] = { name = "Rare " .. index, valueText = "1 / 3" } end
        rows[1].rewards = {
            { icon = 134400, itemID = 1, obtained = false },
            { icon = 134400, itemID = 2, obtained = true },
        }
        return rows
    end
    persistedAddon.RefreshPanels()
    assert(panel.scrollLine.shown and panel.scrollLine.texture == persistedAddon.media.refine.border and #panel.scrollLine.texCoords == 8, "Scroll boundary uses a generic line")
    local reward = panel.rows[1].rewards[1]
    assert(reward.border.shown and reward.border.backdrop.edgeFile == persistedAddon.media.refine.border, "Rare reward uses generic border strips")
    for _, edge in ipairs(reward.edges) do assert(not edge.shown, "Solid reward borders overlap the texture") end
    reward.isHovered = true; reward:PaintEdges()
    assert(reward.texturedBorder and not reward.styled, "Textured border changes reward interaction semantics")
    SetSetting(panel, "style", "pixels")
    assert(separator.texture == persistedAddon.media.borders.pixels.separatorHorizontal and #separator.texCoords == 4)
    assert(not reward.border.shown and not reward.texturedBorder)
    for _, edge in ipairs(reward.edges) do assert(edge.shown, "Switching away from Refine does not restore reward edges") end
    SetSetting(panel, "style", "blizzard")
    assert(separator.vertexColor[1] == 1 and separator.height <= 2)
    persistedAddon.GetPanelRows = originalRows
    print("PASS: Refine row/scroll separators and reward frames use border art, centered atlas sampling and complete restoration when switching themes.")
end
]=]))()

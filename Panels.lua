local addonName, addon = ...
local LEM = addon.LibEditMode
local text = addon.panelText
local panels = {}
addon.panels = panels

local definitions = {
    { id = "panel1", title = text.panel .. " 1", x = -32, y = -220 },
    { id = "panel2", title = text.panel .. " 2", x = -312, y = -220 },
}

local styles = {
    blizzard = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", fill = "Interface\\TargetingFrame\\UI-StatusBar", edgeSize = 8 },
    ayije = { edgeFile = addon.media.ayije.borders.Ayije_Thin.edgeFile, fill = addon.media.ayije.statusbars.Ayije_light, edgeSize = 16 },
    pixels = { edgeFile = addon.media.borders.pixels.edgeFile, fill = addon.media.textures.pixelsFill, edgeSize = 16 },
}
local activeLayout = "Modern"
local editing = false

local function Copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, entry in pairs(value) do copy[key] = Copy(entry) end
    return copy
end

local function Settings(id, layoutName)
    local layouts = addon.characterDB.layouts
    layoutName = layoutName or activeLayout
    if type(layouts[layoutName]) ~= "table" then layouts[layoutName] = {} end
    if type(layouts[layoutName][id]) ~= "table" then layouts[layoutName][id] = {} end
    local settings = layouts[layoutName][id]
    local definition
    for _, entry in ipairs(definitions) do if entry.id == id then definition = entry; break end end
    local defaults = {
        point = "TOPRIGHT", x = definition.x, y = definition.y,
        title = definition.title, width = 260, scale = 1, enabled = true,
        collapsed = false, style = "blizzard", opacity = 0.94,
        fontSize = 11, rowHeight = 22, rowCount = 3, showBars = true,
    }
    for key, value in pairs(defaults) do
        if type(settings[key]) ~= type(value) then settings[key] = value end
    end
    if not styles[settings.style] then settings.style = "blizzard" end
    local anchors = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }
    if not anchors[settings.point] then settings.point = "TOPRIGHT" end
    settings.width = math.max(180, math.min(420, settings.width))
    settings.scale = math.max(0.7, math.min(1.5, settings.scale))
    settings.opacity = math.max(0.2, math.min(1, settings.opacity))
    settings.fontSize = math.floor(math.max(10, math.min(18, settings.fontSize)))
    settings.rowHeight = math.floor(math.max(22, math.min(34, settings.rowHeight)))
    settings.rowCount = math.floor(math.max(1, math.min(8, settings.rowCount)))
    return settings
end

local function SetBackdrop(frame, style, opacity)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = style.edgeFile, tile = false, edgeSize = style.edgeSize, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    frame:SetBackdropColor(0.035, 0.035, 0.035, opacity)
    frame:SetBackdropBorderColor(0.38, 0.35, 0.29, 1)
end

local function CreateRow(panel)
    local row = CreateFrame("Button", nil, panel.content, "BackdropTemplate")
    row:SetHeight(22)
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetPoint("TOPLEFT", 3, -3)
    row.bar:SetPoint("BOTTOMRIGHT", -3, 3)
    row.bar:SetFrameLevel(row:GetFrameLevel())
    row.bar:SetStatusBarColor(0.12, 0.42, 0.62, 0.65)
    -- Text and icons belong to an overlay above the statusbar child.
    local overlay = CreateFrame("Frame", nil, row)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(row.bar:GetFrameLevel() + 1)
    row.icon = overlay:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", 4, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.label:SetPoint("LEFT", 24, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.value = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.value:SetPoint("RIGHT", -6, 0)
    row.value:SetJustifyH("RIGHT")
    row:SetScript("OnEnter", function(self)
        local data = self.data
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(data.name, 1, 0.82, 0)
        GameTooltip:AddLine(text.preview, 1, 1, 1)
        GameTooltip:Show()
        self:SetBackdropBorderColor(0.85, 0.72, 0.38, 1)
    end)
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self:SetBackdropBorderColor(0.38, 0.35, 0.29, 1)
    end)
    return row
end

local function Render(panel)
    local settings = Settings(panel.definition.id)
    local style = styles[settings.style]
    panel:SetScale(settings.scale)
    panel:SetWidth(settings.width)
    SetBackdrop(panel.header, style, settings.opacity)
    panel.title:SetText(settings.title)
    panel.title:SetWidth(settings.width - 40)
    panel.title:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
    panel.editModeName = "FunelQOL · " .. settings.title
    panel.arrow:SetText(settings.collapsed and "+" or "-")
    local data = addon.GetPreviewRows(settings.rowCount)
    for index, entry in ipairs(data) do
        local row = panel.rows[index]
        if not row then row = CreateRow(panel); panel.rows[index] = row end
        row.data = entry
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * (settings.rowHeight + 3))
        row:SetWidth(settings.width)
        row:SetHeight(settings.rowHeight)
        SetBackdrop(row, style, settings.opacity)
        row.label:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
        row.value:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
        row.bar:SetStatusBarTexture(style.fill)
        row.bar:SetMinMaxValues(0, math.max(1, entry.maximum or 0))
        row.bar:SetValue(math.min(entry.value or 0, math.max(1, entry.maximum or 0)))
        row.bar:SetShown(settings.showBars and (entry.maximum or 0) > 0)
        row.icon:SetTexture(entry.icon)
        row.icon:SetShown(entry.icon ~= nil)
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", entry.icon and 24 or 6, 0)
        row.value:SetText(entry.valueText or "")
        local valueWidth = math.min(settings.width * 0.48, row.value:GetStringWidth())
        row.value:SetWidth(valueWidth)
        row.label:SetWidth(math.max(30, settings.width - valueWidth - (entry.icon and 36 or 18)))
        row.label:SetText(entry.name)
        row:Show()
    end
    for index = #data + 1, #panel.rows do panel.rows[index]:Hide() end
    panel.content:SetShown(not settings.collapsed)
    panel:SetHeight(settings.collapsed and 26 or (29 + #data * (settings.rowHeight + 3)))
    panel:SetShown(editing or settings.enabled)
end

function addon.RefreshPanels()
    for _, panel in ipairs(panels) do Render(panel) end
end

function addon.SetPanelTitle(index, title)
    local panel = panels[index]
    if not panel then return end
    Settings(panel.definition.id).title = title
    Render(panel)
end

local function ApplyLayout(layoutName)
    activeLayout = layoutName or LEM:GetActiveLayoutName() or "Modern"
    for _, panel in ipairs(panels) do
        local settings = Settings(panel.definition.id)
        panel:ClearAllPoints()
        panel:SetPoint(settings.point, UIParent, settings.point, settings.x, settings.y)
    end
    addon.RefreshPanels()
end

local function AddSettings(panel)
    local id = panel.definition.id
    local controls = {}
    for _, spec in ipairs({
        { key = "enabled", label = text.enabled, kind = LEM.SettingType.Checkbox, default = true },
        { key = "collapsed", label = text.collapsed, kind = LEM.SettingType.Checkbox, default = false },
        { key = "width", label = text.width, kind = LEM.SettingType.Slider, default = 260, min = 180, max = 420, step = 10 },
        { key = "scale", label = text.scale, kind = LEM.SettingType.Slider, default = 1, min = 0.7, max = 1.5, step = 0.05 },
        { key = "style", label = text.style, kind = LEM.SettingType.Dropdown, default = "blizzard" },
        { key = "opacity", label = text.opacity, kind = LEM.SettingType.Slider, default = 0.94, min = 0.2, max = 1, step = 0.02 },
        { key = "fontSize", label = text.fontSize, kind = LEM.SettingType.Slider, default = 11, min = 10, max = 18, step = 1 },
        { key = "rowHeight", label = text.rowHeight, kind = LEM.SettingType.Slider, default = 22, min = 22, max = 34, step = 1 },
        { key = "rowCount", label = text.rowCount, kind = LEM.SettingType.Slider, default = 3, min = 1, max = 8, step = 1 },
        { key = "showBars", label = text.showBars, kind = LEM.SettingType.Checkbox, default = true },
    }) do
        local key = spec.key
        controls[#controls + 1] = {
            name = spec.label, kind = spec.kind, default = spec.default,
            minValue = spec.min, maxValue = spec.max, valueStep = spec.step,
            values = key == "style" and { { text = "Blizzard", value = "blizzard" }, { text = "Ayije", value = "ayije" }, { text = "Pixels", value = "pixels" } } or nil,
            get = function(layoutName) return Settings(id, layoutName)[key] end,
            set = function(layoutName, value)
                Settings(id, layoutName)[key] = value
                Render(panel)
            end,
        }
    end
    LEM:AddFrameSettings(panel, controls)
end

function addon.InitializePanels()
    if #panels > 0 then return end
    if type(FunelQOLCharDB) ~= "table" then FunelQOLCharDB = {} end
    addon.characterDB = FunelQOLCharDB
    if type(FunelQOLCharDB.layouts) ~= "table" then FunelQOLCharDB.layouts = {} end

    LEM:RegisterCallback("layout", ApplyLayout)
    LEM:RegisterCallback("enter", function() editing = true; addon.RefreshPanels() end)
    LEM:RegisterCallback("exit", function() editing = false; addon.RefreshPanels() end)
    LEM:RegisterCallback("create", function(name, _, sourceName)
        if sourceName and FunelQOLCharDB.layouts[sourceName] then
            FunelQOLCharDB.layouts[name] = Copy(FunelQOLCharDB.layouts[sourceName])
        end
    end)
    LEM:RegisterCallback("rename", function(oldName, newName)
        FunelQOLCharDB.layouts[newName] = FunelQOLCharDB.layouts[oldName]
        FunelQOLCharDB.layouts[oldName] = nil
    end)
    LEM:RegisterCallback("delete", function(name) FunelQOLCharDB.layouts[name] = nil end)

    for _, definition in ipairs(definitions) do
        local panel = CreateFrame("Frame", addonName .. definition.id .. "Panel", UIParent)
        panel.definition, panel.rows = definition, {}
        panel:SetClampedToScreen(true)
        panel:SetFrameStrata("MEDIUM")
        panel:SetSize(260, 26)
        panel.content = CreateFrame("Frame", nil, panel)
        panel.content:SetPoint("TOPLEFT", 0, -29)
        panel.content:SetPoint("TOPRIGHT", 0, -29)
        panel.content:SetHeight(1)
        panel.header = CreateFrame("Button", nil, panel, "BackdropTemplate")
        panel.header:SetPoint("TOPLEFT")
        panel.header:SetPoint("TOPRIGHT")
        panel.header:SetHeight(26)
        panel.title = panel.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        panel.title:SetPoint("CENTER", -8, 0)
        panel.title:SetWordWrap(false)
        panel.title:SetText(definition.title)
        panel.arrow = panel.header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        panel.arrow:SetPoint("RIGHT", -9, 0)
        panel.arrow:SetTextColor(0.25, 0.9, 0.25)
        panel.header:SetScript("OnClick", function()
            if editing then return end
            local settings = Settings(definition.id)
            settings.collapsed = not settings.collapsed
            Render(panel)
        end)
        panel.header:SetScript("OnEnter", function() panel.title:SetTextColor(1, 1, 1) end)
        panel.header:SetScript("OnLeave", function() panel.title:SetTextColor(1, 0.82, 0) end)
        panels[#panels + 1] = panel
        local default = { point = "TOPRIGHT", x = definition.x, y = definition.y }
        LEM:AddFrame(panel, function(_, layoutName, point, x, y)
            local settings = Settings(definition.id, layoutName)
            settings.point, settings.x, settings.y = point, x, y
        end, default)
        AddSettings(panel)
    end
    ApplyLayout(LEM:GetActiveLayoutName())
end

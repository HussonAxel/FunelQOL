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
    ayije = { edgeFile = addon.media.ayije.borders.Ayije_Thin.edgeFile, fill = addon.media.ayije.statusbars.Ayije_light, edgeSize = 16, centered = true, inkInset = 9 / 28 },
    pixels = { edgeFile = addon.media.borders.pixels.edgeFile, fill = addon.media.textures.pixelsFill, edgeSize = 16, centered = true, inkInset = 10 / 28 },
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
        fontSize = 11, rowHeight = 22, rowCount = 3, showBars = true, content = "preview",
        questReadable = true, questAuto = true, questAll = true, questHeight = 400, questLimit = 3, questObjectives = true, questDetails = true, questColors = true,
    }
    for key, value in pairs(defaults) do
        if type(settings[key]) ~= type(value) then settings[key] = value end
    end
    local validContent = false
    for _, kind in ipairs(addon.contentTypes) do if settings.content == kind.value then validContent = true end end
    if not validContent then settings.content = "preview" end
    if not styles[settings.style] then settings.style = "blizzard" end
    local anchors = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }
    if not anchors[settings.point] then settings.point = "TOPRIGHT" end
    settings.width = math.max(180, math.min(420, settings.width))
    settings.scale = math.max(0.7, math.min(1.5, settings.scale))
    settings.opacity = math.max(0.2, math.min(1, settings.opacity))
    settings.fontSize = math.floor(math.max(10, math.min(18, settings.fontSize)))
    settings.rowHeight = math.floor(math.max(22, math.min(34, settings.rowHeight)))
    settings.rowCount = math.floor(math.max(1, math.min(8, settings.rowCount)))
    settings.questHeight = math.floor(math.max(150, math.min(800, settings.questHeight)))
    settings.questLimit = math.floor(math.max(1, math.min(8, settings.questLimit)))
    return settings
end

local function PixelUnit(frame)
    local _, height = GetPhysicalScreenSize()
    height = height and height > 0 and height or 1080
    return (768 / height) / frame:GetEffectiveScale()
end

local function Snap(value, pixel)
    return math.floor(value / pixel + 0.5 + 0.001) * pixel
end

local function DisableTextureSnapping(texture)
    if texture and texture.SetSnapToPixelGrid then
        texture:SetSnapToPixelGrid(false)
        texture:SetTexelSnappingBias(0)
    end
end

local defaultBorderColor = { 0.38, 0.35, 0.29, 1 }
local function PaintBorder(frame)
    local color = frame.normalBorderColor or defaultBorderColor
    if frame.isHovered then
        if color == defaultBorderColor then color = { 0.85, 0.72, 0.38, 1 }
        else color = { math.min(1, color[1] + 0.2), math.min(1, color[2] + 0.2), math.min(1, color[3] + 0.2), color[4] } end
    end
    frame.border:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
end

local function SetBackdrop(frame, style, opacity, pixel, contentLevel, color)
    if not frame.background then
        frame.background = frame:CreateTexture(nil, "BACKGROUND")
        frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.border:EnableMouse(false)
    end
    -- Content occupies the host rect. Only the edge art extends outside it.
    local inset = style.centered and 0 or Snap(3, pixel)
    frame.background:ClearAllPoints()
    frame.background:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    frame.background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    frame.background:SetColorTexture(0.035, 0.035, 0.035, opacity)
    DisableTextureSnapping(frame.background)
    local reach = style.centered and Snap(style.edgeSize / 2, pixel) or 0
    frame.border:ClearAllPoints()
    -- Snap one positive reach and mirror it: rounding +/- half pixels separately is asymmetric.
    frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -reach, reach)
    frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", reach, -reach)
    frame.border:SetFrameLevel((contentLevel or frame:GetFrameLevel()) + 2)
    frame.border:SetBackdrop({ edgeFile = style.edgeFile, edgeSize = style.edgeSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    frame.normalBorderColor = color or defaultBorderColor
    PaintBorder(frame)
    for _, region in ipairs({ frame.border:GetRegions() }) do DisableTextureSnapping(region) end
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
    row.value:SetWordWrap(false)
    row.meta = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.meta:SetJustifyH("LEFT")
    row.meta:SetWordWrap(true)
    row:SetScript("OnEnter", function(self)
        local data = self.data
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        if data.questID then
            GameTooltip:SetText(data.questTitle, 1, 0.82, 0)
            if data.questDetails and data.questDetails ~= "" then GameTooltip:AddLine(data.questDetails, 0.6, 0.8, 1, true) end
            if data.questProgressText then GameTooltip:AddLine(text.questProgress .. ": " .. data.questProgressText, 1, 1, 1) end
            for _, objective in ipairs(data.objectives or {}) do
                GameTooltip:AddLine(objective.text, objective.finished and 0.3 or 1, 1, objective.finished and 0.3 or 1, true)
            end
        elseif data.currencyID then
            GameTooltip:SetCurrencyByID(data.currencyID)
        elseif data.spellID then
            GameTooltip:SetSpellByID(data.spellID)
        else
            GameTooltip:SetText(data.name, 1, 0.82, 0)
            if data.valueText and data.valueText ~= "" then GameTooltip:AddLine(data.valueText, 1, 1, 1) end
        end
        GameTooltip:Show()
        self.isHovered = true
        PaintBorder(self)
    end)
    row:SetScript("OnClick", function(self)
        if not editing and self.data.questID and not InCombatLockdown() then
            if self.data.autoComplete and ShowQuestComplete then ShowQuestComplete(self.data.questID) else QuestMapFrame_OpenToQuestDetails(self.data.questID) end
        end
    end)
    row:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.isHovered = false
        PaintBorder(self)
    end)
    return row
end

local function Render(panel)
    local settings = Settings(panel.definition.id)
    local style = styles[settings.style]
    panel:SetScale(settings.scale)
    local pixel = PixelUnit(panel)
    local width = Snap(settings.width, pixel)
    local headerHeight = Snap(26, pixel)
    -- Alpha >= 64 starts at texel 11 (Ayije) / 12 (Pixels), in the 2..29
    -- sampled cell. Leave room for each texture's exterior ink on both surfaces.
    local outerInk = style.centered and math.max(0, Snap(style.edgeSize / 2, pixel) - style.edgeSize * style.inkInset) or 0
    local gap = math.ceil((3 + outerInk * 2) / pixel - 0.001) * pixel
    local contentTop = headerHeight + gap
    local rowHeight = Snap(settings.rowHeight, pixel)
    panel:SetWidth(width)
    panel.header:SetHeight(headerHeight)
    local clipPadding = Snap(8, pixel)
    local questInset = settings.content == "quests" and clipPadding or 0
    panel.viewport:ClearAllPoints()
    panel.viewport:SetPoint("TOPLEFT", -clipPadding, -contentTop + clipPadding - questInset)
    panel.viewport:SetPoint("TOPRIGHT", clipPadding, -contentTop + clipPadding - questInset)
    SetBackdrop(panel.header, style, settings.opacity, pixel)
    panel.title:SetText(settings.title)
    panel.title:SetWidth(width - Snap(40, pixel))
    panel.title:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
    panel.editModeName = "FunelQOL · " .. settings.title
    panel.arrow:SetText(settings.collapsed and "+" or "-")
    local data = addon.GetPanelRows(settings)
    local renderedHeight = 0
    local readable = settings.content == "quests" and settings.questReadable
    local groupIndex, currentGroup, groupStart = 0, nil, 0
    local function FinishGroup()
        if not currentGroup then return end
        local bottomPadding = Snap(5, pixel)
        currentGroup:SetHeight(renderedHeight - groupStart + bottomPadding)
        renderedHeight = renderedHeight + bottomPadding + math.ceil((8 + outerInk * 2) / pixel) * pixel
    end
    for index, entry in ipairs(data) do
        local row = panel.rows[index]
        if not row then row = CreateRow(panel); panel.rows[index] = row end
        row.data = entry
        row.meta:Hide()
        row.value:Show()
        if readable and entry.isQuestHeader then
            FinishGroup()
            groupIndex = groupIndex + 1
            panel.questGroups = panel.questGroups or {}
            currentGroup = panel.questGroups[groupIndex]
            if not currentGroup then
                currentGroup = CreateFrame("Frame", nil, panel.content, "BackdropTemplate")
                currentGroup:EnableMouse(false)
                currentGroup:SetFrameLevel(panel.content:GetFrameLevel())
                panel.questGroups[groupIndex] = currentGroup
            end
            groupStart = renderedHeight
            currentGroup:ClearAllPoints()
            currentGroup:SetPoint("TOPLEFT", clipPadding, -clipPadding - groupStart)
            currentGroup:SetWidth(width)
            SetBackdrop(currentGroup, style, settings.opacity * 0.7, pixel, currentGroup:GetFrameLevel(), entry.borderColor)
            currentGroup:Show()
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", clipPadding, -clipPadding - renderedHeight)
        row:SetWidth(width)
        row:SetHeight(rowHeight)
        SetBackdrop(row, style, settings.opacity, pixel, row.bar:GetFrameLevel(), entry.borderColor)
        row.background:SetShown(not readable)
        row.border:SetShown(not readable)
        row.label:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
        row.value:SetFont(STANDARD_TEXT_FONT, settings.fontSize, "OUTLINE")
        row.bar:SetStatusBarTexture(style.fill)
        row.bar:SetStatusBarColor(0.12, 0.42, 0.62, 0.65)
        DisableTextureSnapping(row.bar:GetStatusBarTexture())
        local padding = Snap(3, pixel)
        row.bar:ClearAllPoints()
        row.bar:SetPoint("TOPLEFT", padding, -padding)
        row.bar:SetPoint("BOTTOMRIGHT", -padding, padding)
        row.bar:SetMinMaxValues(0, math.max(1, entry.maximum or 0))
        row.bar:SetValue(math.min(entry.value or 0, math.max(1, entry.maximum or 0)))
        row.bar:SetShown(settings.showBars and (entry.maximum or 0) > 0)
        row.icon:SetTexture(entry.icon)
        DisableTextureSnapping(row.icon)
        row.icon:SetSize(Snap(16, pixel), Snap(16, pixel))
        row.icon:ClearAllPoints()
        row.icon:SetPoint("TOPLEFT", Snap(4, pixel), -Snap((rowHeight - Snap(16, pixel)) / 2, pixel))
        row.icon:SetShown(entry.icon ~= nil)
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", Snap(entry.icon and 24 or 6, pixel), 0)
        local labelStart = Snap(entry.icon and 24 or 6, pixel)
        local valueInset, valueGap = Snap(8, pixel), Snap(8, pixel)
        row.value:ClearAllPoints()
        row.value:SetPoint("RIGHT", -valueInset, 0)
        row.value:SetText(entry.moneyAmount and addon.GetMoneyText(entry.moneyAmount, settings.fontSize) or entry.valueText or "")
        local availableWidth = width - labelStart - valueInset - valueGap - 30
        local naturalWidth = row.value:GetUnboundedStringWidth()
        if entry.moneyAmount then
            -- Give all denominations room before shortening the label. On narrow
            -- panels, reduce just the money font until the full amount fits.
            local moneyFontSize = settings.fontSize
            while naturalWidth > availableWidth and moneyFontSize > 8 do
                moneyFontSize = moneyFontSize - 1
                row.value:SetFont(STANDARD_TEXT_FONT, moneyFontSize, "OUTLINE")
                row.value:SetText(addon.GetMoneyText(entry.moneyAmount, moneyFontSize))
                naturalWidth = row.value:GetUnboundedStringWidth()
            end
        end
        local valueWidth = math.ceil(math.min(entry.moneyAmount and availableWidth or width * 0.48, naturalWidth) / pixel) * pixel
        row.value:SetWidth(valueWidth)
        row.label:SetWidth(math.max(30, width - labelStart - valueInset - valueGap - valueWidth))
        row.label:SetWordWrap(entry.wrap or false)
        row.label:SetText(entry.name)
        local labelColor = entry.labelColor or { 1, 0.82, 0 }
        row.label:SetTextColor(labelColor[1], labelColor[2], labelColor[3])
        local actualHeight = entry.wrap and math.max(rowHeight, Snap(row.label:GetStringHeight() + 8, pixel)) or rowHeight
        if readable and (entry.isQuestHeader or entry.questObjective) then
            local isHeader = entry.isQuestHeader
            local fontSize = settings.fontSize + (isHeader and 2 or 1)
            row.label:SetFont(STANDARD_TEXT_FONT, fontSize, "")
            if row.label.SetShadowOffset then row.label:SetShadowOffset(1, -1); row.label:SetShadowColor(0, 0, 0, 1) end
            row.label:ClearAllPoints()
            row.label:SetPoint("TOPLEFT", Snap(isHeader and 10 or 16, pixel), -Snap(isHeader and 8 or 2, pixel))
            row.label:SetWidth(width - Snap(isHeader and 20 or 26, pixel))
            local label = isHeader and entry.questTitle or "- " .. entry.name:gsub("^%s+", "")
            local counter = entry.valueText or ""
            if not isHeader and counter ~= "" and (entry.progressBar or (counter:find("%d%s*/%s*%d")
                and not label:gsub("%s+", ""):find(counter:gsub("%s+", ""), 1, true))) then label = label .. " · " .. counter end
            row.label:SetText(label)
            row.value:Hide()
            row.bar:Hide()
            local labelHeight = row.label:GetStringHeight()
            if isHeader then
                local metadata = settings.questDetails and (entry.questBadge or "") or ""
                local summary = entry.questFailed and text.questFailed or not entry.questProgressText and entry.valueText == text.questLoading and text.questLoading
                    or not entry.questComplete and entry.value and entry.value > 0 and entry.questProgressText or ""
                metadata = metadata .. (metadata ~= "" and summary ~= "" and " · " or "") .. summary
                row.meta:SetFont(STANDARD_TEXT_FONT, math.max(10, settings.fontSize - 1), "")
                row.meta:SetTextColor(0.65, 0.7, 0.75)
                row.meta:ClearAllPoints()
                row.meta:SetPoint("TOPLEFT", Snap(10, pixel), -Snap(8 + labelHeight + 3, pixel))
                row.meta:SetWidth(width - Snap(20, pixel))
                row.meta:SetText(metadata)
                row.meta:SetShown(metadata ~= "")
                actualHeight = Snap(labelHeight + 14 + (metadata ~= "" and row.meta:GetStringHeight() + 3 or 0), pixel)
            else
                actualHeight = Snap(labelHeight + 5, pixel)
                if settings.showBars and entry.progressBar and (entry.maximum or 0) > 0 then
                    actualHeight = actualHeight + Snap(9, pixel)
                    row.bar:ClearAllPoints()
                    row.bar:SetPoint("BOTTOMLEFT", Snap(16, pixel), Snap(2, pixel))
                    row.bar:SetPoint("BOTTOMRIGHT", -Snap(10, pixel), Snap(2, pixel))
                    row.bar:SetHeight(Snap(4, pixel))
                    row.bar:Show()
                end
            end
        end
        row:SetHeight(actualHeight)
        row.icon:ClearAllPoints()
        row.icon:SetPoint("TOPLEFT", Snap(4, pixel), -Snap((actualHeight - Snap(16, pixel)) / 2, pixel))
        renderedHeight = renderedHeight + actualHeight + (readable and Snap(2, pixel) or gap)
        row:Show()
    end
    FinishGroup()
    for index = groupIndex + 1, #(panel.questGroups or {}) do panel.questGroups[index]:Hide() end
    for index = #data + 1, #panel.rows do panel.rows[index]:Hide() end
    local visibleHeight = settings.content == "quests" and math.min(renderedHeight, Snap(settings.questHeight, pixel)) or renderedHeight
    panel.content:SetSize(width + clipPadding * 2, renderedHeight + clipPadding * 2)
    panel.viewport:SetHeight(visibleHeight + clipPadding * 2)
    panel.scrollMaximum = math.max(0, renderedHeight - visibleHeight)
    panel.viewport:SetVerticalScroll(math.min(panel.viewport:GetVerticalScroll(), panel.scrollMaximum))
    panel.scrollHint:ClearAllPoints()
    panel.scrollHint:SetPoint("TOP", panel, "TOP", 0, -contentTop - visibleHeight - clipPadding - questInset)
    panel.scrollHint:SetText(text.questScrollHint)
    panel.scrollHint:SetShown(not settings.collapsed and panel.scrollMaximum > 0)
    panel.content:SetShown(not settings.collapsed)
    panel.viewport:SetShown(not settings.collapsed)
    panel:SetHeight(settings.collapsed and headerHeight or (contentTop + visibleHeight + questInset + (panel.scrollMaximum > 0 and Snap(22, pixel) or 0)))
    -- Rebuild from the saved anchor before snapping the visible top-left edge.
    -- GetLeft/GetTop are expressed in the frame's own scaled coordinates.
    panel:ClearAllPoints()
    panel:SetPoint(settings.point, UIParent, settings.point, settings.x, settings.y)
    local left, top = panel:GetLeft(), panel:GetTop()
    if left and top then
        panel:ClearAllPoints()
        panel:SetPoint(settings.point, UIParent, settings.point,
            settings.x + Snap(left, pixel) - left, settings.y + Snap(top, pixel) - top)
    end
    panel:SetShown(editing or settings.enabled)
end

function addon.RefreshPanels()
    addon.questHasTimers = false
    for _, panel in ipairs(panels) do Render(panel) end
end

function addon.SetPanelTitle(index, title)
    local panel = panels[index]
    if not panel then return end
    Settings(panel.definition.id).title = title
    Render(panel)
end

local function ApplyLayout(layoutName)
    addon.CloseContentEditor()
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
        { key = "content", label = text.content, kind = LEM.SettingType.Dropdown, default = "preview" },
        { key = "questReadable", label = text.questReadable, kind = LEM.SettingType.Checkbox, default = true },
        { key = "questAuto", label = text.questAuto, kind = LEM.SettingType.Checkbox, default = true },
        { key = "questAll", label = text.questAll, kind = LEM.SettingType.Checkbox, default = true },
        { key = "questHeight", label = text.questHeight, kind = LEM.SettingType.Slider, default = 400, min = 150, max = 800, step = 25 },
        { key = "questLimit", label = text.questLimit, kind = LEM.SettingType.Slider, default = 3, min = 1, max = 8, step = 1 },
        { key = "questDetails", label = text.questDetails, kind = LEM.SettingType.Checkbox, default = true },
        { key = "questColors", label = text.questColors, kind = LEM.SettingType.Checkbox, default = true },
        { key = "questObjectives", label = text.questObjectives, kind = LEM.SettingType.Checkbox, default = true },
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
            hidden = function(layoutName)
                local settings = Settings(id, layoutName)
                if key == "rowCount" then return settings.content ~= "preview" end
                if key == "questReadable" or key == "questAuto" or key == "questObjectives" or key == "questDetails" or key == "questColors" or key == "questHeight" then return settings.content ~= "quests" end
                if key == "questAll" then return settings.content ~= "quests" or not settings.questAuto end
                if key == "questLimit" then return settings.content ~= "quests" or not settings.questAuto or settings.questAll end
                return false
            end,
            values = key == "content" and addon.contentTypes or key == "style" and { { text = "Blizzard", value = "blizzard" }, { text = "Ayije", value = "ayije" }, { text = "Pixels", value = "pixels" } } or nil,
            get = function(layoutName) return Settings(id, layoutName)[key] end,
            set = function(layoutName, value)
                if key == "content" then addon.CloseContentEditor() end
                Settings(id, layoutName)[key] = value
                Render(panel)
            end,
        }
    end
    LEM:AddFrameSettings(panel, controls)
    LEM:AddFrameSettingsButtons(panel, { { text = text.configure, click = function()
        addon.OpenContentEditor(Settings(id), function() Render(panel); LEM:RefreshFrameSettings(panel) end)
    end } })
end

function addon.ConfigurePanel(index)
    local panel = panels[index]
    if panel then addon.OpenContentEditor(Settings(panel.definition.id), function() Render(panel); LEM:RefreshFrameSettings(panel) end) end
end

function addon.InitializePanels()
    if #panels > 0 then return end
    if type(FunelQOLCharDB) ~= "table" then FunelQOLCharDB = {} end
    addon.characterDB = FunelQOLCharDB
    if type(FunelQOLCharDB.layouts) ~= "table" then FunelQOLCharDB.layouts = {} end

    LEM:RegisterCallback("layout", ApplyLayout)
    LEM:RegisterCallback("enter", function() editing = true; addon.RefreshPanels() end)
    LEM:RegisterCallback("exit", function() addon.CloseContentEditor(); editing = false; addon.RefreshPanels() end)
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
        panel.viewport = CreateFrame("ScrollFrame", nil, panel)
        panel.content = CreateFrame("Frame", nil, panel.viewport)
        panel.content:SetSize(260, 1)
        panel.viewport:SetScrollChild(panel.content)
        panel.viewport:EnableMouseWheel(true)
        panel.viewport:SetScript("OnMouseWheel", function(self, delta)
            self:SetVerticalScroll(math.max(0, math.min(panel.scrollMaximum or 0, self:GetVerticalScroll() - Snap(delta * 40, PixelUnit(self)))))
        end)
        panel.scrollHint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
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
            Render(panel)
        end, default)
        AddSettings(panel)
    end
    ApplyLayout(LEM:GetActiveLayoutName())

    local events = CreateFrame("Frame")
    events:RegisterEvent("UI_SCALE_CHANGED")
    events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    for _, event in ipairs({ "PLAYER_MONEY", "CURRENCY_DISPLAY_UPDATE", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE", "TRAIT_CONFIG_UPDATED", "PLAYER_SPECIALIZATION_CHANGED", "SPELLS_CHANGED", "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "QUEST_WATCH_LIST_CHANGED", "QUEST_DATA_LOAD_RESULT", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "SUPER_TRACKING_CHANGED", "SUPER_TRACKING_PATH_UPDATED", "QUEST_POI_UPDATE" }) do
        events:RegisterEvent(event)
    end
    events:SetScript("OnEvent", addon.RefreshPanels)
    local elapsed = 0
    events:SetScript("OnUpdate", function(_, delta)
        if not addon.questHasTimers then elapsed = 0; return end
        elapsed = elapsed + delta
        if elapsed >= 1 then elapsed = 0; addon.RefreshPanels() end
    end)
    -- UIParent:SetScale can be called directly by UI addons without a CVar event.
    hooksecurefunc(UIParent, "SetScale", addon.RefreshPanels)
end

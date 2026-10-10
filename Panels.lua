local addonName, addon = ...
local LEM = addon.LibEditMode
local text = addon.panelText
local fr = GetLocale() == "frFR"
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
text.anchorTarget = fr and "Ancrer à" or "Anchor to"
text.anchorSide = fr and "Côté de la cible" or "Target side"
text.anchorAlign = fr and "Alignement" or "Alignment"
text.anchorGap = fr and "Espacement" or "Spacing"
text.anchorOffset = fr and "Décalage le long du bord" or "Offset along edge"
text.point = fr and "Ancre écran" or "Screen anchor"
text.anchorCycle = fr and "Ce lien créerait une boucle d’ancres." or "This link would create an anchor cycle."
local anchorSides = {
    BOTTOM = { start = { "TOPLEFT", "BOTTOMLEFT" }, center = { "TOP", "BOTTOM" }, finish = { "TOPRIGHT", "BOTTOMRIGHT" } },
    TOP = { start = { "BOTTOMLEFT", "TOPLEFT" }, center = { "BOTTOM", "TOP" }, finish = { "BOTTOMRIGHT", "TOPRIGHT" } },
    LEFT = { start = { "TOPRIGHT", "TOPLEFT" }, center = { "RIGHT", "LEFT" }, finish = { "BOTTOMRIGHT", "BOTTOMLEFT" } },
    RIGHT = { start = { "TOPLEFT", "TOPRIGHT" }, center = { "LEFT", "RIGHT" }, finish = { "BOTTOMLEFT", "BOTTOMRIGHT" } },
}

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
    -- Apply the requested visual refresh once to existing layouts, while
    -- allowing subsequent opacity adjustments to persist.
    if settings.backgroundRevision ~= 1 then settings.opacity = 0.8; settings.backgroundRevision = 1 end
    local definition
    for _, entry in ipairs(definitions) do if entry.id == id then definition = entry; break end end
    local defaults = {
        point = "TOPRIGHT", x = definition.x, y = definition.y,
        title = definition.title, width = 260, scale = 1, enabled = true,
        collapsed = false, style = "blizzard", opacity = 0.8,
        fontSize = 11, rowHeight = 22, rowCount = 3, showBars = true, content = "preview",
        questTracker = true, questEvents = true, questReadable = true, questAuto = true, questAll = true, questHeight = 400, questLimit = 3, questObjectives = true, questDetails = true, questColors = true,
        delvesBountifulOnly = false, delvesSort = "grade", delvesHeight = 400,
        delveQuestsHideCompleted = false,
        raidSetsFollowInstance = true,
        anchorTarget = "screen", anchorSide = "BOTTOM", anchorAlign = "start", anchorGap = 8, anchorOffset = 0,
    }
    for key, value in pairs(defaults) do
        if type(settings[key]) ~= type(value) then settings[key] = value end
    end
    local validContent = false
    for _, kind in ipairs(addon.contentTypes) do if settings.content == kind.value then validContent = true end end
    if not validContent then settings.content = "preview" end
    if settings.delvesSort ~= "grade" and settings.delvesSort ~= "name" then settings.delvesSort = "grade" end
    if type(settings.questSections) ~= "table" then settings.questSections = {} end
    if type(settings.delvesSections) ~= "table" then settings.delvesSections = {} end
    if not styles[settings.style] then settings.style = "blizzard" end
    local anchors = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }
    if not anchors[settings.point] then settings.point = "TOPRIGHT" end
    if settings.anchorTarget ~= "panel1" and settings.anchorTarget ~= "panel2" or settings.anchorTarget == id then settings.anchorTarget = "screen" end
    if not anchorSides[settings.anchorSide] then settings.anchorSide = "BOTTOM" end
    if settings.anchorAlign ~= "start" and settings.anchorAlign ~= "center" and settings.anchorAlign ~= "finish" then settings.anchorAlign = "start" end
    settings.anchorGap = math.max(0, math.min(80, settings.anchorGap))
    settings.anchorOffset = math.max(-200, math.min(200, settings.anchorOffset))
    settings.width = math.max(180, math.min(420, settings.width))
    settings.scale = math.max(0.7, math.min(1.5, settings.scale))
    settings.opacity = math.max(0.2, math.min(1, settings.opacity))
    settings.fontSize = math.floor(math.max(10, math.min(18, settings.fontSize)))
    settings.rowHeight = math.floor(math.max(22, math.min(34, settings.rowHeight)))
    settings.rowCount = math.floor(math.max(1, math.min(8, settings.rowCount)))
    settings.questHeight = math.floor(math.max(150, math.min(800, settings.questHeight)))
    settings.delvesHeight = math.floor(math.max(150, math.min(800, settings.delvesHeight)))
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

local function WouldCycle(id, target, layoutName)
    local seen = { [id] = true }
    while target == "panel1" or target == "panel2" do
        if seen[target] then return true end
        seen[target] = true
        target = Settings(target, layoutName).anchorTarget
    end
    return false
end

local screenPoints = { TOPLEFT = { 0, 1 }, TOP = { .5, 1 }, TOPRIGHT = { 1, 1 }, LEFT = { 0, .5 }, CENTER = { .5, .5 }, RIGHT = { 1, .5 }, BOTTOMLEFT = { 0, 0 }, BOTTOM = { .5, 0 }, BOTTOMRIGHT = { 1, 0 } }
local function SaveFreePosition(panel, settings, point)
    local left, top = panel:GetLeft(), panel:GetTop()
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local fraction = screenPoints[point or "TOPLEFT"]
    if left and top and width and height and fraction then
        local ratio = UIParent:GetEffectiveScale() / panel:GetEffectiveScale()
        settings.point = point or "TOPLEFT"
        settings.x = left + panel:GetWidth() * fraction[1] - width * ratio * fraction[1]
        settings.y = top - panel:GetHeight() * (1 - fraction[2]) - height * ratio * fraction[2]
    end
end

local function PositionPanels()
    local lookup, placed = {}, {}
    for _, panel in ipairs(panels) do
        lookup[panel.definition.id] = panel
        local settings = Settings(panel.definition.id)
        if WouldCycle(panel.definition.id, settings.anchorTarget) then settings.anchorTarget = "screen" end
        -- Clear stale engine links before applying a changed dependency graph.
        panel:ClearAllPoints()
    end
    local function Place(panel)
        if placed[panel] then return end
        placed[panel] = true
        local settings = Settings(panel.definition.id)
        local target = lookup[settings.anchorTarget]
        local point, relativePoint, x, y = settings.point, settings.point, settings.x, settings.y
        if target then
            Place(target)
            local pair = anchorSides[settings.anchorSide][settings.anchorAlign]
            point, relativePoint = pair[1], pair[2]
            -- Link offsets are in UIParent units, even when panels have different scales.
            local ratio = UIParent:GetEffectiveScale() / panel:GetEffectiveScale()
            local gap, offset = settings.anchorGap * ratio, settings.anchorOffset * ratio
            x = settings.anchorSide == "LEFT" and -gap or settings.anchorSide == "RIGHT" and gap or offset
            y = settings.anchorSide == "TOP" and gap or settings.anchorSide == "BOTTOM" and -gap or offset
        end
        local relative = target or UIParent
        panel:SetClampedToScreen(not target)
        panel:SetPoint(point, relative, relativePoint, x, y)
        local left, top, pixel = panel:GetLeft(), panel:GetTop(), PixelUnit(panel)
        if left and top then
            panel:ClearAllPoints()
            panel:SetPoint(point, relative, relativePoint, x + Snap(left, pixel) - left, y + Snap(top, pixel) - top)
        end
    end
    for _, panel in ipairs(panels) do Place(panel) end
end

local function DisableTextureSnapping(texture)
    if texture and texture.SetSnapToPixelGrid then
        texture:SetSnapToPixelGrid(false)
        texture:SetTexelSnappingBias(0)
    end
end

local defaultBorderColor = { 0.38, 0.35, 0.29, 1 }
local compactBorderColor = { 0.3, 0.3, 0.3, 1 }
local compactColors = { currencies = { 0.15, 0.8, 1 }, professions = { 0.3, 1, 0.3 }, talents = { 0.75, 0.35, 1 }, custom = { 1, 1, 1 } }
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
        if data.trackerSection then
            GameTooltip:SetText(data.name, 1, 1, 1)
        elseif data.delveID then
            addon.ShowDelveTooltip(data)
        elseif data.eventID then
            GameTooltip:SetText(data.questTitle, 1, 0.55, 0.12)
            if data.questZone then GameTooltip:AddLine(data.questZone, 0.3, 0.7, 1, true) end
            if data.description then GameTooltip:AddLine(data.description, 1, 1, 1, true) end
        elseif data.questID then
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
            if data.raidSetID then
                GameTooltip:SetMinimumWidth(420, true)
                GameTooltip:AddLine(data.raidCollectionText, 1, 1, 1)
            elseif data.valueText and data.valueText ~= "" then GameTooltip:AddLine(data.valueText, 1, 1, 1) end
            for _, line in ipairs(data.tooltipLines or {}) do GameTooltip:AddLine(line, 1, 1, 1, true) end
        end
        GameTooltip:Show()
        self.isHovered = true
        PaintBorder(self)
    end)
    row:SetScript("OnClick", function(self)
        if editing then return end
        if self.data.raidSetID then
            addon.PreviewRaidSet(self.data)
        elseif self.data.trackerSection then
            local settings = Settings(panel.definition.id)
            local key = self.data.trackerSection
            local sections = self.data.delveSection and settings.delvesSections or settings.questSections
            sections[key] = not sections[key]
            addon.RefreshPanels()
        elseif (self.data.eventID or self.data.delveID) and not InCombatLockdown() and OpenWorldMap then
            OpenWorldMap(self.data.mapID)
        elseif self.data.delveQuestID and self.data.delveQuestActive and not InCombatLockdown() then
            QuestMapFrame_OpenToQuestDetails(self.data.delveQuestID)
        elseif self.data.questID and not InCombatLockdown() then
            if self.data.autoComplete and ShowQuestComplete then ShowQuestComplete(self.data.questID) else QuestMapFrame_OpenToQuestDetails(self.data.questID) end
        end
    end)
    row:SetScript("OnLeave", function(self)
        if self.data and self.data.raidSetID then GameTooltip:SetMinimumWidth(0, false) end
        GameTooltip:Hide()
        self.isHovered = false
        PaintBorder(self)
    end)
    return row
end

local function LayoutTrackerRow(row, entry, settings, width, pixel, compact)
    local function P(value) return Snap(value, pixel) end
    row.value:Hide()
    row.bar:Hide()
    row.border:Hide()
    row.background:Hide()
    row.label:SetFont((entry.trackerSection or entry.isQuestHeader) and addon.media.menuFont or STANDARD_TEXT_FONT, settings.fontSize + (compact and (entry.isQuestHeader and 1 or 0) or entry.isQuestHeader and 2 or 1), compact and "OUTLINE" or "")
    row.label:SetWordWrap(true)
    if row.label.SetShadowOffset then row.label:SetShadowOffset(1, -1); row.label:SetShadowColor(0, 0, 0, 1) end
    local section, header = entry.trackerSection, entry.isQuestHeader
    local left = P(compact and (entry.questObjective and 14 or 6) or (section or not header and not entry.questObjective) and 12 or 36)
    row.label:ClearAllPoints()
    row.label:SetPoint("TOPLEFT", left, -P(section and 6 or 2))
    row.label:SetWidth(width - left - P(compact and header and 28 or 12))
    if entry.delveID then
        row.label:SetWidth(width - left - P(42))
        row.value:ClearAllPoints()
        row.value:SetPoint("TOPRIGHT", -P(12), -P(2))
        row.value:SetFont(STANDARD_TEXT_FONT, settings.fontSize + 3, "")
        row.value:SetWidth(P(24))
        row.value:SetText(entry.delveGrade)
        local color = addon.delveGradeColors[entry.delveGrade] or { 0.65, 0.7, 0.75 }
        row.value:SetTextColor(color[1], color[2], color[3])
        row.value:Show()
    end
    if section then
        row.label:SetText((entry.sectionCollapsed and "+ " or "− ") .. (compact and string.upper(entry.name) or entry.name))
        row.label:SetTextColor(1, 1, 1)
        row.background:SetColorTexture(0.3, 0.24, 0.06, 0.35)
        row.background:SetShown(not compact)
        row.trackerLine = row.trackerLine or row:CreateTexture(nil, "ARTWORK")
        row.trackerLine:ClearAllPoints()
        row.trackerLine:SetPoint("BOTTOMLEFT", P(8), 0)
        row.trackerLine:SetPoint("BOTTOMRIGHT", -P(8), 0)
        row.trackerLine:SetHeight(P(1))
        if compact then row.trackerLine:SetColorTexture(0.3, 0.3, 0.3, 0.8)
        else row.trackerLine:SetColorTexture(0.65, 0.5, 0.12, 0.8) end
        DisableTextureSnapping(row.trackerLine)
        row.trackerLine:Show()
        row.icon:Hide()
        return P(row.label:GetStringHeight() + (compact and 10 or 14))
    end
    local label = header and entry.questTitle or entry.name:gsub("^%s+", "")
    if entry.questObjective and not entry.directive then label = "- " .. label end
    local counter = entry.valueText or ""
    if not header and counter ~= "" and (entry.progressBar or (counter:find("%d%s*/%s*%d")
        and not label:gsub("%s+", ""):find(counter:gsub("%s+", ""), 1, true))) then label = label .. " · " .. counter end
    row.label:SetText(label)
    local height = row.label:GetStringHeight() + 5
    if header then
        local metadata = entry.questZone and "|cff4da6e6" .. entry.questZone .. "|r" or ""
        if entry.delveID then
            local story = entry.delveStory or text.delvesUnknown
            if entry.delveTime then story = story .. " · " .. entry.delveTime end
            metadata = metadata .. (metadata ~= "" and "\n" or "") .. story
            if entry.delveQuest then
                local color = entry.delveQuest.color
                local colored = string.format("|cff%02x%02x%02x", math.floor(color[1] * 255), math.floor(color[2] * 255), math.floor(color[3] * 255))
                metadata = metadata .. "\n" .. (fr and "Quête XP : " or "XP quest: ") .. colored .. entry.delveQuest.label .. "|r"
            end
        elseif settings.questDetails then
            local badge = entry.questBadge or ""
            local status = entry.questFailed and text.questFailed or entry.valueText == text.questLoading and text.questLoading
                or not entry.questComplete and entry.value and entry.value > 0 and entry.questProgressText or ""
            local details = badge .. (badge ~= "" and status ~= "" and " · " or "") .. status
            if details ~= "" then metadata = metadata .. (metadata ~= "" and "\n" or "") .. details end
        end
        row.meta:ClearAllPoints()
        row.meta:SetPoint("TOPLEFT", left, -P(row.label:GetStringHeight() + 5))
        row.meta:SetWidth(width - left - P(compact and 28 or 12))
        row.meta:SetFont(STANDARD_TEXT_FONT, compact and math.max(10, settings.fontSize - 1) or settings.fontSize, "")
        row.meta:SetTextColor(0.65, 0.7, 0.75)
        row.meta:SetText(metadata)
        row.meta:SetShown(metadata ~= "")
        if metadata ~= "" then height = height + row.meta:GetStringHeight() + 3 end
        row.icon:ClearAllPoints()
        if compact then row.icon:SetPoint("TOPRIGHT", -P(6), -P(3))
        else row.icon:SetPoint("TOPLEFT", P(10), -P(2)) end
        row.icon:SetSize(P(compact and 14 or 20), P(compact and 14 or 20))
        row.icon:SetTexCoord(0, 1, 0, 1)
        row.icon:SetTexture(entry.questIcon or entry.icon)
        if entry.iconAtlas then row.icon:SetAtlas(entry.iconAtlas, false) end
        row.icon:Show()
        row.trackerAccent = row.trackerAccent or row:CreateTexture(nil, "ARTWORK")
        row.trackerAccent:ClearAllPoints()
        row.trackerAccent:SetPoint("TOPLEFT", P(compact and 1 or 5), -P(2))
        row.trackerAccent:SetPoint("BOTTOMLEFT", P(compact and 1 or 5), P(2))
        row.trackerAccent:SetWidth(P(2))
        local color = entry.borderColor or defaultBorderColor
        row.trackerAccent:SetColorTexture(color[1], color[2], color[3], 0.9)
        DisableTextureSnapping(row.trackerAccent)
        row.trackerAccent:SetShown(entry.borderColor ~= nil)
        height = math.max(24, height)
    else
        row.icon:Hide()
        if settings.showBars and entry.progressBar and (entry.maximum or 0) > 0 then
            height = height + 9
            row.bar:ClearAllPoints()
            row.bar:SetPoint("BOTTOMLEFT", left, P(2))
            row.bar:SetPoint("BOTTOMRIGHT", -P(12), P(2))
            row.bar:SetHeight(P(4))
            row.bar:Show()
        end
    end
    return P(height)
end

local function Render(panel)
    local settings = Settings(panel.definition.id)
    local style = styles[settings.style]
    panel:SetScale(settings.scale)
    local pixel = PixelUnit(panel)
    local width = Snap(settings.width, pixel)
    local questTracker = settings.content == "quests" and settings.questReadable and settings.questTracker
    local delves = settings.content == "delves"
    local tracker = questTracker or delves
    local compact = settings.content ~= "preview" and settings.content ~= "quests" and not delves
    local compactSurface = compact or questTracker
    local headerHeight = Snap(compactSurface and 24 or tracker and 34 or 26, pixel)
    -- Alpha >= 64 starts at texel 11 (Ayije) / 12 (Pixels), in the 2..29
    -- sampled cell. Leave room for each texture's exterior ink on both surfaces.
    local outerInk = style.centered and math.max(0, Snap(style.edgeSize / 2, pixel) - style.edgeSize * style.inkInset) or 0
    local gap = math.ceil((3 + outerInk * 2) / pixel - 0.001) * pixel
    local contentTop = headerHeight + (delves and 0 or gap)
    local rowHeight = Snap(compact and math.max(settings.rowHeight, settings.fontSize + 8) or settings.rowHeight, pixel)
    local rowInset = questTracker and Snap(4, pixel) or 0
    local rowWidth = width - rowInset * 2
    panel:SetWidth(width)
    panel.header:SetHeight(headerHeight)
    local clipPadding = Snap(8, pixel)
    local questInset = (settings.content == "quests" or delves) and clipPadding or 0
    panel.viewport:ClearAllPoints()
    panel.viewport:SetPoint("TOPLEFT", -clipPadding, -contentTop + clipPadding - questInset)
    panel.viewport:SetPoint("TOPRIGHT", clipPadding, -contentTop + clipPadding - questInset)
    SetBackdrop(panel.header, style, settings.opacity, pixel, nil, compactSurface and compactBorderColor or nil)
    if compactSurface then
        SetBackdrop(panel.body, style, settings.opacity, pixel, nil, compactBorderColor)
        panel.body:ClearAllPoints()
        panel.body:SetPoint("TOPLEFT", 0, -contentTop)
        panel.body:SetPoint("BOTTOMRIGHT", 0, 0)
    end
    panel.body:SetShown(compactSurface and not settings.collapsed)
    if tracker then SetBackdrop(panel, style, settings.opacity, pixel) end
    if panel.background then panel.background:SetShown(delves); panel.border:SetShown(delves) end
    panel.header.background:SetShown(not delves)
    panel.header.border:SetShown(not delves)
    panel.title:ClearAllPoints()
    panel.title:SetPoint(delves and "LEFT" or "CENTER", delves and Snap(12, pixel) or compactSurface and 0 or -8, 0)
    local title = settings.title
    if settings.title == panel.definition.title then
        if tracker then title = delves and text.delves or text.trackerTitle
        elseif compact then
            for _, kind in ipairs(addon.contentTypes) do if kind.value == settings.content then title = kind.text; break end end
            if settings.content == "raidsets" then title = addon.GetRaidSetTitle(settings) or title end
        end
    end
    panel.title:SetText(compactSurface and string.upper(title) or title)
    panel.title:SetWidth(width - Snap(40, pixel))
    panel.title:SetFont(addon.media.menuFont, settings.fontSize + (delves and 3 or 0), delves and "" or "OUTLINE")
    panel.title:SetTextColor(1, (tracker or compact) and 1 or 0.82, (tracker or compact) and 1 or 0)
    panel.editModeName = "FunelQOL · " .. settings.title
    panel.arrow:ClearAllPoints()
    panel.arrow:SetPoint(compactSurface and "LEFT" or "RIGHT", compactSurface and Snap(7, pixel) or -Snap(7, pixel), 0)
    panel.arrow:SetSize(Snap(16, pixel), Snap(16, pixel))
    for index, stroke in ipairs(panel.arrow.strokes) do
        stroke:SetSize(Snap(9, pixel), Snap(2, pixel))
        stroke:ClearAllPoints()
        -- Right-facing when collapsed, downward-facing when expanded.
        stroke:SetPoint("CENTER", panel.arrow, "CENTER", settings.collapsed and 0 or Snap(index == 1 and -3 or 3, pixel), settings.collapsed and Snap(index == 1 and 3 or -3, pixel) or 0)
        stroke:SetRotation(index == 1 and -math.pi / 4 or math.pi / 4)
    end
    local data = delves and addon.GetDelveRows(settings) or tracker and addon.GetTrackerRows(settings) or addon.GetPanelRows(settings)
    local renown = settings.content == "renown"
    local renownValueWidth, renownFontSize = 0, settings.fontSize
    if renown then
        panel.valueMeasure = panel.valueMeasure or panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        local available = rowWidth - Snap(6 + 8 + 8 + 26, pixel) - 30
        repeat
            panel.valueMeasure:SetFont(STANDARD_TEXT_FONT, renownFontSize, "OUTLINE")
            renownValueWidth = 0
            for _, entry in ipairs(data) do
                panel.valueMeasure:SetText(entry.valueText or "")
                renownValueWidth = math.max(renownValueWidth, panel.valueMeasure:GetUnboundedStringWidth())
            end
            if renownValueWidth <= available or renownFontSize <= 8 then break end
            renownFontSize = renownFontSize - 1
        until false
        renownValueWidth = math.ceil(math.min(available, renownValueWidth) / pixel) * pixel
        panel.valueMeasure:Hide()
    end
    local renderedHeight = 0
    local readable = tracker or settings.content == "quests" and settings.questReadable
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
        for _, crest in ipairs(row.crests or {}) do crest.icon:Hide(); crest.count:Hide() end
        row.meta:Hide()
        if row.trackerLine then row.trackerLine:Hide() end
        if row.trackerAccent then row.trackerAccent:Hide() end
        row.value:Show()
        if readable and entry.isQuestHeader and not tracker then
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
        row:SetPoint("TOPLEFT", clipPadding + rowInset, -clipPadding - renderedHeight)
        row:SetWidth(rowWidth)
        row:SetHeight(rowHeight)
        SetBackdrop(row, style, settings.opacity, pixel, row.bar:GetFrameLevel(), entry.borderColor)
        row.background:SetShown(not readable and not compact)
        row.border:SetShown(not readable and not compact)
        if not row.separator then row.separator = row.label:GetParent():CreateTexture(nil, "ARTWORK") end
        local nextEntry = data[index + 1]
        row.separator:SetShown(compact and nextEntry ~= nil or questTracker and nextEntry and not entry.trackerSection and (nextEntry.isQuestHeader or nextEntry.trackerSection) or false)
        row.separator:ClearAllPoints()
        row.separator:SetPoint("BOTTOMLEFT", 0, 0)
        row.separator:SetPoint("BOTTOMRIGHT", 0, 0)
        row.separator:SetHeight(pixel)
        row.separator:SetColorTexture(compact and 0.35 or 0.2, compact and 0.35 or 0.2, compact and 0.35 or 0.2, compact and 1 or 0.7)
        DisableTextureSnapping(row.separator)
        row.label:SetFont(addon.media.menuFont, settings.fontSize, "OUTLINE")
        row.value:SetFont(STANDARD_TEXT_FONT, renown and renownFontSize or settings.fontSize, "OUTLINE")
        row.value:SetTextColor(1, 1, 1)
        row.bar:SetStatusBarTexture(style.fill)
        local gaugeMaximum = entry.gaugeMaximum or entry.maximum or 0
        local gaugeValue = entry.gaugeValue or entry.value or 0
        local compactGauge = compact and gaugeMaximum > 0 and (entry.gaugeMaximum ~= nil or settings.content == "professions" or settings.content == "raidsets")
        local gaugeColor = entry.compactColor or entry.labelColor or {0.12, 0.42, 0.62}
        if compactGauge then row.bar:SetStatusBarColor(gaugeColor[1], gaugeColor[2], gaugeColor[3], 0.3)
        else row.bar:SetStatusBarColor(0.12, 0.42, 0.62, 0.65) end
        DisableTextureSnapping(row.bar:GetStatusBarTexture())
        local padding = compactGauge and 0 or Snap(3, pixel)
        row.bar:ClearAllPoints()
        row.bar:SetPoint("TOPLEFT", padding, -padding)
        row.bar:SetPoint("BOTTOMRIGHT", -padding, padding)
        row.bar:SetMinMaxValues(0, math.max(1, gaugeMaximum))
        row.bar:SetValue(math.max(0, math.min(gaugeValue, math.max(1, gaugeMaximum))))
        row.bar:SetShown(settings.showBars and gaugeMaximum > 0 and (not compact or compactGauge))
        row.icon:SetTexture(entry.icon)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if entry.iconAtlas then
            row.icon:SetTexCoord(0, 1, 0, 1)
            row.icon:SetAtlas(entry.iconAtlas, false)
        end
        DisableTextureSnapping(row.icon)
        row.icon:SetSize(Snap(16, pixel), Snap(16, pixel))
        row.icon:ClearAllPoints()
        row.icon:SetPoint("TOPLEFT", Snap(4, pixel), -Snap((rowHeight - Snap(16, pixel)) / 2, pixel))
        row.icon:SetShown(entry.icon ~= nil)
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", Snap(not compact and entry.icon and 24 or 6, pixel), 0)
        local labelStart = Snap(not compact and entry.icon and 24 or 6, pixel)
        local valueInset, valueGap = Snap(8, pixel), Snap(8, pixel)
        row.value:ClearAllPoints()
        row.value:SetPoint("RIGHT", -valueInset, 0)
        row.value:SetText(entry.crestAmounts and "" or entry.moneyAmount and addon.GetMoneyText(entry.moneyAmount, settings.fontSize) or entry.valueText or "")
        local compactIconSize = Snap(renown and 20 or entry.iconSize or 14, pixel)
        local iconSpace = compact and entry.icon and not entry.moneyAmount and compactIconSize + Snap(6, pixel) or 0
        if renown then row.value:SetPoint("RIGHT", -valueInset - iconSpace, 0) end
        local availableWidth = rowWidth - labelStart - valueInset - valueGap - iconSpace - 30
        local naturalWidth = row.value:GetUnboundedStringWidth()
        if entry.moneyAmount or entry.fitValue then
            -- Give all denominations room before shortening the label. On narrow
            -- panels, reduce just the money font until the full amount fits.
            local moneyFontSize = settings.fontSize
            while naturalWidth > availableWidth and moneyFontSize > 8 do
                moneyFontSize = moneyFontSize - 1
                row.value:SetFont(STANDARD_TEXT_FONT, moneyFontSize, "OUTLINE")
                if entry.moneyAmount then row.value:SetText(addon.GetMoneyText(entry.moneyAmount, moneyFontSize)) end
                naturalWidth = row.value:GetUnboundedStringWidth()
            end
        end
        local valueWidth = math.ceil(math.min((entry.moneyAmount or entry.fitValue) and availableWidth or rowWidth * 0.48, naturalWidth) / pixel) * pixel
        if renown then valueWidth = renownValueWidth end
        row.value:SetWidth(valueWidth)
        row.label:SetWidth(math.max(30, rowWidth - labelStart - valueInset - valueGap - valueWidth - iconSpace))
        row.label:SetWordWrap(entry.wrap or false)
        row.label:SetText(compact and string.upper(entry.name) or entry.name)
        local labelColor = entry.labelColor or compact and (entry.compactColor or (entry.moneyAmount and { 1, 0.82, 0 } or compactColors[settings.content])) or { 1, 0.82, 0 }
        row.label:SetTextColor(labelColor[1], labelColor[2], labelColor[3])
        if compact and not entry.moneyAmount then row.value:SetTextColor(labelColor[1], labelColor[2], labelColor[3]) end
        local actualHeight = entry.wrap and math.max(rowHeight, Snap(row.label:GetStringHeight() + 8, pixel)) or rowHeight
        if compact and (entry.iconSize or renown) then actualHeight = math.max(actualHeight, compactIconSize + Snap(4, pixel)) end
        if tracker then
            if entry.isQuestHeader then
                renderedHeight = renderedHeight + Snap(questTracker and 4 or 8, pixel)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", clipPadding + rowInset, -clipPadding - renderedHeight)
            end
            actualHeight = LayoutTrackerRow(row, entry, settings, rowWidth, pixel, questTracker)
        elseif readable and (entry.isQuestHeader or entry.questObjective) then
            local isHeader = entry.isQuestHeader
            local fontSize = settings.fontSize + (isHeader and 2 or 1)
            row.label:SetFont(isHeader and addon.media.menuFont or STANDARD_TEXT_FONT, fontSize, "")
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
        if entry.crestAmounts then
            -- Inline textures follow the font baseline and can protrude even
            -- when the row is taller. Anchor real textures to the row instead.
            row.crests = row.crests or {}
            local fontSize, iconSize, crestGap = settings.fontSize, 20, 8
            local function Measure()
                local total = 0
                for crestIndex, info in ipairs(entry.crestAmounts) do
                    local crest = row.crests[crestIndex]
                    if not crest then
                        crest = { icon = row.icon:GetParent():CreateTexture(nil, "ARTWORK"), count = row.label:GetParent():CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") }
                        row.crests[crestIndex] = crest
                    end
                    crest.count:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
                    crest.count:SetText(tostring(info.quantity or 0))
                    crest.width = math.ceil(crest.count:GetUnboundedStringWidth() / pixel) * pixel
                    total = total + Snap(iconSize, pixel) + Snap(3, pixel) + crest.width + (crestIndex > 1 and Snap(crestGap, pixel) or 0)
                end
                return total
            end
            local totalWidth = Measure()
            while totalWidth > availableWidth and fontSize > 8 do fontSize = fontSize - 1; totalWidth = Measure() end
            while totalWidth > availableWidth and crestGap > 2 do crestGap = crestGap - 2; totalWidth = Measure() end
            while totalWidth > availableWidth and iconSize > 16 do iconSize = iconSize - 2; totalWidth = Measure() end
            local offset = valueInset
            for crestIndex = #entry.crestAmounts, 1, -1 do
                local crest, info = row.crests[crestIndex], entry.crestAmounts[crestIndex]
                crest.count:ClearAllPoints()
                crest.count:SetPoint("RIGHT", row, "RIGHT", -offset, 0)
                crest.count:SetWidth(crest.width)
                crest.count:SetJustifyH("RIGHT")
                crest.count:Show()
                offset = offset + crest.width + Snap(3, pixel)
                crest.icon:SetTexture(info.iconFileID)
                crest.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                DisableTextureSnapping(crest.icon)
                crest.icon:SetSize(Snap(iconSize, pixel), Snap(iconSize, pixel))
                crest.icon:ClearAllPoints()
                crest.icon:SetPoint("RIGHT", row, "RIGHT", -offset, 0)
                crest.icon:Show()
                offset = offset + Snap(iconSize, pixel) + Snap(crestGap, pixel)
            end
            row.label:SetWidth(math.max(20, rowWidth - labelStart - valueInset - valueGap - totalWidth))
            row.value:Hide()
            row:SetHeight(math.max(actualHeight, Snap(iconSize + 8, pixel)))
            actualHeight = row:GetHeight()
        end
        if compact then
            row.icon:ClearAllPoints()
            row.icon:SetSize(compactIconSize, compactIconSize)
            row.icon:SetPoint("RIGHT", row, "RIGHT", renown and -valueInset or -Snap(valueInset + valueWidth + 4, pixel), 0)
            row.icon:SetShown(entry.icon ~= nil and not entry.moneyAmount)
        elseif not tracker then
            row.icon:ClearAllPoints()
            row.icon:SetPoint("TOPLEFT", Snap(4, pixel), -Snap((actualHeight - Snap(16, pixel)) / 2, pixel))
        end
        renderedHeight = renderedHeight + actualHeight + (compactSurface and 0 or readable and Snap(2, pixel) or gap)
        row:Show()
    end
    FinishGroup()
    for index = groupIndex + 1, #(panel.questGroups or {}) do panel.questGroups[index]:Hide() end
    for index = #data + 1, #panel.rows do panel.rows[index]:Hide() end
    local maximumHeight = delves and settings.delvesHeight or settings.questHeight
    local visibleHeight = (settings.content == "quests" or delves) and math.min(renderedHeight, Snap(maximumHeight, pixel)) or renderedHeight
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
    PositionPanels()
    panel:SetShown(editing or settings.enabled)
end

function addon.RefreshPanels()
    addon.questHasTimers = false
    addon.raidUpgradePending = false
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
        { key = "questTracker", label = text.questTracker, kind = LEM.SettingType.Checkbox, default = true },
        { key = "questEvents", label = text.questEvents, kind = LEM.SettingType.Checkbox, default = true },
        { key = "delvesBountifulOnly", label = text.delvesBountifulOnly, kind = LEM.SettingType.Checkbox, default = false },
        { key = "delvesSort", label = text.delvesSort, kind = LEM.SettingType.Dropdown, default = "grade" },
        { key = "delvesHeight", label = text.delvesHeight, kind = LEM.SettingType.Slider, default = 400, min = 150, max = 800, step = 25 },
        { key = "delveQuestsHideCompleted", label = text.delveQuestsHideCompleted, kind = LEM.SettingType.Checkbox, default = false },
        { key = "raidSetsFollowInstance", label = text.raidSetsFollowInstance, kind = LEM.SettingType.Checkbox, default = true },
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
        { key = "anchorTarget", label = text.anchorTarget, kind = LEM.SettingType.Dropdown, default = "screen" },
        { key = "point", label = text.point, kind = LEM.SettingType.Dropdown, default = "TOPRIGHT" },
        { key = "anchorSide", label = text.anchorSide, kind = LEM.SettingType.Dropdown, default = "BOTTOM" },
        { key = "anchorAlign", label = text.anchorAlign, kind = LEM.SettingType.Dropdown, default = "start" },
        { key = "anchorGap", label = text.anchorGap, kind = LEM.SettingType.Slider, default = 8, min = 0, max = 80, step = 1 },
        { key = "anchorOffset", label = text.anchorOffset, kind = LEM.SettingType.Slider, default = 0, min = -200, max = 200, step = 1 },
        { key = "width", label = text.width, kind = LEM.SettingType.Slider, default = 260, min = 180, max = 420, step = 10 },
        { key = "scale", label = text.scale, kind = LEM.SettingType.Slider, default = 1, min = 0.7, max = 1.5, step = 0.05 },
        { key = "style", label = text.style, kind = LEM.SettingType.Dropdown, default = "blizzard" },
        { key = "opacity", label = text.opacity, kind = LEM.SettingType.Slider, default = 0.8, min = 0.2, max = 1, step = 0.02 },
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
                if key == "point" then return settings.anchorTarget ~= "screen" end
                if key == "anchorSide" or key == "anchorAlign" or key == "anchorGap" or key == "anchorOffset" then return settings.anchorTarget == "screen" end
                if key == "rowCount" then return settings.content ~= "preview" end
                if key == "delveQuestsHideCompleted" then return settings.content ~= "delvequests" end
                if key == "raidSetsFollowInstance" then return settings.content ~= "raidsets" end
                if key == "showBars" then return settings.content ~= "preview" and settings.content ~= "quests" and settings.content ~= "delves" end
                if key == "delvesBountifulOnly" or key == "delvesSort" or key == "delvesHeight" then return settings.content ~= "delves" end
                if key == "questTracker" then return settings.content ~= "quests" or not settings.questReadable end
                if key == "questEvents" then return settings.content ~= "quests" or not settings.questReadable or not settings.questTracker end
                if key == "questReadable" or key == "questAuto" or key == "questObjectives" or key == "questDetails" or key == "questColors" or key == "questHeight" then return settings.content ~= "quests" end
                if key == "questAll" then return settings.content ~= "quests" or not settings.questAuto end
                if key == "questLimit" then return settings.content ~= "quests" or not settings.questAuto or settings.questAll end
                return false
            end,
            values = key == "anchorTarget" and { { text = fr and "Écran (libre)" or "Screen (free)", value = "screen" }, { text = text.panel .. (id == "panel1" and " 2" or " 1"), value = id == "panel1" and "panel2" or "panel1" } }
                or key == "point" and { { text = fr and "Haut gauche" or "Top left", value = "TOPLEFT" }, { text = fr and "Haut" or "Top", value = "TOP" }, { text = fr and "Haut droite" or "Top right", value = "TOPRIGHT" }, { text = fr and "Gauche" or "Left", value = "LEFT" }, { text = fr and "Centre" or "Center", value = "CENTER" }, { text = fr and "Droite" or "Right", value = "RIGHT" }, { text = fr and "Bas gauche" or "Bottom left", value = "BOTTOMLEFT" }, { text = fr and "Bas" or "Bottom", value = "BOTTOM" }, { text = fr and "Bas droite" or "Bottom right", value = "BOTTOMRIGHT" } }
                or key == "anchorSide" and { { text = fr and "En dessous" or "Below", value = "BOTTOM" }, { text = fr and "Au-dessus" or "Above", value = "TOP" }, { text = fr and "À gauche" or "Left", value = "LEFT" }, { text = fr and "À droite" or "Right", value = "RIGHT" } }
                or key == "anchorAlign" and { { text = fr and "Début (gauche / haut)" or "Start (left / top)", value = "start" }, { text = fr and "Centre" or "Center", value = "center" }, { text = fr and "Fin (droite / bas)" or "End (right / bottom)", value = "finish" } }
                or key == "content" and addon.contentTypes or key == "delvesSort" and { { text = fr and "Note" or "Grade", value = "grade" }, { text = fr and "Nom" or "Name", value = "name" } } or key == "style" and { { text = "Blizzard", value = "blizzard" }, { text = "Ayije", value = "ayije" }, { text = "Pixels", value = "pixels" } } or nil,
            get = function(layoutName) return Settings(id, layoutName)[key] end,
            set = function(layoutName, value)
                if key == "point" then SaveFreePosition(panel, Settings(id, layoutName), value) end
                if key == "anchorTarget" then
                    if WouldCycle(id, value, layoutName) then DEFAULT_CHAT_FRAME:AddMessage("FunelQOL: " .. text.anchorCycle); return end
                    if value == "screen" and Settings(id, layoutName).anchorTarget ~= "screen" then SaveFreePosition(panel, Settings(id, layoutName)) end
                end
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
        panel.body = CreateFrame("Frame", nil, panel, "BackdropTemplate")
        panel.body:EnableMouse(false)
        panel.body:SetFrameLevel(panel:GetFrameLevel())
        panel.header:SetPoint("TOPLEFT")
        panel.header:SetPoint("TOPRIGHT")
        panel.header:SetHeight(26)
        panel.title = panel.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        panel.title:SetPoint("CENTER", -8, 0)
        panel.title:SetWordWrap(false)
        panel.title:SetText(definition.title)
        panel.arrow = CreateFrame("Frame", nil, panel.header)
        panel.arrow:EnableMouse(false)
        panel.arrow:SetPoint("RIGHT", -9, 0)
        panel.arrow.strokes = {}
        for index = 1, 2 do
            local stroke = panel.arrow:CreateTexture(nil, "OVERLAY")
            stroke:SetColorTexture(0.3, 1, 0.3, 1)
            DisableTextureSnapping(stroke)
            panel.arrow.strokes[index] = stroke
        end
        panel.header:SetScript("OnClick", function()
            if editing then return end
            local settings = Settings(definition.id)
            settings.collapsed = not settings.collapsed
            Render(panel)
        end)
        panel.header:SetScript("OnEnter", function()
            panel.title:SetTextColor(1, 1, 1)
            for _, stroke in ipairs(panel.arrow.strokes) do stroke:SetColorTexture(1, 1, 1, 1) end
        end)
        panel.header:SetScript("OnLeave", function()
            for _, stroke in ipairs(panel.arrow.strokes) do stroke:SetColorTexture(0.3, 1, 0.3, 1) end
            local settings = Settings(definition.id)
            local tracker = settings.content == "delves" or settings.content == "quests" and settings.questReadable and settings.questTracker
            local compact = settings.content ~= "preview" and settings.content ~= "quests" and settings.content ~= "delves"
            panel.title:SetTextColor(1, (tracker or compact) and 1 or 0.82, (tracker or compact) and 1 or 0)
        end)
        panels[#panels + 1] = panel
        local default = { point = "TOPRIGHT", x = definition.x, y = definition.y }
        LEM:AddFrame(panel, function(_, layoutName, point, x, y)
            local settings = Settings(definition.id, layoutName)
            -- Dragging / nudging deliberately releases the link, as in EUI movers.
            settings.anchorTarget = "screen"
            settings.point, settings.x, settings.y = point, x, y
            Render(panel)
        end, default)
        AddSettings(panel)
    end
    ApplyLayout(LEM:GetActiveLayoutName())

    local events = CreateFrame("Frame")
    events:RegisterEvent("UI_SCALE_CHANGED")
    events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    events:RegisterEvent("AREA_POIS_UPDATED")
    events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("UPDATE_UI_WIDGET")
    events:RegisterEvent("UPDATE_ALL_UI_WIDGETS")
    events:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE")
    for _, event in ipairs({ "PLAYER_MONEY", "CURRENCY_DISPLAY_UPDATE", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE", "TRAIT_CONFIG_UPDATED", "PLAYER_SPECIALIZATION_CHANGED", "SPELLS_CHANGED", "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "QUEST_WATCH_LIST_CHANGED", "QUEST_DATA_LOAD_RESULT", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "SUPER_TRACKING_CHANGED", "SUPER_TRACKING_PATH_UPDATED", "QUEST_POI_UPDATE" }) do
        events:RegisterEvent(event)
    end
    events:RegisterEvent("ACHIEVEMENT_EARNED")
    events:RegisterEvent("CRITERIA_UPDATE")
    for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_DIFFICULTY_CHANGED", "TRANSMOG_COLLECTION_UPDATED", "CHALLENGE_MODE_MAPS_UPDATE", "WEEKLY_REWARDS_UPDATE", "WEEKLY_REWARDS_ITEM_CHANGED", "UPDATE_FACTION",
        "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "MAJOR_FACTION_UNLOCKED", "GET_ITEM_INFO_RECEIVED" }) do events:RegisterEvent(event) end
    local delveEvents = { AREA_POIS_UPDATED = true, ZONE_CHANGED_NEW_AREA = true, PLAYER_ENTERING_WORLD = true,
        ACTIVE_DELVE_DATA_UPDATE = true, UPDATE_ALL_UI_WIDGETS = true, ACHIEVEMENT_EARNED = true, CRITERIA_UPDATE = true }
    events:SetScript("OnEvent", function(_, event, info)
        if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "GET_ITEM_INFO_RECEIVED" or event == "PLAYER_ENTERING_WORLD" or event == "TRANSMOG_COLLECTION_UPDATED" then addon.InvalidateRaidActions() end
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "TRANSMOG_COLLECTION_UPDATED" then addon.InvalidateRaidSets() end
        if event == "UPDATE_UI_WIDGET" then
            if not addon.IsDelveWidget(info and info.widgetID) then return end
            addon.InvalidateDelves()
        elseif delveEvents[event] then addon.InvalidateDelves() end
        addon.RefreshPanels()
    end)
    local elapsed = 0
    events:SetScript("OnUpdate", function(_, delta)
        if not addon.questHasTimers and not addon.raidUpgradePending then elapsed = 0; return end
        elapsed = elapsed + delta
        if elapsed >= (addon.questHasTimers and 1 or 2) then
            elapsed = 0
            if addon.raidUpgradePending then addon.InvalidateRaidActions() end
            addon.RefreshPanels()
        end
    end)
    -- UIParent:SetScale can be called directly by UI addons without a CVar event.
    hooksecurefunc(UIParent, "SetScale", addon.RefreshPanels)
end

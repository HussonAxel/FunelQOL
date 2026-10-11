local addonName, addon = ...
local LEM = addon.LibEditMode
local text = addon.panelText
local fr = GetLocale() == "frFR"
local panels = {}
local dragging = {}
addon.panels = panels

local definitions = {}
-- Panels beyond the first two cascade leftwards, then down, from the upper right.
local function Definition(index)
    if not definitions[index] then
        local column, line = (index - 1) % 4, math.floor((index - 1) / 4)
        definitions[index] = { id = "panel" .. index, index = index, title = text.panel .. " " .. index, x = -32 - column * 280, y = -220 - line * 40 }
    end
    return definitions[index]
end

-- Only panels that currently exist are valid anchor targets.
local function IsPanelID(id)
    local index = type(id) == "string" and tonumber(string.match(id, "^panel(%d+)$"))
    return index ~= nil and panels[index] ~= nil
end

-- Bars and progress fills share the d1 texture; backgrounds keep each style's own texture.
local styles = {
    blizzard = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", fill = addon.media.statusbar, backgroundTexture = "Interface\\TargetingFrame\\UI-StatusBar", edgeSize = 8 },
    ayije = { edgeFile = addon.media.ayije.borders.Ayije_Thin.edgeFile, fill = addon.media.statusbar, backgroundTexture = addon.media.ayije.statusbars.Ayije_light, edgeSize = 16, centered = true, inkInset = 9 / 28 },
    pixels = { edgeFile = addon.media.borders.pixels.edgeFile, separator = addon.media.borders.pixels.separatorHorizontal, fill = addon.media.statusbar, backgroundTexture = addon.media.textures.pixelsBackground, background = 0.1, edgeSize = 16, centered = true, inkInset = 10 / 28 },
    refine = { edgeFile = addon.media.refine.border, separator = addon.media.refine.border,
        -- RefineUI's TopEdge cell, rotated from the vertical border atlas strip.
        separatorTexCoords = { 66 / 256, 30 / 32, 94 / 256, 30 / 32, 66 / 256, 2 / 32, 94 / 256, 2 / 32 },
        fill = addon.media.statusbar, backgroundTexture = addon.media.refine.fill, font = addon.media.refine.font, edgeSize = 12, centered = true, inkInset = 6 / 28, background = 0.1, borderColor = { 0.6, 0.6, 0.6, 1 }, hoverColor = { 1, 0.82, 0, 1 } },
}
local styleChoices = {
    { text = "Blizzard", value = "blizzard" },
    { text = "Ayije", value = "ayije" },
    { text = "Pixels", value = "pixels" },
    { text = "RefineUI", value = "refine" },
}
local function SetPanelFont(region, size, flags, settings)
    addon.SetFont(region, size, flags, styles[settings.style].font)
end
local activeLayout = "Modern"
local editing = false
text.anchorTarget = fr and "Ancrer à" or "Anchor to"
text.anchorSide = fr and "Côté de la cible" or "Target side"
text.anchorAlign = fr and "Alignement" or "Alignment"
text.anchorGap = fr and "Espacement" or "Spacing"
text.anchorOffset = fr and "Décalage le long du bord" or "Offset along edge"
text.point = fr and "Ancre écran" or "Screen anchor"
text.anchorCycle = fr and "Ce lien créerait une boucle d’ancres." or "This link would create an anchor cycle."
text.removeTracker = fr and "Supprimer ce tracker" or "Delete this tracker"
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

-- Settings() runs per panel on every routed event: keep its constant tables shared.
local defaultsCache = {}
local appearanceKeys = { "width", "scale", "fontSize", "rowHeight", "style", "opacity" }
local sharedAppearance = {}
for _, key in ipairs(appearanceKeys) do sharedAppearance[key] = true end
local panelPoints = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }
local function Settings(id, layoutName)
    local layouts = addon.panelDB.layouts
    layoutName = layoutName or activeLayout
    if type(layouts[layoutName]) ~= "table" then layouts[layoutName] = {} end
    if type(layouts[layoutName][id]) ~= "table" then layouts[layoutName][id] = {} end
    local settings = layouts[layoutName][id]
    -- Apply the requested visual refresh once to existing layouts, while
    -- allowing subsequent opacity adjustments to persist.
    if settings.backgroundRevision ~= 2 then settings.opacity = 1; settings.backgroundRevision = 2 end
    -- Pixels replaces the former Blizzard default once; later choices persist.
    if settings.styleRevision ~= 1 then
        local reference = layouts[layoutName].panel1
        if settings.style == nil and type(reference) == "table" and reference.styleRevision == 1 then
            settings.style = reference.style
        elseif settings.style == nil or settings.style == "blizzard" then settings.style = "pixels" end
        settings.styleRevision = 1
    end
    local defaults = defaultsCache[id]
    if not defaults then
        local definition = Definition(tonumber(string.match(id, "^panel(%d+)$")))
        defaults = {
            point = "TOPRIGHT", x = definition.x, y = definition.y,
            title = definition.title, width = 260, scale = 1, enabled = true,
            collapsed = false, style = "pixels", opacity = 1,
            fontSize = 11, rowHeight = 22, rowCount = 3, showBars = true, content = "preview",
            questTracker = true, questEvents = true, questReadable = true, questAuto = true, questAll = true, questHeight = 400, questLimit = 3, questObjectives = true, questDetails = true, questColors = true,
            delvesBountifulOnly = false, delvesSort = "grade", delvesHeight = 400,
            delveQuestsHideCompleted = false,
            raidSetsFollowInstance = true,
            anchorTarget = "screen", anchorSide = "BOTTOM", anchorAlign = "start", anchorGap = 8, anchorOffset = 0,
        }
        defaultsCache[id] = defaults
    end
    for key, value in pairs(defaults) do
        if type(settings[key]) ~= type(value) then
            local reference = layouts[layoutName].panel1
            settings[key] = sharedAppearance[key] and type(reference) == "table" and type(reference[key]) == type(value) and reference[key] or value
        end
    end
    local validContent = false
    for _, kind in ipairs(addon.contentTypes) do if settings.content == kind.value then validContent = true end end
    if not validContent then settings.content = "preview" end
    if settings.delvesSort ~= "grade" and settings.delvesSort ~= "name" then settings.delvesSort = "grade" end
    if type(settings.questSections) ~= "table" then settings.questSections = {} end
    if type(settings.delvesSections) ~= "table" then settings.delvesSections = {} end
    if not styles[settings.style] then settings.style = "pixels" end
    if not panelPoints[settings.point] then settings.point = "TOPRIGHT" end
    if not IsPanelID(settings.anchorTarget) or settings.anchorTarget == id then settings.anchorTarget = "screen" end
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

-- Older layouts save their localized slot name as the title. Recognize both
-- locales and old slot numbers after deletion, without rewriting custom names.
local function PanelTitle(settings)
    local title = settings.title
    local generic = string.upper(title)
    if settings.titleOverride == title or not (string.match(generic, "^PANEL %d+$") or string.match(generic, "^PANNEAU %d+$")) then
        return title
    end
    for _, kind in ipairs(addon.contentTypes) do
        if kind.value == settings.content then title = kind.text; break end
    end
    if settings.content == "quests" and settings.questReadable and settings.questTracker then title = text.trackerTitle end
    if settings.content == "raidsets" then title = addon.GetRaidSetTitle(settings) or title end
    if settings.content == "raidcollection" then title = addon.GetRaidCollectionTitle(settings) or title end
    if settings.content == "rares" then title = addon.GetRareTitle() or title end
    return title
end

local function Snap(value, pixel)
    return math.floor(value / pixel + 0.5 + 0.001) * pixel
end

local function WouldCycle(id, target, layoutName)
    local seen = { [id] = true }
    while IsPanelID(target) do
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
        settings.positionHeight = panel:GetHeight()
    end
end

-- Compare rectangles in UIParent units so differently scaled panels snap alike.
local function PanelRect(panel)
    local left, top = panel:GetLeft(), panel:GetTop()
    if not left or not top then return end
    local scale = panel:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return left * scale, top * scale, panel:GetWidth() * scale, panel:GetHeight() * scale
end

local snapSides = { "BOTTOM", "TOP", "LEFT", "RIGHT" }
local snapAlignments = { "start", "center", "finish" }
local snapLabels = fr and { BOTTOM = "dessous", TOP = "dessus", LEFT = "à gauche", RIGHT = "à droite" }
    or { BOTTOM = "below", TOP = "above", LEFT = "left", RIGHT = "right" }
local function FindAnchor(panel)
    if InCombatLockdown() then return end
    local left, top, width, height = PanelRect(panel)
    if not left then return end
    local best, distance = nil, 56 * 56
    local anchors = _G.RefineUI and _G.RefineUI.EditModeAnchors
    for _, target in ipairs(panels) do
        if target ~= panel and target:IsVisible() and not dragging[target]
            and not WouldCycle(panel.definition.id, target.definition.id)
            and not (anchors and anchors:OwnsPosition(target)) then
            local x, y, w, h = PanelRect(target)
            if x then
                for _, side in ipairs(snapSides) do
                    for index, align in ipairs(snapAlignments) do
                        local fraction = (index - 1) / 2
                        local snapX, snapY
                        if side == "BOTTOM" or side == "TOP" then
                            snapX = x + (w - width) * fraction
                            snapY = side == "BOTTOM" and y - h - 8 or y + height + 8
                        else
                            snapX = side == "LEFT" and x - width - 8 or x + w + 8
                            snapY = y - (h - height) * fraction
                        end
                        local dx, dy = left - snapX, top - snapY
                        local delta = dx * dx + dy * dy
                        if delta < distance then
                            best, distance = { target = target, side = side, align = align, x = snapX, y = snapY, width = width, height = height }, delta
                        end
                    end
                end
            end
        end
    end
    return best
end

local function AutoAnchor(panel, settings)
    local best = FindAnchor(panel)
    if best then
        settings.anchorTarget, settings.anchorSide, settings.anchorAlign = best.target.definition.id, best.side, best.align
        settings.anchorGap, settings.anchorOffset = 8, 0
    end
end

-- A ghost of the final position uses exactly the same candidate as release.
-- It is independent of the moving frame and never intercepts mouse input.
local anchorPreview
local function HideAnchorPreview(panel)
    if anchorPreview and (not panel or anchorPreview.owner == panel) then
        anchorPreview:Hide()
        anchorPreview.owner, anchorPreview.candidate = nil, nil
    end
end
local function UpdateAnchorPreview(panel)
    local candidate = panel:IsVisible() and FindAnchor(panel)
    if not candidate then HideAnchorPreview(panel); return end
    if not anchorPreview then
        anchorPreview = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        anchorPreview:SetFrameStrata("DIALOG")
        anchorPreview:EnableMouse(false)
        anchorPreview:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
        anchorPreview:SetBackdropColor(0.1, 0.8, 0.3, 0.18)
        anchorPreview:SetBackdropBorderColor(0.2, 1, 0.4, 1)
        anchorPreview.label = anchorPreview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        anchorPreview.label:SetPoint("CENTER")
        anchorPreview.label:SetTextColor(0.3, 1, 0.4)
        addon.anchorPreview = anchorPreview
    end
    anchorPreview.owner, anchorPreview.candidate = panel, candidate
    anchorPreview:ClearAllPoints()
    anchorPreview:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", candidate.x, candidate.y)
    anchorPreview:SetSize(candidate.width, candidate.height)
    anchorPreview.label:SetWidth(math.max(100, candidate.width - 12))
    anchorPreview.label:SetText((fr and "Relâchez pour ancrer" or "Release to anchor") .. "\n" .. PanelTitle(Settings(candidate.target.definition.id)) .. " · " .. snapLabels[candidate.side])
    anchorPreview:Show()
end

local function PositionPanels()
    local lookup, placed = {}, {}
    local anchors = _G.RefineUI and _G.RefineUI.EditModeAnchors
    for _, panel in ipairs(panels) do
        lookup[panel.definition.id] = panel
        local settings = Settings(panel.definition.id)
        if WouldCycle(panel.definition.id, settings.anchorTarget) then settings.anchorTarget = "screen" end
        -- Clear stale engine links before applying a changed dependency graph.
        if not dragging[panel] and not (anchors and anchors:OwnsPosition(panel)) then panel:ClearAllPoints() end
    end
    local function Place(panel)
        if placed[panel] then return end
        placed[panel] = true
        -- Keep global links attached throughout redraws instead of briefly
        -- restoring an obsolete screen position until RefineUI's timer runs.
        if dragging[panel] or anchors and anchors:OwnsPosition(panel) then return end
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
        else
            -- Screen positions describe the panel at the height it had when
            -- placed. Keep its top/title fixed when its body opens or changes.
            if type(settings.positionHeight) ~= "number" or settings.positionHeight <= 0 then
                settings.positionHeight = panel:GetHeight()
            end
            y = y + (settings.positionHeight - panel:GetHeight()) * (1 - screenPoints[point][2])
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
    if anchors then anchors:Refresh() end
end

local function DisableTextureSnapping(texture)
    if texture and texture.SetSnapToPixelGrid then
        texture:SetSnapToPixelGrid(false)
        texture:SetTexelSnappingBias(0)
    end
end

local defaultBorderColor = { 0.38, 0.35, 0.29, 1 }
local compactBorderColor = { 0.3, 0.3, 0.3, 1 }
local compactColors = { currencies = { 0.15, 0.8, 1 }, professions = { 0.3, 1, 0.3 }, custom = { 1, 1, 1 } }
local function PaintSeparator(texture, style, pixel, r, g, b, alpha)
    local offset = 0
    if style and style.separatorTexCoords then
        texture:SetTexture(style.separator)
        texture:SetTexCoord(unpack(style.separatorTexCoords))
        texture:SetVertexColor(style.borderColor[1], style.borderColor[2], style.borderColor[3], alpha)
        local height = math.max(2, math.floor(style.edgeSize / pixel / 2 + 0.5) * 2) * pixel
        texture:SetHeight(height)
        offset = -height / 2
    elseif style and style.separator then
        -- The bright ridge is centred at texel 5.5 from the top. Sample a
        -- symmetric band around it, rather than centring its transparent padding.
        texture:SetTexture(style.separator)
        texture:SetTexCoord(0, 1, 1 / 32, 10 / 32)
        texture:SetVertexColor(compactBorderColor[1], compactBorderColor[2], compactBorderColor[3], alpha)
        -- An even physical-pixel height keeps both edges and the ridge centred
        -- on the boundary without rounding the half-height independently.
        local height = math.max(2, math.floor(style.edgeSize * 9 / 32 / pixel / 2 + 0.5) * 2) * pixel
        texture:SetHeight(height)
        offset = -height / 2
    else
        texture:SetTexCoord(0, 1, 0, 1)
        texture:SetVertexColor(1, 1, 1, 1)
        if style and style.borderColor then r, g, b = unpack(style.borderColor) end
        texture:SetColorTexture(r, g, b, alpha)
        texture:SetHeight(pixel)
    end
    DisableTextureSnapping(texture)
    return offset
end
local function PaintBorder(frame)
    local color = frame.normalBorderColor or defaultBorderColor
    if frame.isHovered then
        if frame.hoverBorderColor then color = frame.hoverBorderColor
        elseif color == defaultBorderColor then color = { 0.85, 0.72, 0.38, 1 }
        else color = { math.min(1, color[1] + 0.2), math.min(1, color[2] + 0.2), math.min(1, color[3] + 0.2), color[4] } end
    end
    frame.border:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
end

-- Preserve the provider's full colour and the selected texture's contrast.
local function SetOpaqueBarColor(bar, r, g, b)
    bar:SetStatusBarColor(r, g, b, 1)
end

local function SetBackdrop(frame, style, opacity, pixel, contentLevel, color)
    if not frame.background then
        frame.background = frame:CreateTexture(nil, "ARTWORK", nil, -1)
        frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.border:EnableMouse(false)
    end
    -- Content occupies the host rect. Only the edge art extends outside it.
    local inset = style.centered and 0 or Snap(3, pixel)
    local reach = style.centered and Snap(style.edgeSize / 2, pixel) or 0
    local level = (contentLevel or frame:GetFrameLevel()) + 2
    local background = style.background or 0.035
    frame.background:SetTexture(style.backgroundTexture or style.fill)
    frame.background:SetVertexColor(background, background, background, opacity)
    frame.background:SetAlpha(1)
    frame.normalBorderColor = style.borderColor and (not color or color == defaultBorderColor or color == compactBorderColor) and style.borderColor or color or defaultBorderColor
    frame.hoverBorderColor = frame.normalBorderColor == style.borderColor and style.hoverColor or nil
    -- BackdropTemplate:SetBackdrop rebuilds nine textures in Lua; only redo it when inputs change.
    local key = style.edgeFile .. ":" .. style.edgeSize .. ":" .. inset .. ":" .. reach .. ":" .. level
    if frame.backdropKey == key then PaintBorder(frame); return end
    frame.backdropKey = key
    frame.background:ClearAllPoints()
    frame.background:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    frame.background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    DisableTextureSnapping(frame.background)
    frame.border:ClearAllPoints()
    -- Snap one positive reach and mirror it: rounding +/- half pixels separately is asymmetric.
    frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -reach, reach)
    frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", reach, -reach)
    frame.border:SetFrameLevel(level)
    frame.border:SetBackdrop({ edgeFile = style.edgeFile, edgeSize = style.edgeSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    PaintBorder(frame)
    for _, region in ipairs({ frame.border:GetRegions() }) do DisableTextureSnapping(region) end
end

local function CreateRow(panel)
    local row = CreateFrame("Button", nil, panel.content, "BackdropTemplate")
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetHeight(22)
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetPoint("TOPLEFT", 3, -3)
    row.bar:SetPoint("BOTTOMRIGHT", -3, 3)
    row.bar:SetFrameLevel(row:GetFrameLevel())
    SetOpaqueBarColor(row.bar, 0.12, 0.42, 0.62)
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
            if data.questXPText then GameTooltip:AddLine(data.questXPText, 0.3, 1, 0.3, true) end
            for _, objective in ipairs(data.objectives or {}) do
                GameTooltip:AddLine(objective.text, objective.finished and 0.3 or 1, 1, objective.finished and 0.3 or 1, true)
            end
        elseif data.raidCollectionLink then
            GameTooltip:SetHyperlink(data.raidCollectionLink)
            for _, line in ipairs(data.tooltipLines or {}) do GameTooltip:AddLine(line, 1, 1, 1, true) end
        elseif data.currencyID then
            GameTooltip:SetCurrencyByID(data.currencyID)
        else
            GameTooltip:SetText(data.name, 1, 0.82, 0)
            if data.raidSetID then
                GameTooltip:SetMinimumWidth(420, true)
                GameTooltip:AddLine(data.raidCollectionText, 1, 1, 1)
            elseif data.valueText and data.valueText ~= "" then GameTooltip:AddLine(data.valueText, 1, 1, 1) end
            for _, line in ipairs(data.tooltipLines or {}) do GameTooltip:AddLine(line, 1, 1, 1, true) end
        end
        local hint = addon.GetRowActionHint(data)
        if hint then GameTooltip:AddLine(hint, 1, 1, 1, true) end
        GameTooltip:Show()
        self.isHovered = true
        PaintBorder(self)
    end)
    row:SetScript("OnClick", function(self, button)
        if editing then return end
        if button == "RightButton" then
            addon.RowRightClick(self.data)
            return
        end
        if self.data.rareMapID and (IsShiftKeyDown() or not self.data.rareHasRewards) then
            if not InCombatLockdown() and OpenWorldMap then OpenWorldMap(self.data.rareMapID) end
        elseif self.data.rareMapID then
            addon.ToggleRare(self.data.rareNpcID)
            addon.RefreshPanels()
        elseif self.data.raidCollectionBossKey then
            addon.ToggleRaidCollectionBoss(Settings(panel.definition.id), self.data.raidCollectionBossKey)
            addon.RefreshPanels()
        elseif self.data.raidCollectionKind then
            addon.PreviewRaidCollectionReward(self.data)
        elseif self.data.raidSetID then
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

local function UpdateScrollFades(panel)
    if not panel.fadeTop then return end
    local scroll, maximum = panel.viewport:GetVerticalScroll(), panel.scrollMaximum or 0
    local visible = panel.viewport:IsShown() and maximum > 0
    panel.fadeTop:SetShown(visible and scroll > 0)
    panel.fadeBottom:SetShown(visible and scroll < maximum)
end

addon.sectionOpenIcon ="|TInterface\\Buttons\\UI-MinusButton-Up:0|t "
addon.sectionClosedIcon = "|TInterface\\Buttons\\UI-PlusButton-Up:0|t "

local function LayoutTrackerRow(row, entry, settings, width, pixel, compact)
    local function P(value) return Snap(value, pixel) end
    row.value:Hide()
    row.bar:Hide()
    row.border:Hide()
    row.background:Hide()
    SetPanelFont(row.label, settings.fontSize + (compact and (entry.isQuestHeader and 1 or 0) or entry.isQuestHeader and 2 or 1), compact and "OUTLINE" or "", settings)
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
        SetPanelFont(row.value, settings.fontSize + 3, "", settings)
        row.value:SetWidth(P(24))
        row.value:SetText(entry.delveGrade)
        local color = addon.delveGradeColors[entry.delveGrade] or { 0.65, 0.7, 0.75 }
        row.value:SetTextColor(color[1], color[2], color[3])
        row.value:Show()
    end
    if section then
        -- The menu font has no "−" glyph: use Blizzard's plus/minus art instead.
        row.label:SetText((entry.sectionCollapsed and addon.sectionClosedIcon or addon.sectionOpenIcon) .. (compact and string.upper(entry.name) or entry.name))
        row.label:SetTextColor(1, 1, 1)
        row.background:SetVertexColor(0.3, 0.24, 0.06, 1)
        row.background:SetShown(not compact)
        row.trackerLine = row.trackerLine or row:CreateTexture(nil, "ARTWORK")
        row.trackerLine:ClearAllPoints()
        local offset = PaintSeparator(row.trackerLine, styles[settings.style], pixel,
            compact and 0.3 or 0.65, compact and 0.3 or 0.5, compact and 0.3 or 0.12, 0.8)
        row.trackerLine:SetPoint("BOTTOMLEFT", P(8), offset)
        row.trackerLine:SetPoint("BOTTOMRIGHT", -P(8), offset)
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
    local height = row.label:GetStringHeight() + (compact and entry.questObjective and 7 or 5)
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
        SetPanelFont(row.meta, compact and math.max(10, settings.fontSize - 1) or settings.fontSize, "", settings)
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

local batching = false
local refreshEvents
local function UpdatePolling()
    local timed, pending = false, false
    for _, panel in ipairs(panels) do
        if panel.pollingEnabled then
            timed = timed or panel.questHasTimers or false
            pending = pending or panel.raidUpgradePending or false
        end
    end
    addon.questHasTimers, addon.raidUpgradePending = timed, pending
    if refreshEvents then refreshEvents:SetShown(timed or pending) end
end
local function Render(panel)
    local settings = Settings(panel.definition.id)
    panel.pollingEnabled = editing or settings.enabled
    local style = styles[settings.style]
    panel:SetScale(settings.scale)
    local pixel = PixelUnit(panel)
    local width = Snap(settings.width, pixel)
    local questTracker = settings.content == "quests" and settings.questReadable and settings.questTracker
    local delves = settings.content == "delves"
    local tracker = questTracker or delves
    local compact = settings.content ~= "preview" and settings.content ~= "quests" and not delves
    local compactSurface = compact or questTracker
    -- All content types share the same title bar, including collapsed trackers.
    local headerHeight = Snap(math.max(24, settings.fontSize + 8), pixel)
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
    -- Compact rows share the body border: no vertical overscan into its header.
    local verticalPadding = compact and 0 or clipPadding
    -- Scrolling panels clip at the body edge, not inside the header gap.
    local questInset = (settings.content == "quests" or settings.content == "rares" or settings.content == "teleports" or delves) and verticalPadding or 0
    panel.viewport:ClearAllPoints()
    panel.viewport:SetPoint("TOPLEFT", -clipPadding, -contentTop + verticalPadding - questInset)
    panel.viewport:SetPoint("TOPRIGHT", clipPadding, -contentTop + verticalPadding - questInset)
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
    local title = PanelTitle(settings)
    panel.title:SetWidth(width - Snap(40, pixel))
    SetPanelFont(panel.title, settings.fontSize + (delves and 3 or 0), delves and "" or "OUTLINE", settings)
    -- SetText with an unchanged string keeps the old layout, which stays blank when it was
    -- laid out before the font file loaded: relayout the title on every render.
    panel.title:SetText("")
    panel.title:SetText(compactSurface and string.upper(title) or title)
    panel.title:SetTextColor(1, (tracker or compact) and 1 or 0.82, (tracker or compact) and 1 or 0)
    panel.editModeName = "FunelQOL · " .. title
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
    addon.questHasTimers, addon.raidUpgradePending = false, false
    local data = delves and addon.GetDelveRows(settings) or tracker and addon.GetTrackerRows(settings) or addon.GetPanelRows(settings)
    panel.questHasTimers, panel.raidUpgradePending = addon.questHasTimers, addon.raidUpgradePending
    local renown = settings.content == "renown"
    local renownValueWidth, renownFontSize = 0, settings.fontSize
    if renown then
        panel.valueMeasure = panel.valueMeasure or panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        local available = rowWidth - Snap(6 + 8 + 8 + 26, pixel) - 30
        repeat
            SetPanelFont(panel.valueMeasure, renownFontSize, "OUTLINE", settings)
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
        for _, reward in ipairs(row.rewards or {}) do reward:Hide() end
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
            SetBackdrop(currentGroup, style, settings.opacity, pixel, currentGroup:GetFrameLevel(), entry.borderColor)
            currentGroup:Show()
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", clipPadding + rowInset, -verticalPadding - renderedHeight)
        row:SetWidth(rowWidth)
        row:SetHeight(rowHeight)
        SetBackdrop(row, style, settings.opacity, pixel, row.bar:GetFrameLevel(), entry.borderColor)
        row.background:SetShown(not readable and not compact)
        row.border:SetShown(not readable and not compact)
        if not row.separator then row.separator = row.label:GetParent():CreateTexture(nil, "ARTWORK") end
        local nextEntry = data[index + 1]
        row.separator:SetShown(compact and nextEntry ~= nil or questTracker and nextEntry and not entry.trackerSection and (nextEntry.isQuestHeader or nextEntry.trackerSection) or false)
        row.separator:ClearAllPoints()
        local separatorOffset = PaintSeparator(row.separator, style, pixel,
            compact and 0.35 or 0.2, compact and 0.35 or 0.2, compact and 0.35 or 0.2, compact and 1 or 0.7)
        row.separator:SetPoint("BOTTOMLEFT", 0, separatorOffset)
        row.separator:SetPoint("BOTTOMRIGHT", 0, separatorOffset)
        SetPanelFont(row.label, settings.fontSize, "OUTLINE", settings)
        SetPanelFont(row.value, renown and renownFontSize or settings.fontSize, "OUTLINE", settings)
        row.value:SetTextColor(1, 1, 1)
        row.bar:SetStatusBarTexture(style.fill)
        local gaugeMaximum = entry.gaugeMaximum or entry.maximum or 0
        local gaugeValue = entry.gaugeValue or entry.value or 0
        local compactGauge = compact and gaugeMaximum > 0 and (entry.gaugeMaximum ~= nil or settings.content == "professions" or settings.content == "raidsets")
        local gaugeColor = entry.compactColor or entry.labelColor or {0.12, 0.42, 0.62}
        if compactGauge then SetOpaqueBarColor(row.bar, gaugeColor[1], gaugeColor[2], gaugeColor[3])
        else SetOpaqueBarColor(row.bar, 0.12, 0.42, 0.62) end
        local barTexture = row.bar:GetStatusBarTexture()
        barTexture:SetDrawLayer("ARTWORK", 0)
        barTexture:SetAlpha(1)
        DisableTextureSnapping(barTexture)
        local padding = compactGauge and 0 or Snap(3, pixel)
        row.bar:ClearAllPoints()
        row.bar:SetPoint("TOPLEFT", padding, -padding)
        row.bar:SetPoint("BOTTOMRIGHT", -padding, padding)
        row.bar:SetMinMaxValues(0, math.max(1, gaugeMaximum))
        row.bar:SetValue(math.max(0, math.min(gaugeValue, math.max(1, gaugeMaximum))))
        row.bar:SetShown(settings.showBars and gaugeMaximum > 0 and (not compact or compactGauge))
        row.icon:SetTexture(entry.icon)
        row.icon:SetTexCoord(4 / 64, 60 / 64, 4 / 64, 60 / 64)
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
        -- Larger square icons with whole-pixel dimensions. Leave breathing room
        -- inside the row; all compact rows reserve this same column.
        local desiredIconSize = math.min(entry.iconSize or 20, rowHeight - Snap(4, pixel))
        local compactIconSize = math.max(2, math.floor(desiredIconSize / pixel / 2)) * 2 * pixel
        -- Reserve the icon column even on rows without an icon, so changing
        -- content does not move the label/value boundary.
        local iconSpace = compact and (compactIconSize + Snap(6, pixel)) or 0
        if renown then row.value:SetPoint("RIGHT", -valueInset - iconSpace, 0) end
        local availableWidth = rowWidth - labelStart - valueInset - valueGap - iconSpace - 30
        local naturalWidth = row.value:GetUnboundedStringWidth()
        if entry.moneyAmount or entry.fitValue then
            -- Give all denominations room before shortening the label. On narrow
            -- panels, reduce just the money font until the full amount fits.
            local moneyFontSize = settings.fontSize
            while naturalWidth > availableWidth and moneyFontSize > 8 do
                moneyFontSize = moneyFontSize - 1
                SetPanelFont(row.value, moneyFontSize, "OUTLINE", settings)
                if entry.moneyAmount then row.value:SetText(addon.GetMoneyText(entry.moneyAmount, moneyFontSize)) end
                naturalWidth = row.value:GetUnboundedStringWidth()
            end
        end
        local valueWidth = math.ceil(math.min((entry.moneyAmount or entry.fitValue) and availableWidth or rowWidth * 0.48, naturalWidth) / pixel) * pixel
        if compact and not renown then
            valueWidth = math.min(availableWidth, math.max(valueWidth, Snap(rowWidth * 0.38, pixel)))
        end
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
                renderedHeight = renderedHeight + Snap(questTracker and 10 or 8, pixel)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", clipPadding + rowInset, -verticalPadding - renderedHeight)
            end
            actualHeight = LayoutTrackerRow(row, entry, settings, rowWidth, pixel, questTracker)
        elseif readable and (entry.isQuestHeader or entry.questObjective) then
            local isHeader = entry.isQuestHeader
            local fontSize = settings.fontSize + (isHeader and 2 or 1)
            SetPanelFont(row.label, fontSize, "", settings)
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
                SetPanelFont(row.meta, math.max(10, settings.fontSize - 1), "", settings)
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
                    SetPanelFont(crest.count, fontSize, "OUTLINE", settings)
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
        if entry.rewards and #entry.rewards > 0 then
            -- Name and collection count on the first line, then a wrapping grid of
            -- bordered icons. Tall rows are fine: the panel scrolls.
            row.rewards = row.rewards or {}
            -- Styled grids (teleports, vault) frame each icon with the panel's border style.
            local styled, castable = entry.styledRewards, entry.castRewards
            local texturedBorder = styled or settings.style == "refine"
            local iconSize, rewardGap, gridInset = Snap(26, pixel), Snap(4, pixel), Snap(6, pixel)
            if settings.style == "refine" then rewardGap = math.ceil((4 + outerInk * 2) / pixel) * pixel end
            local iconInset = styled and not style.centered and Snap(3, pixel) or pixel * 2
            -- Icons are 64x64. Showing the central 56 texels on exactly 56 or 28 screen
            -- pixels (full size or the next mip level) keeps them sharp at any UI scale.
            local iconCoords = styled and { 4 / 64, 60 / 64, 4 / 64, 60 / 64 } or { 0.08, 0.92, 0.08, 0.92 }
            if styled then
                iconSize = (28 / pixel >= 42 and 56 or 28) * pixel + iconInset * 2
                rewardGap = rewardGap + math.ceil(outerInk * 2 / pixel - 0.001) * pixel
            end
            -- Teleport grids need one allowance for the two outer borders,
            -- plus a small visible gap. The generic styled-grid path above
            -- adds the RefineUI border allowance twice.
            if castable and entry.iconsOnly then
                rewardGap = Snap(2, pixel) + math.ceil(outerInk * 2 / pixel - 0.001) * pixel
            end
            local perLine = math.max(1, math.floor((rowWidth - gridInset * 2 + rewardGap) / (iconSize + rewardGap)))
            -- Wide tiles (vault slots) share the whole line: icon on the left, then the
            -- caption over a progress fill.
            local wide = entry.wideRewards and #entry.rewards > 0
            local tileWidth = iconSize
            if wide then
                perLine = #entry.rewards
                tileWidth = math.max(iconSize, math.floor((rowWidth - gridInset * 2 - rewardGap * (perLine - 1)) / perLine / pixel) * pixel)
                perLine = math.max(1, math.min(perLine, math.floor((rowWidth - gridInset * 2 + rewardGap) / (tileWidth + rewardGap))))
            end
            local lines = math.ceil(#entry.rewards / perLine)
            -- Icon-only rows (teleports) have no title line above the grid.
            local gridTop = entry.iconsOnly and gridInset or rowHeight
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row, "TOPLEFT", labelStart, -Snap(rowHeight / 2, pixel))
            row.value:ClearAllPoints()
            row.value:SetPoint("RIGHT", row, "TOPRIGHT", -valueInset, -Snap(rowHeight / 2, pixel))
            for rewardIndex, info in ipairs(entry.rewards) do
                local reward = row.rewards[rewardIndex]
                if not reward then
                    reward = CreateFrame("Frame", nil, row.label:GetParent())
                    reward.background = reward:CreateTexture(nil, "BACKGROUND")
                    reward.background:SetAllPoints()
                    reward.background:SetColorTexture(0, 0, 0, 1)
                    reward.fill = reward:CreateTexture(nil, "ARTWORK", nil, -1)
                    reward.icon = reward:CreateTexture(nil, "ARTWORK")
                    reward.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    reward.edges = {}
                    for edgeIndex = 1, 4 do reward.edges[edgeIndex] = reward:CreateTexture(nil, "BORDER") end
                    reward.check = reward:CreateTexture(nil, "OVERLAY")
                    reward.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                    reward.check:SetPoint("BOTTOMRIGHT", 1, -1)
                    -- Short overlay text (vault item level or progress), above the border frame.
                    reward.overlay = CreateFrame("Frame", nil, reward)
                    reward.overlay:SetAllPoints()
                    reward.overlay:SetFrameLevel(reward:GetFrameLevel() + 4)
                    reward.caption = reward.overlay:CreateFontString(nil, "OVERLAY")
                    reward.PaintEdges = function(self)
                        if self.texturedBorder then PaintBorder(self); return end
                        local color = self.obtained and { 0.25, 0.6, 0.25 } or compactBorderColor
                        local boost = self.isHovered and 0.35 or 0
                        for _, edge in ipairs(self.edges) do
                            edge:SetColorTexture(math.min(1, color[1] + boost), math.min(1, color[2] + boost), math.min(1, color[3] + boost), 1)
                        end
                    end
                    reward:EnableMouse(true)
                    if reward.SetPropagateMouseClicks then reward:SetPropagateMouseClicks(true) end
                    reward:SetScript("OnEnter", function(self)
                        self.isHovered = true
                        self:PaintEdges()
                        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                        local lines = self.tooltipLines or {}
                        if self.link then GameTooltip:SetHyperlink(self.link)
                        elseif self.spellID then GameTooltip:SetSpellByID(self.spellID)
                        elseif self.toyID and GameTooltip.SetToyByItemID then GameTooltip:SetToyByItemID(self.toyID)
                        elseif self.itemID then GameTooltip:SetItemByID(self.itemID)
                        elseif lines[1] then GameTooltip:SetText(lines[1], 1, 1, 1) end
                        for lineIndex, line in ipairs(lines) do
                            if lineIndex > 1 or self.link then GameTooltip:AddLine(line, 0.85, 0.85, 0.85, true) end
                        end
                        -- Teleport tooltips already show their remaining cooldown.
                        if self.castable then
                            if InCombatLockdown() then GameTooltip:AddLine(text.teleportCombat, 1, 0.4, 0.4)
                            else GameTooltip:AddLine(text.teleportUse, 0.6, 0.6, 0.6) end
                        elseif not self.styled then
                            GameTooltip:AddLine(self.obtained and text.rewardObtained or text.rewardMissing, self.obtained and 0.3 or 1, self.obtained and 1 or 0.4, self.obtained and 0.3 or 0.4)
                        end
                        GameTooltip:Show()
                        if self.castable then addon.AttachTeleportButton(self) end
                    end)
                    reward:SetScript("OnLeave", function(self)
                        self.isHovered = false
                        self:PaintEdges()
                        GameTooltip:Hide()
                    end)
                    row.rewards[rewardIndex] = reward
                end
                -- One physical pixel of border, drawn inside the frame so icons never overlap.
                local top, bottom, left, right = unpack(reward.edges)
                top:ClearAllPoints(); top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(pixel)
                bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(pixel)
                left:ClearAllPoints(); left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(pixel)
                right:ClearAllPoints(); right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(pixel)
                for _, edge in ipairs(reward.edges) do DisableTextureSnapping(edge); edge:SetShown(not texturedBorder) end
                reward.styled, reward.castable = styled, castable
                reward.texturedBorder = texturedBorder
                -- Teleport icons are cast, not row clicks, even in combat when they cannot be used.
                if reward.SetPropagateMouseClicks then reward:SetPropagateMouseClicks(not castable) end
                if texturedBorder then
                    if not reward.border then
                        reward.border = CreateFrame("Frame", nil, reward, "BackdropTemplate")
                        reward.border:EnableMouse(false)
                    end
                    reward.border:Show()
                    SetBackdrop(reward, style, 1, pixel, nil, not styled and info.obtained and { 0.25, 0.6, 0.25, 1 } or info.cooldownDuration and compactBorderColor or nil)
                elseif reward.border then
                    -- The frame may have been styled by a previous content type.
                    reward.border:Hide()
                    reward.backdropKey = nil
                    reward.background:ClearAllPoints()
                    reward.background:SetAllPoints()
                    reward.background:SetColorTexture(0, 0, 0, 1)
                end
                reward.icon:SetTexCoord(unpack(iconCoords))
                reward.icon:ClearAllPoints()
                reward.icon:SetPoint("TOPLEFT", iconInset, -iconInset)
                if wide then reward.icon:SetSize(iconSize - iconInset * 2, iconSize - iconInset * 2)
                else reward.icon:SetPoint("BOTTOMRIGHT", -iconInset, iconInset) end
                local progress = wide and info.progress and math.max(0, math.min(1, info.progress)) or 0
                reward.fill:ClearAllPoints()
                reward.fill:SetPoint("TOPLEFT", iconSize - iconInset, -iconInset)
                reward.fill:SetSize(math.max(pixel, Snap((tileWidth - iconSize) * progress, pixel)), iconSize - iconInset * 2)
                reward.fill:SetTexture(style.fill)
                local fillColor = info.captionColor or { 0.15, 0.8, 1 }
                reward.fill:SetVertexColor(fillColor[1], fillColor[2], fillColor[3], 0.3)
                DisableTextureSnapping(reward.fill)
                reward.fill:SetShown(progress > 0)
                reward.itemID, reward.spellID, reward.toyID, reward.obtained = info.itemID, info.spellID, info.toyID, info.obtained
                reward.link, reward.tooltipLines = info.link, info.tooltipLines
                reward.caption:ClearAllPoints()
                if wide then
                    reward.caption:SetPoint("LEFT", reward, "LEFT", iconSize - iconInset, 0)
                    reward.caption:SetPoint("RIGHT", reward, "RIGHT", -iconInset, 0)
                    reward.caption:SetJustifyH("CENTER")
                    SetPanelFont(reward.caption, settings.fontSize, "OUTLINE", settings)
                else
                    reward.caption:SetPoint("BOTTOM", reward, "BOTTOM", 0, iconInset + pixel)
                    SetPanelFont(reward.caption, Snap(math.max(9, math.floor(iconSize * 0.34)), pixel), "OUTLINE", settings)
                end
                reward.caption:SetTextColor(unpack(info.captionColor or { 1, 1, 1 }))
                reward.caption:SetText(info.caption or "")
                reward.caption:SetShown(info.caption ~= nil)
                addon.UpdateTeleportButton(reward)
                if info.cooldownDuration then
                    if not reward.cooldown then
                        reward.cooldown = CreateFrame("Cooldown", nil, reward, "CooldownFrameTemplate")
                        if reward.cooldown.SetDrawEdge then reward.cooldown:SetDrawEdge(false) end
                    end
                    reward.cooldown:ClearAllPoints()
                    reward.cooldown:SetAllPoints(reward.icon)
                    reward.cooldown:SetCooldown(info.cooldownStart, info.cooldownDuration)
                    reward.cooldown:Show()
                elseif reward.cooldown then
                    reward.cooldown:Hide()
                end
                reward:PaintEdges()
                reward:SetSize(tileWidth, iconSize)
                reward:ClearAllPoints()
                local column, line = (rewardIndex - 1) % perLine, math.floor((rewardIndex - 1) / perLine)
                reward:SetPoint("TOPLEFT", row, "TOPLEFT", gridInset + column * (tileWidth + rewardGap), -gridTop - line * (iconSize + rewardGap))
                reward.icon:SetTexture(info.icon or 134400)
                reward.icon:SetDesaturated(info.obtained or info.locked or info.cooldownDuration ~= nil)
                reward.icon:SetAlpha((info.obtained or info.locked) and 0.5 or 1)
                DisableTextureSnapping(reward.icon)
                reward.check:SetSize(Snap(math.floor(iconSize * 0.55), pixel), Snap(math.floor(iconSize * 0.55), pixel))
                reward.check:SetShown(info.obtained)
                reward:Show()
            end
            actualHeight = gridTop + lines * (iconSize + rewardGap) - rewardGap + gridInset
            row:SetHeight(actualHeight)
        end
        if compact then
            row.icon:ClearAllPoints()
            row.icon:SetSize(compactIconSize, compactIconSize)
            row.icon:SetPoint("TOPRIGHT", row, "TOPRIGHT", renown and -valueInset or -Snap(valueInset + valueWidth + 4, pixel), -Snap((actualHeight - compactIconSize) / 2, pixel))
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
    local visibleHeight = (settings.content == "quests" or settings.content == "rares" or settings.content == "raidcollection" or settings.content == "teleports" or delves) and math.min(renderedHeight, Snap(maximumHeight, pixel)) or renderedHeight
    panel.content:SetSize(width + clipPadding * 2, renderedHeight + verticalPadding * 2)
    panel.viewport:SetHeight(visibleHeight + verticalPadding * 2)
    panel.scrollMaximum = math.max(0, renderedHeight - visibleHeight)
    panel.viewport:SetVerticalScroll(math.min(panel.viewport:GetVerticalScroll(), panel.scrollMaximum))
    local viewTop, viewBottom = -contentTop + verticalPadding - questInset, -contentTop - visibleHeight - verticalPadding - questInset
    local scrolling = not settings.collapsed and panel.scrollMaximum > 0
    panel.scrollHint:ClearAllPoints()
    panel.scrollHint:SetPoint("TOP", panel, "TOP", 0, viewBottom - Snap(5, pixel))
    SetPanelFont(panel.scrollHint, math.max(8, settings.fontSize - 2), "", settings)
    panel.scrollHint:SetTextColor(0.55, 0.55, 0.55)
    panel.scrollHint:SetText(text.questScrollHint)
    panel.scrollHint:SetShown(scrolling)
    local edge, fadeHeight = Snap(3, pixel), Snap(28, pixel)
    for _, fade in ipairs({ panel.fadeTop, panel.fadeBottom }) do
        local atTop = fade == panel.fadeTop
        fade:ClearAllPoints()
        fade:SetPoint(atTop and "TOPLEFT" or "BOTTOMLEFT", panel, "TOPLEFT", edge, atTop and viewTop or viewBottom)
        fade:SetPoint(atTop and "TOPRIGHT" or "BOTTOMRIGHT", panel, "TOPRIGHT", -edge, atTop and viewTop or viewBottom)
        fade:SetHeight(fadeHeight)
        fade:SetColorTexture(1, 1, 1, 1)
        if fade.SetGradient and CreateColor then
            local solid, clear = CreateColor(0.035, 0.035, 0.035, 0.95), CreateColor(0.035, 0.035, 0.035, 0)
            -- VERTICAL gradients go from the bottom colour to the top colour.
            fade:SetGradient("VERTICAL", atTop and clear or solid, atTop and solid or clear)
        end
        DisableTextureSnapping(fade)
    end
    panel.scrollLine:ClearAllPoints()
    local scrollLineOffset = PaintSeparator(panel.scrollLine, style, pixel, compactBorderColor[1], compactBorderColor[2], compactBorderColor[3], 0.8)
    panel.scrollLine:SetPoint("TOPLEFT", panel, "TOPLEFT", Snap(8, pixel), viewBottom + scrollLineOffset)
    panel.scrollLine:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -Snap(8, pixel), viewBottom + scrollLineOffset)
    panel.scrollLine:SetShown(scrolling)
    panel.content:SetShown(not settings.collapsed)
    panel.viewport:SetShown(not settings.collapsed)
    UpdateScrollFades(panel)
    panel:SetHeight(settings.collapsed and headerHeight or (contentTop + visibleHeight + questInset + (panel.scrollMaximum > 0 and Snap(22, pixel) or 0)))
    if not batching then PositionPanels() end
    panel:SetShown(editing or settings.enabled)
    if not batching then UpdatePolling() end
end

-- contents: optional set of content types; only matching panels are rendered.
local function RenderPanels(contents, force)
    batching = true
    local rendered = false
    for _, panel in ipairs(panels) do
        if force then
            Render(panel)
            rendered = true
        else
            local settings = Settings(panel.definition.id)
            panel.pollingEnabled = editing or settings.enabled
            if (not contents or contents[settings.content]) and panel.pollingEnabled then
                Render(panel)
                rendered = true
            elseif not panel.pollingEnabled then
                panel:Hide()
            end
        end
    end
    batching = false
    if rendered then PositionPanels() end
    UpdatePolling()
end

function addon.RefreshPanels(contents)
    RenderPanels(contents, not contents)
end

function addon.SetPanelTitle(index, title)
    local panel = panels[index]
    if not panel then return end
    local settings = Settings(panel.definition.id)
    settings.title = title
    -- Even a deliberately chosen "PANEL 4" is a manual title from now on.
    settings.titleOverride = title
    Render(panel)
end

local function ApplyLayout(layoutName)
    addon.CloseContentEditor()
    -- Finish shortcut drags in their original layout before changing ownership.
    for _, panel in ipairs(panels) do
        if panel.shortcutDrag then panel.header:GetScript("OnDragStop")() end
        panel.autoAnchorPending = nil
    end
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
        { key = "style", label = text.style, kind = LEM.SettingType.Dropdown, default = "pixels" },
        { key = "opacity", label = text.opacity, kind = LEM.SettingType.Slider, default = 1, min = 0.2, max = 1, step = 0.02 },
        { key = "fontSize", label = text.fontSize, kind = LEM.SettingType.Slider, default = 11, min = 10, max = 18, step = 1 },
        { key = "rowHeight", label = text.rowHeight, kind = LEM.SettingType.Slider, default = 22, min = 22, max = 34, step = 1 },
        { key = "rowCount", label = text.rowCount, kind = LEM.SettingType.Slider, default = 3, min = 1, max = 8, step = 1 },
        { key = "showBars", label = text.showBars, kind = LEM.SettingType.Checkbox, default = true },
    }) do
        local key = spec.key
        controls[#controls + 1] = {
            name = spec.label, kind = spec.kind, default = spec.default,
            desc = sharedAppearance[key] and (fr and "Ce réglage s’applique à tous les trackers de cette disposition." or "This setting applies to all trackers in this layout.") or nil,
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
                if key == "questReadable" or key == "questAuto" or key == "questObjectives" or key == "questDetails" or key == "questColors" then return settings.content ~= "quests" end
                if key == "questHeight" then return settings.content ~= "quests" and settings.content ~= "rares" and settings.content ~= "raidcollection" and settings.content ~= "teleports" end
                if key == "questAll" then return settings.content ~= "quests" or not settings.questAuto end
                if key == "questLimit" then return settings.content ~= "quests" or not settings.questAuto or settings.questAll end
                return false
            end,
            values = key == "anchorTarget" and function()
                    local targets = { { text = fr and "Écran (libre)" or "Screen (free)", value = "screen" } }
                    for _, other in ipairs(panels) do
                        if other ~= panel then targets[#targets + 1] = { text = text.panel .. " " .. other.definition.index, value = other.definition.id } end
                    end
                    return targets
                end
                or key == "point" and { { text = fr and "Haut gauche" or "Top left", value = "TOPLEFT" }, { text = fr and "Haut" or "Top", value = "TOP" }, { text = fr and "Haut droite" or "Top right", value = "TOPRIGHT" }, { text = fr and "Gauche" or "Left", value = "LEFT" }, { text = fr and "Centre" or "Center", value = "CENTER" }, { text = fr and "Droite" or "Right", value = "RIGHT" }, { text = fr and "Bas gauche" or "Bottom left", value = "BOTTOMLEFT" }, { text = fr and "Bas" or "Bottom", value = "BOTTOM" }, { text = fr and "Bas droite" or "Bottom right", value = "BOTTOMRIGHT" } }
                or key == "anchorSide" and { { text = fr and "En dessous" or "Below", value = "BOTTOM" }, { text = fr and "Au-dessus" or "Above", value = "TOP" }, { text = fr and "À gauche" or "Left", value = "LEFT" }, { text = fr and "À droite" or "Right", value = "RIGHT" } }
                or key == "anchorAlign" and { { text = fr and "Début (gauche / haut)" or "Start (left / top)", value = "start" }, { text = fr and "Centre" or "Center", value = "center" }, { text = fr and "Fin (droite / bas)" or "End (right / bottom)", value = "finish" } }
                or key == "content" and addon.contentTypes or key == "delvesSort" and { { text = fr and "Note" or "Grade", value = "grade" }, { text = fr and "Nom" or "Name", value = "name" } } or key == "style" and styleChoices or nil,
            get = function(layoutName) return Settings(id, layoutName)[key] end,
            set = function(layoutName, value)
                if key == "point" then SaveFreePosition(panel, Settings(id, layoutName), value) end
                if key == "anchorTarget" then
                    if WouldCycle(id, value, layoutName) then DEFAULT_CHAT_FRAME:AddMessage("FunelQOL: " .. text.anchorCycle); return end
                    if value == "screen" and Settings(id, layoutName).anchorTarget ~= "screen" then SaveFreePosition(panel, Settings(id, layoutName)) end
                end
                if key == "content" then addon.CloseContentEditor() end
                if sharedAppearance[key] then
                    for _, other in ipairs(panels) do Settings(other.definition.id, layoutName)[key] = value end
                    addon.RefreshPanels()
                    LEM:RefreshFrameSettings(panel)
                    return
                end
                Settings(id, layoutName)[key] = value
                Render(panel)
            end,
        }
    end
    LEM:AddFrameSettings(panel, controls)
    LEM:AddFrameSettingsButtons(panel, {
        { text = text.configure, click = function()
            addon.OpenContentEditor(Settings(id), function() Render(panel); LEM:RefreshFrameSettings(panel) end)
        end },
        { text = text.addTracker, click = function()
            if not editing or InCombatLockdown() then return end
            addon.AddPanel()
            LEM:RefreshFrameSettings(panel)
        end },
        { text = text.removeTracker, click = function()
            if not editing or InCombatLockdown() or panels[panel.definition.index] ~= panel then return end
            if #panels <= 1 then
                DEFAULT_CHAT_FRAME:AddMessage(fr and "FunelQOL : au moins un tracker doit rester." or "FunelQOL: at least one tracker must remain.")
                return
            end
            addon.RemovePanel(panel.definition.index)
            if LEM.internal and LEM.internal.dialog then LEM.internal.dialog:Hide() end
        end },
    })
end

function addon.ConfigurePanel(index)
    local panel = panels[index]
    if panel then addon.OpenContentEditor(Settings(panel.definition.id), function() Render(panel); LEM:RefreshFrameSettings(panel) end) end
end

local created = {}
-- Frames cannot be destroyed, so removed panels are kept hidden and reused.
local function CreatePanel(index)
    if created[index] then
        panels[index] = created[index]
        if _G.RefineUI and _G.RefineUI.EditModeAnchors then
            _G.RefineUI.EditModeAnchors:RegisterFrame(created[index], LEM)
        end
        return created[index]
    end
    local definition = Definition(index)
    local panel = CreateFrame("Frame", addonName .. definition.id .. "Panel", UIParent)
    panel.definition, panel.rows = definition, {}
    panel:SetClampedToScreen(true)
    -- Keep trackers above HUD bars while leaving dialogs, menus and tooltips
    -- in their higher native strata. Children inherit this priority.
    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(100)
    panel:SetSize(260, 26)
    panel.viewport = CreateFrame("ScrollFrame", nil, panel)
    panel.content = CreateFrame("Frame", nil, panel.viewport)
    panel.content:SetSize(260, 1)
    panel.viewport:SetScrollChild(panel.content)
    panel.viewport:EnableMouseWheel(true)
    panel.viewport:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(panel.scrollMaximum or 0, self:GetVerticalScroll() - Snap(delta * 40, PixelUnit(self)))))
        UpdateScrollFades(panel)
    end)
    panel.scrollHint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    -- Soft shadows over the clipped edges say "there is more" without cutting text abruptly.
    panel.fades = CreateFrame("Frame", nil, panel)
    panel.fades:EnableMouse(false)
    panel.fades:SetFrameLevel(panel:GetFrameLevel() + 50)
    panel.fadeTop = panel.fades:CreateTexture(nil, "OVERLAY")
    panel.fadeBottom = panel.fades:CreateTexture(nil, "OVERLAY")
    panel.scrollLine = panel.fades:CreateTexture(nil, "OVERLAY")
    panel.header = CreateFrame("Button", nil, panel, "BackdropTemplate")
    panel.body = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    panel.body:EnableMouse(false)
    panel.body:SetFrameLevel(panel:GetFrameLevel())
    panel.header:SetPoint("TOPLEFT")
    panel.header:SetPoint("TOPRIGHT")
    panel.header:SetHeight(24)
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
    panel.header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    panel.header:RegisterForDrag("LeftButton")
    panel.header:SetScript("OnMouseDown", function() panel.suppressHeaderClick = nil end)
    panel.header:SetScript("OnDragStart", function()
        if not IsShiftKeyDown() or InCombatLockdown() then return end
        panel.suppressHeaderClick, panel.shortcutDrag = true, true
        panel:SetMovable(true)
        panel.header:RegisterEvent("PLAYER_REGEN_DISABLED")
        panel:StartMoving()
    end)
    local function StopShortcutDrag()
        if not panel.shortcutDrag then return end
        panel:StopMovingOrSizing()
        panel.shortcutDrag = nil
        panel:SetMovable(false)
        panel.header:UnregisterEvent("PLAYER_REGEN_DISABLED")
        if panel:IsVisible() then Render(panel) end
        LEM:RefreshFrameSettings(panel)
    end
    panel.header:SetScript("OnDragStop", StopShortcutDrag)
    panel.header:SetScript("OnEvent", StopShortcutDrag)
    panel.header:SetScript("OnHide", StopShortcutDrag)
    panel.header:SetScript("OnClick", function(_, button)
        if panel.suppressHeaderClick or button == "LeftButton" and IsShiftKeyDown() then return end
        if IsControlKeyDown() then
            if InCombatLockdown() or panels[definition.index] ~= panel then return end
            if button == "LeftButton" then
                addon.AddPanel(panel)
            elseif button == "RightButton" then
                if #panels <= 1 then
                    DEFAULT_CHAT_FRAME:AddMessage(fr and "FunelQOL : au moins un tracker doit rester." or "FunelQOL: at least one tracker must remain.")
                    return
                end
                addon.RemovePanel(definition.index)
                if LEM.internal and LEM.internal.dialog then LEM.internal.dialog:Hide() end
            end
            return
        end
        if button == "RightButton" then
            local layoutName = activeLayout
            MenuUtil.CreateContextMenu(panel.header, function(_, root)
                root:CreateTitle(text.content)
                for _, choice in ipairs(addon.contentTypes) do
                    local content = choice.value
                    root:CreateRadio(choice.text, function() return Settings(definition.id, layoutName).content == content end, function()
                        -- An open menu must not change another layout or a reused slot.
                        if activeLayout ~= layoutName or panels[definition.index] ~= panel then return end
                        addon.CloseContentEditor()
                        Settings(definition.id, layoutName).content = content
                        Render(panel)
                        LEM:RefreshFrameSettings(panel)
                    end)
                end
            end)
            return
        end
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
    panels[definition.index] = panel
    hooksecurefunc(panel, "StartMoving", function()
        if InCombatLockdown() then return end
        dragging[panel] = true
        panel.autoAnchorPending = nil
        local settings = Settings(definition.id)
        SaveFreePosition(panel, settings, settings.point)
        settings.anchorTarget = "screen"
        local elapsedTime = 0
        panel:SetScript("OnUpdate", function(_, elapsed)
            elapsedTime = elapsedTime + elapsed
            if elapsedTime < 0.03 then return end
            elapsedTime = 0
            UpdateAnchorPreview(panel)
        end)
        UpdateAnchorPreview(panel)
    end)
    hooksecurefunc(panel, "StopMovingOrSizing", function()
        if not dragging[panel] then return end
        panel:SetScript("OnUpdate", nil)
        HideAnchorPreview(panel)
        dragging[panel] = nil
        local settings = Settings(definition.id)
        SaveFreePosition(panel, settings, settings.point)
        if panel.shortcutDrag then
            AutoAnchor(panel, settings)
        else
            -- LibEditMode normalizes the screen position after stopping the drag.
            -- Apply the link in its position callback, after that normalization.
            panel.autoAnchorPending = true
        end
    end)
    local default = { point = "TOPRIGHT", x = definition.x, y = definition.y }
    LEM:AddFrame(panel, function(_, layoutName, point, x, y)
        local settings = Settings(definition.id, layoutName)
        -- Dragging / nudging deliberately releases the link, as in EUI movers.
        settings.anchorTarget = "screen"
        settings.point, settings.x, settings.y = point, x, y
        settings.positionHeight = panel:GetHeight()
        if panel.autoAnchorPending then
            panel.autoAnchorPending = nil
            AutoAnchor(panel, settings)
        end
        Render(panel)
    end, default)
    AddSettings(panel)
    -- RefineUI's global Edit Mode links can target native systems as well as trackers.
    if _G.RefineUI and _G.RefineUI.EditModeAnchors then
        _G.RefineUI.EditModeAnchors:RegisterFrame(panel, LEM, "FunelQOL · " .. Settings(definition.id).title, function()
            local settings = Settings(definition.id)
            settings.anchorTarget = "screen"
            SaveFreePosition(panel, settings, settings.point)
        end)
    end
    created[index] = panel
    return panel
end

function addon.AddPanel(anchorPanel)
    if InCombatLockdown() then return nil end
    if anchorPanel and panels[anchorPanel.definition.index] ~= anchorPanel then return nil end
    local index = #panels + 1
    local panel = CreatePanel(index)
    addon.panelDB.panelCount = index
    local settings = Settings(panel.definition.id)
    if index > 1 then
        local reference = Settings(panels[1].definition.id)
        for _, key in ipairs(appearanceKeys) do settings[key] = reference[key] end
    end
    if anchorPanel then
        settings.anchorTarget = anchorPanel.definition.id
        settings.anchorSide, settings.anchorAlign = "RIGHT", "start"
        settings.anchorGap, settings.anchorOffset = 8, 0
    end
    panel:ClearAllPoints()
    panel:SetPoint(settings.point, UIParent, settings.point, settings.x, settings.y)
    addon.RefreshPanels()
    LEM:RefreshFrameSettings(panel)
    return index
end

function addon.RemovePanel(index)
    local count = #panels
    index = index or count
    if InCombatLockdown() or count <= 1 or not panels[index] then return nil end
    addon.CloseContentEditor()
    local panel, id = panels[index], panels[index].definition.id
    local last, lastID = panels[count], panels[count].definition.id
    local anchors = _G.RefineUI and _G.RefineUI.EditModeAnchors
    -- Keep panels linked to the removed one where they currently are.
    for _, other in ipairs(panels) do
        local settings = Settings(other.definition.id)
        if settings.anchorTarget == id then SaveFreePosition(other, settings); settings.anchorTarget = "screen" end
    end
    if anchors then anchors:UnregisterFrame(panel) end
    -- Keep dense numbered slots: move the last tracker's configuration into
    -- the deleted slot, including its positions/content in every layout.
    for _, layout in pairs(addon.panelDB.layouts) do
        if type(layout) == "table" then
            for _, settings in pairs(layout) do
                if type(settings) == "table" and settings.anchorTarget == id then settings.anchorTarget = "screen" end
            end
            layout[id] = index ~= count and layout[lastID] or nil
            layout[lastID] = nil
            if index ~= count then
                for _, settings in pairs(layout) do
                    if type(settings) == "table" and settings.anchorTarget == lastID then settings.anchorTarget = id end
                end
            end
        end
    end
    if anchors and index ~= count then
        anchors:MoveFrameLinks(last, panel)
        anchors:UnregisterFrame(last)
        anchors:RegisterFrame(panel, LEM)
    end
    panels[count] = nil
    addon.panelDB.panelCount = count - 1
    last:Hide()
    if LEM.frameSelections and LEM.frameSelections[last] then LEM.frameSelections[last]:Hide() end
    addon.RefreshPanels()
    return index
end

function addon.InitializePanels()
    if #panels > 0 then return end
    if type(FunelQOLCharDB) ~= "table" then FunelQOLCharDB = {} end
    FunelQOLDB = FunelQOLDB or {}
    if type(FunelQOLDB.panels) ~= "table" then
        FunelQOLDB.panels = Copy({ layouts = FunelQOLCharDB.layouts, panelCount = FunelQOLCharDB.panelCount })
    end
    -- A single account table; legacy character data remains untouched.
    addon.characterDB = FunelQOLCharDB
    addon.panelDB = FunelQOLDB.panels
    local panelDB = addon.panelDB
    if type(panelDB.layouts) ~= "table" then panelDB.layouts = {} end

    LEM:RegisterCallback("layout", ApplyLayout)
    LEM:RegisterCallback("enter", function() editing = true; addon.RefreshPanels() end)
    LEM:RegisterCallback("exit", function() addon.CloseContentEditor(); editing = false; addon.RefreshPanels() end)
    LEM:RegisterCallback("create", function(name, _, sourceName)
        if sourceName and panelDB.layouts[sourceName] then
            panelDB.layouts[name] = Copy(panelDB.layouts[sourceName])
        end
    end)
    LEM:RegisterCallback("rename", function(oldName, newName)
        panelDB.layouts[newName] = panelDB.layouts[oldName]
        panelDB.layouts[oldName] = nil
    end)
    LEM:RegisterCallback("delete", function(name) panelDB.layouts[name] = nil end)

    if type(panelDB.panelCount) ~= "number" or panelDB.panelCount < 1 then panelDB.panelCount = 2 end
    panelDB.panelCount = math.floor(panelDB.panelCount)
    for index = 1, panelDB.panelCount do CreatePanel(index) end
    if panelDB.appearanceRevision ~= 1 then
        -- Normalize the reference first, including legacy theme migrations.
        for layoutName, layout in pairs(panelDB.layouts) do
            local reference = Settings("panel1", layoutName)
            for id, settings in pairs(layout) do
                if type(id) == "string" and string.match(id, "^panel%d+$") and type(settings) == "table" then
                    for _, key in ipairs(appearanceKeys) do settings[key] = reference[key] end
                    settings.styleRevision = 1
                end
            end
        end
        panelDB.appearanceRevision = 1
    end
    ApplyLayout(LEM:GetActiveLayoutName())

    local events = CreateFrame("Frame")
    refreshEvents = events
    events:RegisterEvent("UI_SCALE_CHANGED")
    events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    events:RegisterEvent("AREA_POIS_UPDATED")
    events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("UPDATE_UI_WIDGET")
    events:RegisterEvent("UPDATE_ALL_UI_WIDGETS")
    events:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE")
    for _, event in ipairs({ "PLAYER_MONEY", "CURRENCY_DISPLAY_UPDATE", "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE", "PLAYER_SPECIALIZATION_CHANGED", "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "QUEST_WATCH_LIST_CHANGED", "QUEST_DATA_LOAD_RESULT", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "SUPER_TRACKING_CHANGED", "SUPER_TRACKING_PATH_UPDATED", "QUEST_POI_UPDATE" }) do
        events:RegisterEvent(event)
    end
    events:RegisterEvent("ACHIEVEMENT_EARNED")
    events:RegisterEvent("CRITERIA_UPDATE")
    for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_DIFFICULTY_CHANGED", "TRANSMOG_COLLECTION_UPDATED", "CHALLENGE_MODE_MAPS_UPDATE", "WEEKLY_REWARDS_UPDATE", "WEEKLY_REWARDS_ITEM_CHANGED", "UPDATE_FACTION",
        "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "MAJOR_FACTION_UNLOCKED", "GET_ITEM_INFO_RECEIVED" }) do events:RegisterEvent(event) end
    local delveEvents = { AREA_POIS_UPDATED = true, ZONE_CHANGED_NEW_AREA = true, PLAYER_ENTERING_WORLD = true,
        ACTIVE_DELVE_DATA_UPDATE = true, UPDATE_ALL_UI_WIDGETS = true, ACHIEVEMENT_EARNED = true, CRITERIA_UPDATE = true }
    local questContents = { quests = true, delvequests = true, weekly = true, rares = true }
    local itemContents = { raidsets = true, raidcollection = true, vault = true, rares = true }
    local rareContents = { rares = true }
    local teleportContents = { teleports = true }
    local delveContents = { delves = true }
    local eventContents = { GET_ITEM_INFO_RECEIVED = itemContents, ITEM_DATA_LOAD_RESULT = itemContents, AREA_POIS_UPDATED = { quests = true, delves = true },
        CRITERIA_UPDATE = { delves = true, rares = true }, UPDATE_UI_WIDGET = delveContents, UPDATE_ALL_UI_WIDGETS = delveContents }
    eventContents.PLAYER_MONEY = { currencies = true, quests = true }
    eventContents.CURRENCY_DISPLAY_UPDATE = { currencies = true, weekly = true, vault = true }
    eventContents.SKILL_LINES_CHANGED = { professions = true }
    eventContents.TRADE_SKILL_LIST_UPDATE = eventContents.SKILL_LINES_CHANGED
    eventContents.UPDATE_FACTION = { renown = true }
    eventContents.MAJOR_FACTION_RENOWN_LEVEL_CHANGED = eventContents.UPDATE_FACTION
    eventContents.MAJOR_FACTION_UNLOCKED = eventContents.UPDATE_FACTION
    eventContents.WEEKLY_REWARDS_UPDATE = { vault = true }
    eventContents.WEEKLY_REWARDS_ITEM_CHANGED = eventContents.WEEKLY_REWARDS_UPDATE
    eventContents.CHALLENGE_MODE_MAPS_UPDATE = teleportContents
    for _, event in ipairs({ "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "NEW_MOUNT_ADDED", "NEW_PET_ADDED", "NEW_TOY_ADDED", "ITEM_DATA_LOAD_RESULT" }) do
        events:RegisterEvent(event)
        eventContents[event] = event=="ITEM_DATA_LOAD_RESULT" and itemContents or rareContents
    end
    eventContents.NEW_TOY_ADDED = { rares = true, teleports = true }
    for _, event in ipairs({ "SPELLS_CHANGED", "TOYS_UPDATED", "SPELL_UPDATE_COOLDOWN", "BAG_UPDATE_COOLDOWN" }) do
        events:RegisterEvent(event)
        eventContents[event] = teleportContents
    end
    for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "QUEST_WATCH_LIST_CHANGED", "QUEST_DATA_LOAD_RESULT", "QUEST_POI_UPDATE",
        "SUPER_TRACKING_CHANGED" }) do eventContents[event] = questContents end
    -- Path updates only change the quest tracker's waypoint text.
    eventContents.SUPER_TRACKING_PATH_UPDATED = { quests = true }
    local vaultContents = { vault = true }
    -- Opening the map fires dozens of events in a few frames: render once per burst.
    local pending, pendingAll, queued = {}, false, false
    local function Flush()
        queued = false
        local contents, all = pending, pendingAll
        pending, pendingAll = {}, false
        if all then RenderPanels() else RenderPanels(contents) end
    end
    local function QueueRefresh(contents)
        if contents then
            local active = false
            for _, panel in ipairs(panels) do
                local settings = Settings(panel.definition.id)
                if contents[settings.content] and (editing or settings.enabled) then active = true; break end
            end
            if not active then return end
        end
        if contents then for content in pairs(contents) do pending[content] = true end else pendingAll = true end
        if not C_Timer then return Flush() end
        if not queued then queued = true; C_Timer.After(0.1, Flush) end
    end
    addon.QueuePanelRefresh = QueueRefresh
    events:SetScript("OnEvent", function(_, event, info)
        if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "TRANSMOG_COLLECTION_UPDATED" then addon.InvalidateRaidActions() end
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "TRANSMOG_COLLECTION_UPDATED" then addon.InvalidateRaidSets() end
        if event == "ITEM_DATA_LOAD_RESULT" or event == "GET_ITEM_INFO_RECEIVED" then
            -- Any addon's item query fires these: only items requested here
            -- rebuild rares/raid actions (pending raid items clear their cache).
            local rare = addon.IsRareItemPending(info)
            local raid = addon.IsRaidActionItemPending(info)
            if not rare and not raid then
                if event == "GET_ITEM_INFO_RECEIVED" then QueueRefresh(vaultContents) end
                return
            end
        end
        -- Cooldown events fire on every global cooldown: teleports are only cast out of combat.
        if (event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN") and InCombatLockdown() then return end
        if event == "UPDATE_UI_WIDGET" then
            if not addon.IsDelveWidget(info and info.widgetID) then return end
            addon.InvalidateDelves()
        elseif delveEvents[event] then addon.InvalidateDelves() end
        QueueRefresh(eventContents[event])
    end)
    local elapsed = 0
    events:SetScript("OnUpdate", function(_, delta)
        if not addon.questHasTimers and not addon.raidUpgradePending then elapsed = 0; return end
        elapsed = elapsed + delta
        if elapsed >= (addon.questHasTimers and 1 or 2) then
            elapsed = 0
            if addon.raidUpgradePending then addon.InvalidateRaidActions() end
            addon.RefreshPanels({ quests = addon.questHasTimers, raidsets = addon.raidUpgradePending, raidcollection = addon.raidUpgradePending })
        end
    end)
    UpdatePolling()
    -- UIParent:SetScale can be called directly by UI addons without a CVar event.
    hooksecurefunc(UIParent, "SetScale", function() addon.RefreshPanels() end)
end

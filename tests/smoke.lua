-- Minimal stateful WoW mock. The actual Blizzard UI still needs in-game testing.
local frames, messages = {}, {}
local methods = {}
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetPoint(...)
    self.point = { ... }
    self.points = self.points or {}
    self.points[#self.points + 1] = self.point
end
function methods:ClearAllPoints() self.point, self.points = nil, {} end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:SetScrollChild(child) self.child = child end
function methods:EnableMouseWheel() end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetScale(scale)
    self.scale = scale
    if self.scaleHook then self.scaleHook() end
end
function hooksecurefunc(frame, method, callback)
    assert(method == "SetScale")
    frame.scaleHook = callback
end
function methods:GetEffectiveScale() return (self.scale or 1) * (self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetLeft() return 137.27 + (self.point and self.point[4] or 0) end
function methods:GetTop() return 531.43 + (self.point and self.point[5] or 0) end
function methods:GetRegions() end
function methods:GetParent() return self.parent end
function methods:IsShown() return self.shown end
function methods:SetChecked(checked) self.checked = checked end
function methods:RegisterForClicks(...) self.clicks = {...} end
function methods:SetRotation(rotation) self.rotation = rotation end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetShown(shown) self.shown = shown end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetTexture(texture) self.texture = texture; self.atlas = nil; return true end
function methods:SetText(text) self.text = text end
function methods:SetFont(font, size) self.font, self.fontSize = font, size end
function methods:GetStringWidth() return #(self.text or "") * 6 end
function methods:GetUnboundedStringWidth() return #(self.text or "") * 6 end
function methods:GetStringHeight() return math.ceil(#(self.text or "") * 6 / math.max(1, self.width or 200)) * (self.fontSize or 11) end
function methods:SetBackdrop(backdrop) self.backdrop = backdrop end
function methods:SetStatusBarTexture(texture) self.texture = texture; self.barColor = nil end
function methods:GetStatusBarTexture() return self end
function methods:SetStatusBarColor(...) self.barColor = { ... } end
function methods:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
function methods:SetValue(value) self.value = value end
for _, name in ipairs({ "SetAllPoints", "SetClampedToScreen", "SetFrameStrata", "SetBackdropColor", "SetBackdropBorderColor", "SetTexCoord", "SetJustifyH", "SetWordWrap", "SetTextColor", "EnableMouse", "SetColorTexture" }) do
    methods[name] = function() end
end
function methods:SetWordWrap(enabled) self.wordWrap = enabled end
function CreateFrame(kind, name, parent)
    local frame = setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, events = {}, shown = true }, { __index = methods })
    frames[#frames + 1] = frame
    return frame
end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
function methods:CreateFontString() return CreateFrame("FontString", nil, self) end
UIParent = CreateFrame("Frame")
local physicalHeight = 1080
UIParent:SetScale(768 / physicalHeight)
function GetPhysicalScreenSize() return 1920, physicalHeight end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) messages[#messages + 1] = message end }
GameTooltip = { SetOwner = function() end, SetCurrencyByID = function() end, SetText = function() end, AddLine = function() end, SetMinimumWidth = function() end, Show = function() end, Hide = function() end }
SlashCmdList = {}
function GetLocale() return "frFR" end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
local combat = false
function InCombatLockdown() return combat end
EditModeManagerFrame = {}
local editOpened = false
function ShowUIPanel(frame) assert(frame == EditModeManagerFrame); editOpened = true end

local LEM = { callbacks = {}, settings = {}, positions = {}, active = "Modern", SettingType = { Checkbox = 1, Slider = 2, Dropdown = 3 } }
function LEM:RegisterCallback(event, callback) self.callbacks[event] = callback end
function LEM:RefreshFrameSettings() end
function LEM:GetActiveLayoutName() return self.active end
function LEM:AddFrame(frame, callback) self.positions[frame] = callback end
function LEM:AddFrameSettingsButtons(frame, buttons) self.buttons = self.buttons or {}; self.buttons[frame] = buttons end
function LEM:AddFrameSettings(frame, settings) self.settings[frame] = settings end
local addon = { LibEditMode = LEM }
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "CurrencyCatalog.lua", "CurrencyEditor.lua", "QuestContent.lua", "QuestXP.lua", "TrackerContent.lua", "DelveRatings.lua", "DelveQuestContent.lua", "DelveContent.lua", "ProgressContent.lua", "RaidAppearanceActions.lua", "RaidSetContent.lua", "RaidCollection.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
    assert(loadfile(file))("FunelQOL", addon)
end
local core = frames[#frames]
core.scripts.OnEvent(core, "ADDON_LOADED", "OtherAddon")
assert(addon.db == nil)
core.scripts.OnEvent(core, "ADDON_LOADED", "FunelQOL")
core.scripts.OnEvent(core, "PLAYER_LOGIN")
assert(#addon.panels == 2 and #messages == 1)
local first, second = addon.panels[1], addon.panels[2]
assert(#first.rows == 3 and #second.rows == 3)
local function SetSetting(panel, key, value)
    for _, control in ipairs(LEM.settings[panel]) do
        if control.name == addon.panelText[key] then control.set(LEM.active, value); return end
    end
    error("Missing setting " .. key)
end
LEM.positions[first](first, "Modern", "CENTER", 42, -24)
SetSetting(first, "width", 320)
SetSetting(first, "scale", 1.2)
SetSetting(first, "enabled", false)
assert(not first.shown and first.width == 320 and first.scale == 1.2)
LEM.callbacks.enter()
assert(first.shown)
LEM.callbacks.exit()
assert(not first.shown)
LEM.active = "Classic"
LEM.callbacks.layout("Classic")
assert(first.shown and first.width == 260 and first.point[1] == "TOPRIGHT")
LEM.active = "Modern"
LEM.callbacks.layout("Modern")
assert(not first.shown and first.width == 320 and first.point[1] == "CENTER" and FunelQOLCharDB.layouts.Modern.panel1.x == 42)
LEM.callbacks.create("Copied", 3, "Modern")
assert(FunelQOLCharDB.layouts.Copied.panel1.width == 320)
assert(FunelQOLCharDB.layouts.Copied.panel1 ~= FunelQOLCharDB.layouts.Modern.panel1)
LEM.callbacks.rename("Copied", "Renamed")
assert(FunelQOLCharDB.layouts.Copied == nil and FunelQOLCharDB.layouts.Renamed.panel1.width == 320)
LEM.callbacks.delete("Renamed")
assert(FunelQOLCharDB.layouts.Renamed == nil)

first.header.scripts.OnClick()
assert(not first.content.shown and first.height == first.header.height)
first.header.scripts.OnClick()
assert(first.content.shown)
LEM.callbacks.enter()
first.header.scripts.OnClick()
assert(first.content.shown)
LEM.callbacks.exit()
SetSetting(first, "rowCount", 8)
SetSetting(first, "rowHeight", 30)
SetSetting(first, "fontSize", 16)
assert(#first.rows == 8 and first.rows[8].shown and math.abs(first.rows[1].height - 30) < 0.00001 and first.rows[1].label.fontSize == 16)
SetSetting(first, "rowCount", 1)
assert(first.rows[1].shown and not first.rows[2].shown)
SetSetting(first, "showBars", false)
assert(not first.rows[1].bar.shown)
SetSetting(first, "style", "ayije")
assert(first.header.border.backdrop.edgeFile == addon.media.ayije.borders.Ayije_Thin.edgeFile)
assert(first.header.border.points[1][4] < 0, "Ayije border must be centered around the host, not inset into it")
SetSetting(first, "style", "pixels")
assert(first.header.border.backdrop.edgeFile == addon.media.borders.pixels.edgeFile)
-- Pixel artwork must surround the content on a separate, higher frame.
assert(first.rows[1].border, "Pixels border is drawn on the content frame instead of surrounding it")
assert(first.rows[1].border:GetFrameLevel() > first.rows[1].bar:GetFrameLevel(), "Fill covers the Pixels border")
SlashCmdList.FUNELQOL("Title 1 Mon Menu Test")
assert(first.title.text == "Mon Menu Test" and second.title.text == "PANNEAU 2")
LEM.active = "Classic"
LEM.callbacks.layout("Classic")
assert(first.title.text == "PANNEAU 1")
LEM.active = "Modern"
LEM.callbacks.layout("Modern")
assert(first.title.text == "Mon Menu Test")
combat = true
SlashCmdList.FUNELQOL("edit")
assert(not editOpened)
combat = false
SlashCmdList.FUNELQOL("edit")
assert(editOpened)
SlashCmdList.FUNELQOL("greeting")
assert(not FunelQOLDB.showGreeting)
local newAddon = { LibEditMode = LEM }
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "CurrencyCatalog.lua", "CurrencyEditor.lua", "QuestContent.lua", "QuestXP.lua", "TrackerContent.lua", "DelveRatings.lua", "DelveQuestContent.lua", "DelveContent.lua", "ProgressContent.lua", "RaidAppearanceActions.lua", "RaidSetContent.lua", "RaidCollection.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
    assert(loadfile(file))("FunelQOL", newAddon)
end
local reloadedCore = frames[#frames]
reloadedCore.scripts.OnEvent(reloadedCore, "ADDON_LOADED", "FunelQOL")
local messageCount = #messages
reloadedCore.scripts.OnEvent(reloadedCore, "PLAYER_LOGIN")
assert(#messages == messageCount)
assert(newAddon.panels[1].title.text == "Mon Menu Test" and newAddon.panels[1].width == 320)
assert(not newAddon.panels[1].shown and newAddon.panels[1].scale == 1.2)
local frameCount = #frames
newAddon.InitializePanels()
assert(#frames == frameCount)
local function OnGrid(value, pixel)
    assert(math.abs(value / pixel - math.floor(value / pixel + 0.5)) < 0.00001, "Geometry misses the physical pixel grid")
end
first = newAddon.panels[1]
for _, style in ipairs({ "pixels", "ayije" }) do
    SetSetting(first, "style", style)
for _, height in ipairs({ 1080, 1440, 2160 }) do
    physicalHeight = height
    for _, uiScale in ipairs({ 0.64, 0.8, 1 }) do
        UIParent:SetScale(uiScale)
        for _, scale in ipairs({ 0.7, 1, 1.2, 1.5 }) do
            SetSetting(first, "scale", scale)
            local pixel = (768 / height) / first:GetEffectiveScale()
            OnGrid(first.width, pixel)
            OnGrid(first:GetLeft(), pixel)
            OnGrid(first:GetTop(), pixel)
            local row = first.rows[1]
            OnGrid(row.height, pixel)
            assert(row.bar.barColor and row.bar.barColor[1] == 0.12, "Changing texture lost the fill tint")
            local tl, br = row.border.points[1], row.border.points[2]
            OnGrid(tl[4], pixel); OnGrid(tl[5], pixel)
            assert(tl[4] == -br[4] and tl[5] == -br[5], "Asymmetric border offsets")
            assert(tl[4] < 0 and tl[5] > 0 and row.border.backdrop.insets.left == 0)
            assert(row.border:GetFrameLevel() > row.bar:GetFrameLevel())
            OnGrid(first.header.height, pixel)
            local contentTop = -first.viewport.points[1][3] + first.rows[1].point[2]
            -- The two-argument offset SetPoint call stores x/y at indices 2/3.
            local outside = -tl[4] - row.border.backdrop.edgeSize * ((style == "ayije" and 9 or 10) / 28)
            assert(contentTop - first.header.height >= 2 * outside, "Header and row borders overlap")
            local headerBorder = first.header.border
            local heightWithOutset = first.header.height + headerBorder.points[1][5] - headerBorder.points[2][5]
            assert(heightWithOutset >= 2 * headerBorder.backdrop.edgeSize, "Border corners are squeezed by a short header")
        end
    end
end
end
UIParent:SetScale(0.73)
OnGrid(first.width, (768 / physicalHeight) / first:GetEffectiveScale())
assert(UIParent.scaleHook, "Direct UI scale changes are not observed")
print("PASS: initialization, preview controls, independent titles, collapse, visibility, layout switching/copy/rename/delete, and combat guard.")
print("PASS: centered Pixels/Ayije borders, corner clearance, fill tint, and pixel alignment at 72 style/resolution/UI/panel-scale combinations.")
-- Live content providers, ordered selections and the native editor.
function methods:GetText() return self.text or "" end
function methods:OverrideText(value) self.defaultText = value end
function methods:SetupMenu(callback) self.menu = callback end
function methods:ClearFocus() self.focus = false end
for _, name in ipairs({ "SetAutoFocus", "SetMaxLetters", "SetBackdropColor" }) do methods[name] = function() end end
local quantity, money = 12, 50000
C_CurrencyInfo = {
    GetCoinTextureString = function(value) return tostring(value) .. " copper" end,
    GetCurrencyListSize = function() return 3 end,
    GetCurrencyListInfo = function(index) return index == 1 and { isHeader = true } or { name = index == 2 and "Token" or "Season" } end,
    GetCurrencyListLink = function(index) return tostring(index) end,
    GetCurrencyIDFromLink = tonumber,
    GetCurrencyInfo = function(id)
        if id ~= 2 and id ~= 3 and id ~= 4 then return nil end
        return { name = id == 2 and "Token" or id == 3 and "Season" or "Hidden currency", quantity = quantity, maxQuantity = 100,
            useTotalEarnedForMaxQty = id == 3, iconFileID = 134400 }
    end,
}
function GetMoney() return money end
function GetProfessions() return 1, nil, nil, 4, 5 end
function GetProfessionInfo(index) return "Profession" .. index, 134400, 25, 100, 0, 0, index * 10, 0, nil, nil, "Expansion" .. index end
local selectedTalent = true
C_ClassTalents = { GetActiveConfigID = function() return 1 end }
C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 1 } } end,
    GetTreeNodes = function() return { 10, 20, 30 } end,
    GetNodeInfo = function(_, id) return { activeEntry = { entryID = id, rank = id == 30 and 0 or 1 }, subTreeActive = id == 10 and selectedTalent or id ~= 10 } end,
    GetEntryInfo = function(_, id) return { definitionID = id, maxRanks = 2 } end,
    GetDefinitionInfo = function(id) return { spellID = id * 10 } end,
}
C_Spell = { GetSpellInfo = function(id) return { name = "Talent" .. id, iconID = 134400 } end }
SetSetting(first, "content", "currencies")
local settings = FunelQOLCharDB.layouts.Modern.panel1
settings.selections.currencies = { 3, -1, 2, 0, 0, 0, 0, 0 }
newAddon.RefreshPanels()
assert(first.rows[1].data.name == "Season" and first.rows[1].data.maximum == 0 and first.rows[1].data.valueText == "12")
assert(first.rows[2].data.valueText == "50000 copper" and first.rows[3].data.maximum == 100)
local dataEvents
for _, frame in ipairs(frames) do if frame.events.CURRENCY_DISPLAY_UPDATE then dataEvents = frame end end
assert(dataEvents and dataEvents.events.PLAYER_MONEY and dataEvents.events.TRAIT_CONFIG_UPDATED)
quantity, money = 35, 75000
dataEvents.scripts.OnEvent(dataEvents, "CURRENCY_DISPLAY_UPDATE")
assert(first.rows[1].data.valueText == "35" and first.rows[2].data.valueText == "75000 copper")
SetSetting(first, "content", "professions")
assert(first.rows[1].data.name == "Expansion1" and first.rows[2].data.name == "Expansion4" and first.rows[3].data.name == "Expansion5", "Nil profession slots skipped later professions")
SetSetting(first, "content", "talents")
assert(first.rows[1].data.spellID == 100 and first.rows[2].data.spellID == 200 and not first.rows[3].shown)
selectedTalent = false
newAddon.RefreshPanels()
assert(first.rows[1].data.spellID == 200 and not first.rows[2].shown, "Inactive hero subtree still displayed")
SetSetting(first, "content", "custom")
settings.customRows = { { name = "Notes", valueText = "Raid 20:30" }, nil, { name = "Bank", valueText = "Materials" } }
newAddon.RefreshPanels()
assert(first.rows[1].data.name == "Notes" and first.rows[2].data.name == "Bank" and not first.rows[1].bar.shown)
local function FindEditor()
    for index = #frames, 1, -1 do
        local frame = frames[index]
        if frame.width == 560 and (frame.height == 414 or frame.height == 620) then return frame end
    end
end
SlashCmdList.FUNELQOL("content 1")
local editor = FindEditor()
assert(editor and editor.shown)
local function EditorButton(label, y)
    for _, frame in ipairs(frames) do
        if frame.parent == editor and frame.text == label and frame.point[3] == y then return frame end
    end
    error("Missing editor button " .. label)
end
EditorButton("↓", -92).scripts.OnClick()
assert(settings.customRows[1] == nil and settings.customRows[2].name == "Notes")
local nameBox
for _, frame in ipairs(frames) do
    if frame.parent == editor and frame.point and frame.point[2] == 48 and frame.point[3] == -92 and frame.scripts.OnTextChanged then nameBox = frame end
end
nameBox:SetText("Custom first")
nameBox.scripts.OnTextChanged(nameBox, true)
assert(first.rows[1].data.name == "Custom first")
EditorButton("×", -92).scripts.OnClick()
assert(settings.customRows[1] == nil)
local count = #frames
SlashCmdList.FUNELQOL("content 1")
assert(#frames == count, "Reopening the editor leaked frames")
SetSetting(first, "content", "currencies")
assert(not editor.shown)
SlashCmdList.FUNELQOL("content 1")
editor = FindEditor()
local function CurrencyChoice(name)
    for _, frame in ipairs(frames) do
        if frame.entry and frame.entry.name == name and frame.shown then return frame end
    end
    error("Missing currency checkbox " .. name)
end
local dropdown, choices
local root = { SetScrollMode = function() end, CreateRadio = function(_, name, selected, click) choices[name] = click end }
CurrencyChoice("Token").scripts.OnClick(CurrencyChoice("Token"))
assert(settings.selections.currencies[1] == 3 and settings.selections.currencies[3] == 0, "Unchecking does not compact selected currencies")
CurrencyChoice("Token").scripts.OnClick(CurrencyChoice("Token"))
assert(settings.selections.currencies[3] == 2 and first.rows[3].data.name == "Token")
newAddon.currencyRegistry[#newAddon.currencyRegistry + 1] = {4,1}
editor.update()
CurrencyChoice("Hidden currency").scripts.OnClick(CurrencyChoice("Hidden currency"))
assert(settings.selections.currencies[4] == 4 and first.rows[4].data.name == "Hidden currency")
LEM.active = "Classic"; LEM.callbacks.layout("Classic")
assert(not editor.shown and newAddon.panels[1].rows[1].data.name == "Aperçu 1")
LEM.active = "Modern"; LEM.callbacks.layout("Modern")
assert(first.rows[3].data.name == "Token" and first.rows[4].data.name == "Hidden currency")
LEM.callbacks.create("ContentCopy", 4, "Modern")
local copy = FunelQOLCharDB.layouts.ContentCopy.panel1
copy.selections.currencies[1] = 0
assert(settings.selections.currencies[1] == 3 and copy.customRows ~= settings.customRows)
settings.selections.currencies = { 0, 0, 0, 0, 0, 0, 0, 0 }
newAddon.RefreshPanels()
assert(first.rows[1].data.name == newAddon.panelText.empty and not first.rows[2].shown)
settings.content = "invalid"
newAddon.RefreshPanels()
assert(settings.content == "preview")
settings.content = "custom"
local persistedAddon = { LibEditMode = LEM }
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "CurrencyCatalog.lua", "CurrencyEditor.lua", "QuestContent.lua", "QuestXP.lua", "TrackerContent.lua", "DelveRatings.lua", "DelveQuestContent.lua", "DelveContent.lua", "ProgressContent.lua", "RaidAppearanceActions.lua", "RaidSetContent.lua", "RaidCollection.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
    assert(loadfile(file))("FunelQOL", persistedAddon)
end
local persistedCore = frames[#frames]
persistedCore.scripts.OnEvent(persistedCore, "ADDON_LOADED", "FunelQOL")
persistedCore.scripts.OnEvent(persistedCore, "PLAYER_LOGIN")
assert(persistedAddon.panels[1].rows[1].data.name == "Notes" and persistedAddon.panels[1].rows[2].data.name == "Bank")
assert(persistedAddon.panels[2].rows[1].data.name == "Aperçu 1")
print("PASS: live currencies, seasonal caps, money events, sparse professions, selected talents, custom rows, currency checkboxes, editor selection/reorder/remove/reuse, layout isolation and deep copies.")
-- Quest tracking: watch order, world quests, live objectives and manual selection.
local watches, worldWatches = { 101, 102 }, { 102, 103 }
local questProgress, questComplete = 2, false
local requestedQuests = {}
C_QuestLog = {
    GetNumQuestWatches = function() return #watches end,
    GetQuestIDForQuestWatchIndex = function(index) return watches[index] end,
    GetNumWorldQuestWatches = function() return #worldWatches end,
    GetQuestIDForWorldQuestWatchIndex = function(index) return worldWatches[index] end,
    GetTitleForQuestID = function(id) return id ~= 104 and "Quest " .. id or nil end,
    RequestLoadQuestByID = function(id) requestedQuests[id] = (requestedQuests[id] or 0) + 1 end,
    IsComplete = function(id) return id == 102 and questComplete end,
    IsFailed = function() return false end,
    GetQuestObjectives = function(id)
        if id == 104 then return nil end
        if id == 102 then return {} end
        if id == 103 then return { { text = "Fill the progress bar", type = "progressbar", finished = false, numFulfilled = 0, numRequired = 1 } } end
        return {
            { text = "Collect some especially long named supplies from the camp: " .. questProgress .. "/5", type = "item", finished = questProgress == 5, numFulfilled = questProgress, numRequired = 5 },
            { text = "Speak to the scout", type = "event", finished = true, numFulfilled = 1, numRequired = 1 },
        }
    end,
}
function GetQuestProgressBarPercent() return 42.5 end
local openedQuest
function QuestMapFrame_OpenToQuestDetails(id) openedQuest = id end
first = persistedAddon.panels[1]
settings = FunelQOLCharDB.layouts.Modern.panel1
SetSetting(first, "questTracker", false)
SetSetting(first, "content", "quests")
SetSetting(first, "questReadable", false)
assert(settings.questAuto and first.rows[1].data.questID == 101 and first.rows[1].data.valueText == "70% · 1 / 2")
assert(first.rows[2].data.value == 2 and first.rows[2].data.maximum == 5 and first.rows[2].height > first.rows[3].height, "Objective text does not wrap")
assert(first.rows[4].data.questID == 102 and first.rows[4].data.valueText == persistedAddon.panelText.questActive, "Zero objectives falsely reported ready")
assert(first.rows[5].data.questID == 103 and first.rows[6].data.value == 42.5 and first.rows[6].data.maximum == 100)
assert(not first.rows[7] or not first.rows[7].shown, "Duplicate world quest watch displayed twice")
SetSetting(first, "questAll", false)
SetSetting(first, "questLimit", 1)
assert(first.rows[3].shown and not first.rows[4].shown)
SetSetting(first, "questLimit", 3)
local questEvents
for _, frame in ipairs(frames) do if frame.events.QUEST_WATCH_UPDATE then questEvents = frame end end
assert(questEvents and questEvents.events.QUEST_WATCH_LIST_CHANGED and questEvents.events.QUEST_DATA_LOAD_RESULT)
questProgress, questComplete = 5, true
questEvents.scripts.OnEvent(questEvents, "QUEST_WATCH_UPDATE", 101)
assert(first.rows[1].data.valueText == "100% · 2 / 2" and first.rows[2].data.value == 5)
assert(first.rows[4].data.valueText == persistedAddon.panelText.questReady)
combat = true; first.rows[1].scripts.OnClick(first.rows[1]); assert(openedQuest == nil)
combat = false; first.rows[1].scripts.OnClick(first.rows[1]); assert(openedQuest == 101)
LEM.callbacks.enter(); openedQuest = nil
first.rows[1].scripts.OnClick(first.rows[1]); assert(openedQuest == nil)
LEM.callbacks.exit()
SetSetting(first, "questObjectives", false)
assert(first.rows[1].data.questID == 101 and first.rows[2].data.questID == 102 and first.rows[3].data.questID == 103 and not first.rows[4].shown)
SlashCmdList.FUNELQOL("content 1")
editor = FindEditor()
for _, frame in ipairs(frames) do if frame.parent == editor and frame.menu then dropdown = frame; break end end
choices = {}; dropdown.menu(dropdown, root)
choices["Quest 103"]()
assert(not settings.questAuto and first.rows[1].data.questID == 103, "Editor did not switch to manual quest order")
EditorButton("↓", -92).scripts.OnClick()
assert(first.rows[1].data.questID == 102 and first.rows[2].data.questID == 103)
watches, worldWatches = { 101 }, {}
questEvents.scripts.OnEvent(questEvents, "QUEST_WATCH_LIST_CHANGED")
assert(first.rows[1].data.name == persistedAddon.panelText.empty, "Untracked manual quests remain visible")
watches = { 101, 102 }; worldWatches = { 103 }
questEvents.scripts.OnEvent(questEvents, "QUEST_LOG_UPDATE")
assert(first.rows[1].data.questID == 102 and first.rows[2].data.questID == 103, "Retained selection did not return after retracking")
SetSetting(first, "questAuto", true)
watches = { 104 }; worldWatches = {}
questEvents.scripts.OnEvent(questEvents, "QUEST_DATA_LOAD_RESULT")
questEvents.scripts.OnEvent(questEvents, "QUEST_LOG_UPDATE")
assert(first.rows[1].data.valueText == persistedAddon.panelText.questLoading and requestedQuests[104] == 1, "Uncached quest floods load requests or reports completion")
watches = {}; questEvents.scripts.OnEvent(questEvents, "QUEST_WATCH_LIST_CHANGED")
assert(first.rows[1].data.name == persistedAddon.panelText.questEmpty)
LEM.callbacks.create("QuestCopy", 5, "Modern")
assert(FunelQOLCharDB.layouts.QuestCopy.panel1.content == "quests" and FunelQOLCharDB.layouts.QuestCopy.panel1.selections.quests ~= settings.selections.quests)
print("PASS: tracked quests and world quests, deduplication, live counts/percentages, objective wrapping, ready/loading/empty states, automatic limits, manual selection/order/retracking, layout copy and combat/edit click guard.")
-- Quest categories and semantic border colors survive hover, rendering and reuse.
function methods:SetBackdropBorderColor(...) self.borderColor = { ... } end
Enum = { QuestFrequency = { Default = 0, Daily = 1, Weekly = 2, ResetByScheduler = 3 } }
C_QuestLog.GetLogIndexForQuestID = function(id) return id ~= 104 and id or nil end
C_QuestLog.GetInfo = function(id)
    return { frequency = id == 101 and 1 or id == 102 and 2 or id == 106 and 3 or 0,
        campaignID = id == 105 and 1 or nil, level = 80 }
end
C_QuestLog.IsImportantQuest = function(id) return id == 102 or id == 108 end
C_QuestLog.IsRepeatableQuest = function(id) return id == 107 end
C_QuestLog.IsWorldQuest = function(id) return id == 103 end
watches, worldWatches = { 101, 102, 105, 106, 107, 108, 104 }, { 103 }
questProgress, questComplete = 2, false
SetSetting(first, "questLimit", 8)
SetSetting(first, "questDetails", true)
SetSetting(first, "questColors", true)
SetSetting(first, "questObjectives", false)
assert(first.rows[1].data.name:find("Journalière", 1, true) and first.rows[1].data.name:find("Niv. 80", 1, true))
assert(first.rows[2].data.name:find("Importante", 1, true) and first.rows[2].data.name:find("Hebdomadaire", 1, true))
assert(first.rows[3].data.name:find("Campagne", 1, true))
assert(first.rows[4].data.name:find("Récurrente", 1, true) and not first.rows[4].data.name:find("Hebdomadaire", 1, true), "Scheduler reset wrongly labeled weekly")
assert(first.rows[5].data.name:find("Répétable", 1, true))
assert(first.rows[6].data.name:find("Importante", 1, true))
assert(first.rows[7].data.name == "Quête 104", "Unavailable metadata guessed a normal quest")
assert(first.rows[8].data.name:find("Expédition", 1, true))
local function HasColor(row, expected)
    local actual = row.border.borderColor
    assert(actual and actual[1] == expected[1] and actual[2] == expected[2] and actual[3] == expected[3], "Incorrect quest border color")
end
for _, style in ipairs({ "blizzard", "pixels", "ayije" }) do
    SetSetting(first, "style", style)
    HasColor(first.rows[1], persistedAddon.questColors.recurring)
    HasColor(first.rows[2], persistedAddon.questColors.recurring)
    HasColor(first.rows[3], persistedAddon.questColors.campaign)
    HasColor(first.rows[6], persistedAddon.questColors.important)
    local row = first.rows[1]
    row.scripts.OnEnter(row)
    assert(row.border.borderColor[2] > persistedAddon.questColors.recurring[2], "Hover does not highlight blue border")
    persistedAddon.RefreshPanels()
    assert(row.border.borderColor[2] > persistedAddon.questColors.recurring[2], "Live refresh loses hover color")
    row.scripts.OnLeave(row)
    HasColor(row, persistedAddon.questColors.recurring)
end
assert(first.rows[1].data.valueText == "70% · 1 / 2" and first.rows[1].bar.value == 70 and first.rows[1].bar.maximum == 100)
assert(first.rows[8].data.valueText == "43% · 0 / 1", "Progress bar percentage reduced to finished-objective count")
local tooltipLines = {}
GameTooltip.AddLine = function(_, line) tooltipLines[#tooltipLines + 1] = line end
first.rows[2].scripts.OnEnter(first.rows[2])
assert(tooltipLines[1]:find("Hebdomadaire", 1, true))
tooltipLines = {}
first.rows[1].scripts.OnEnter(first.rows[1])
assert(tooltipLines[2]:find(persistedAddon.panelText.questProgress, 1, true))
first.rows[1].scripts.OnLeave(first.rows[1])
first.rows[2].scripts.OnLeave(first.rows[2])
SetSetting(first, "questDetails", false)
assert(first.rows[1].data.name == "Quest 101" and first.rows[1].data.questDetails:find("Journalière", 1, true), "Compact display erased tooltip metadata")
SetSetting(first, "questColors", false)
HasColor(first.rows[1], { 0.38, 0.35, 0.29 })
SetSetting(first, "questColors", true)
SetSetting(first, "questObjectives", true)
HasColor(first.rows[1], persistedAddon.questColors.recurring)
HasColor(first.rows[2], persistedAddon.questColors.recurring)
SetSetting(first, "content", "preview")
HasColor(first.rows[1], { 0.38, 0.35, 0.29 })
assert(not first.rows[1].data.questID, "Reused preview row retains quest metadata")
print("PASS: daily/weekly/important/campaign/recurring/world labels, partial objective progress, metadata tooltips, category colors across all styles, hover restoration, settings and row reuse.")
-- Complete coverage of the screenshot: all watches, campaign and hand-in instructions.
watches, worldWatches = {}, {}
for id = 201, 214 do watches[#watches + 1] = id end
C_QuestLog.GetTitleForQuestID = function(id) return "Quest " .. id end
C_QuestLog.GetLogIndexForQuestID = function(id) return id end
C_QuestLog.GetInfo = function(id) return { frequency = 0, level = 80, isAutoComplete = id == 203 } end
Enum.QuestClassification = { Campaign = 1, Normal = 2 }
C_QuestInfoSystem = { GetQuestClassification = function(id) return id == 201 and 1 or 2 end }
C_QuestLog.IsImportantQuest = function() return false end
C_QuestLog.IsRepeatableQuest = function() return false end
C_QuestLog.IsWorldQuest = function() return false end
C_QuestLog.IsComplete = function(id) return id == 202 or id == 203 end
C_QuestLog.GetNextWaypointText = function(id) return id == 202 and "Waypoint fallback" or id == 204 and "Travel to the camp" end
function GetQuestLogCompletionText(index) return index == 202 and "Deliver the Plowhead to Aliva at Hillhelm Stead." end
local timeElapsed = 20
C_QuestLog.GetTimeAllowed = function(id) if id == 205 then return 120, timeElapsed end end
C_QuestLog.GetRequiredMoney = function(id) return id == 206 and 100000 or 0 end
C_QuestLog.GetQuestObjectives = function(id) return { { text = "Collect supplies (Optional)", numFulfilled = 1, numRequired = 4, finished = false, type = "item" } } end
SetSetting(first, "content", "quests")
SetSetting(first, "questAll", true)
SetSetting(first, "questLimit", 1)
SetSetting(first, "questHeight", 150)
SetSetting(first, "questDetails", true)
SetSetting(first, "questAuto", true)
local headers = 0
local handIn, automatic, waypoint, timer, moneyRow
for _, row in ipairs(first.rows) do
    if row.shown then
        if row.data.name:find("^Quest ") then headers = headers + 1 end
        if row.data.name:find("Deliver the Plowhead", 1, true) then handIn = row end
        if row.data.autoComplete and row.data.name:find("Clique", 1, true) then automatic = row end
        if row.data.name:find("Travel to the camp", 1, true) then waypoint = row end
        if row.data.name:find("Temps restant", 1, true) then timer = row end
        if row.data.name:find("Argent requis", 1, true) then moneyRow = row end
    end
end
assert(headers == 14, "All-quests mode still truncates watches")
assert(first.rows[1].data.name:find("Campagne", 1, true), "Campaign with no campaignID not classified")
assert(handIn and automatic and waypoint and timer and moneyRow, "Missing native quest instructions/timer/money requirements")
assert(timer.data.valueText == "1:40" and moneyRow.data.maximum == 100000)
assert(first.scrollMaximum > 0 and first.scrollHint.shown and first.viewport.height <= 170)
first.viewport.scripts.OnMouseWheel(first.viewport, -1)
assert(first.viewport:GetVerticalScroll() > 0)
for index = 1, 100 do first.viewport.scripts.OnMouseWheel(first.viewport, -1) end
assert(first.viewport:GetVerticalScroll() == first.scrollMaximum)
for index = 1, 100 do first.viewport.scripts.OnMouseWheel(first.viewport, 1) end
assert(first.viewport:GetVerticalScroll() == 0)
local completedID
function ShowQuestComplete(id) completedID = id end
automatic.scripts.OnClick(automatic); assert(completedID == 203)
combat = true; completedID = nil; automatic.scripts.OnClick(automatic); assert(not completedID)
combat = false
local timerEvents
for _, frame in ipairs(frames) do if frame.events.QUEST_POI_UPDATE then timerEvents = frame end end
assert(timerEvents and timerEvents.events.SUPER_TRACKING_CHANGED and persistedAddon.questHasTimers)
timeElapsed = 22
timerEvents.scripts.OnUpdate(timerEvents, 1)
assert(timer.data.valueText == "1:38", "Quest timer does not refresh without quest events")
SetSetting(first, "questObjectives", false)
persistedAddon.RefreshPanels()
assert(not persistedAddon.questHasTimers)
for _, row in ipairs(first.rows) do assert(not row.shown or not row.data.name:find("Deliver the Plowhead", 1, true)) end
SetSetting(first, "questAll", false)
assert(first.rows[1].shown and not first.rows[2].shown and first.scrollMaximum == 0 and not first.scrollHint.shown)
print("PASS: all watched quests, campaign classification fallback, hand-in/auto-completion/waypoints, optional objective text, money requirements, live timers and bounded mouse-wheel scrolling.")
-- Readability: one surface per quest, full-width titles and a clear text hierarchy.
function methods:SetTextColor(...) self.textColor = { ... } end
SetSetting(first, "questAll", true)
SetSetting(first, "questObjectives", true)
SetSetting(first, "questReadable", true)
SetSetting(first, "showBars", true)
local activeGroups, activeHeaders = 0, 0
local readyHeader, timedObjective
for _, group in ipairs(first.questGroups) do if group.shown then activeGroups = activeGroups + 1 end end
for _, row in ipairs(first.rows) do
    if row.shown then
        assert(not row.border.shown and not row.background.shown, "Objectives still use individual framed boxes")
        assert(not row.value.shown, "Right counters steal title width")
        if row.data.isQuestHeader then
            activeHeaders = activeHeaders + 1
            assert(row.label.text == row.data.questTitle and row.label.width > first.width - 25)
            assert(not row.bar.shown, "Overall quest progress fills the title background")
            assert(not row.meta.text:find("Niv.", 1, true) and not row.meta.text:find("Quête normale", 1, true), "Repeated metadata clutters title")
            if row.data.questComplete then readyHeader = row end
        elseif row.data.questObjective then
            assert(row.label.text:sub(1, 2) == "- ", "Objective indentation/bullet missing")
            if row.data.name:find("Temps restant", 1, true) then timedObjective = row end
            if not row.data.progressBar then assert(not row.bar.shown, "Ordinary count objective still has a progress bar") end
        end
    end
end
assert(activeGroups == 14 and activeGroups == activeHeaders, "Quests are not grouped into one surface each")
assert(readyHeader and readyHeader.label.textColor[2] == 1 and readyHeader.label.textColor[1] < 0.5)
assert(timedObjective and timedObjective.label.text:find("1:38", 1, true) and timedObjective.bar.height < 6, "Compact presentation hides timer value")
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    local group = first.questGroups[1]
    assert(group.height > first.rows[1].height and group.border.shown)
    assert(group.border.borderColor[1] == persistedAddon.questColors.campaign[1])
end
SetSetting(first, "questReadable", false)
assert(not first.questGroups[1].shown and first.rows[1].border.shown and first.rows[1].value.shown)
SetSetting(first, "questReadable", true)
SetSetting(first, "content", "preview")
assert(not first.questGroups[1].shown and first.rows[1].border.shown and not first.rows[1].meta.shown)
print("PASS: one group per quest, full-width larger titles, white/green objective hierarchy, compact metadata, retained timer values, thin progress bars, all border styles and presentation switching.")

-- Model inline texture widths instead of counting texture markup as letters.
function methods:GetUnboundedStringWidth()
    local textureWidth = 0
    local plain = (self.text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|A:([^|]+)|a", function(tag)
        local width = tag:match("^[^:]+:(%d+)")
        textureWidth = textureWidth + (tonumber(width) or 14)
        return ""
    end):gsub("|T([^|]+)|t", function(tag)
        local height, width = tag:match("^[^:]+:(%d+):(%d+)")
        textureWidth = textureWidth + (tonumber(width) ~= 0 and tonumber(width) or self.fontSize or 14)
        return ""
    end)
    return (utf8.len(plain) or #plain) * (self.fontSize or 11) * 0.55 + textureWidth
end
function methods:GetStringWidth()
    return math.min(self.width or math.huge, self:GetUnboundedStringWidth())
end
C_CurrencyInfo.GetCoinTextureString = function(amount, height)
    local parts = {}
    for _, denomination in ipairs({ {10000, "Gold"}, {100, "Silver"}, {1, "Copper"} }) do
        local count = math.floor(amount / denomination[1])
        amount = amount % denomination[1]
        if count > 0 or denomination[1] == 1 then
            parts[#parts + 1] = count .. "|TInterface\\MoneyFrame\\UI-" .. denomination[2] .. "Icon:" .. (height or 14) .. ":" .. (height or 14) .. ":2:0|t"
        end
    end
    return table.concat(parts, " ")
end
SetSetting(first, "content", "currencies")
settings = FunelQOLCharDB.layouts[LEM.active].panel1
settings.selections.currencies = { -1, 3, 0, 0, 0, 0, 0, 0 }
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    for _, width in ipairs({ 180, 260, 420 }) do
        SetSetting(first, "width", width)
        for _, fontSize in ipairs({ 10, 11, 18 }) do
            SetSetting(first, "fontSize", fontSize)
            for _, amount in ipairs({ 0, 65175051, 99999999999, 10000, 51 }) do
                money = amount
                persistedAddon.RefreshPanels()
                local row = first.rows[1]
                local naturalWidth = row.value:GetUnboundedStringWidth()
                assert(row.value.width >= naturalWidth, "Money value is constrained below its inline texture width")
                assert(row.value.wordWrap == false, "Money can wrap into the border")
                assert(row.value.point[2] <= -8, "Money needs an inset for the final coin")
                assert(row.label.width + naturalWidth + 22 <= row.width + 1, "Money overlaps its label")
                for tag in row.value.text:gmatch("|T([^|]+)|t") do
                    local height, size, x, y = tag:match("^[^:]+:(%d+):(%d+):(-?%d+):(-?%d+)$")
                    assert(tonumber(x) == 0 and tonumber(y) == 0, "Inline coin protrudes outside its measured bounds")
                    assert(tonumber(height) == row.value.fontSize and tonumber(size) == row.value.fontSize, "Coin size does not match the value font")
                end
            end
        end
    end
end
print("PASS: money remains single-line and within its reserved bounds, zero-offset coins, all border styles, panel widths, font sizes and changing denominations.")

-- Reference tracker: continuous surface, independently folded sections and map events.
function methods:SetAtlas(atlas) self.atlas = atlas end
Enum.UIMapType = { World = 1, Continent = 2, Zone = 3 }
local maps = {
    [100] = { name = "Khaz Algar", mapType = 2, parentMapID = 1 },
    [160] = { name = "Isle of Dorn", mapType = 3, parentMapID = 100 },
    [161] = { name = "The Ringing Deeps", mapType = 3, parentMapID = 100 },
}
C_Map = { GetBestMapForUnit = function() return 160 end, GetMapInfo = function(id) return maps[id] end }
C_TaskQuest = { GetQuestZoneID = function() return 160 end }
C_QuestLog.GetHeaderIndexForQuest = function() return 999 end
local previousInfo = C_QuestLog.GetInfo
C_QuestLog.GetInfo = function(id) if id == 999 then return { title = "Isle of Dorn", isHeader = true } end; return previousInfo(id) end
C_QuestLog.IsWorldQuest = function(id) return id == 214 end
local eventInfos = {
    [1] = { name = "Awakening the Machine", description = "Defend the machine.", linkedUiMapID = 161, atlasName = "poi-workorders", isCurrentEvent = true },
    [2] = { name = "Theater Troupe", isCurrentEvent = true },
    [3] = { name = "Inactive event", isCurrentEvent = false },
    [4] = { name = "Locked event", isCurrentEvent = true, isLocked = true },
}
C_AreaPoiInfo = {
    GetEventsForMap = function(id) return id == 160 and { 1, 3, 4 } or { 1, 2 } end,
    GetAreaPOIInfo = function(_, id) return eventInfos[id] end,
}
local openedMap
function OpenWorldMap(id) openedMap = id end
SetSetting(first, "width", 320)
settings.title = first.definition.title
SetSetting(first, "fontSize", 12)
SetSetting(first, "content", "quests")
SetSetting(first, "questTracker", true)
SetSetting(first, "questReadable", true)
SetSetting(first, "questEvents", true)
SetSetting(first, "questAll", true)
local function FindTrackerRow(predicate)
    for _, row in ipairs(first.rows) do if row.shown and predicate(row.data) then return row end end
end
local sectionKeys = {}
local questCount, eventCount = 0, 0
for _, row in ipairs(first.rows) do
    if row.shown then
        assert(not row.border.shown, "Continuous tracker still draws per-row borders")
        if row.data.trackerSection then
            sectionKeys[row.data.trackerSection] = true
            assert(not row.background.shown and row.trackerLine.shown)
        elseif row.data.isQuestHeader then
            assert(not row.background.shown and row.icon.shown and row.meta.shown)
            assert(row.meta.text:find("|cff4da6e6", 1, true), "Zone lacks its blue text hierarchy")
            assert(row.label.point[2] == row.meta.point[2] and row.label.point[2] >= 5)
            if row.data.questID then questCount = questCount + 1 else eventCount = eventCount + 1 end
        end
    end
end
assert(sectionKeys.campaign and sectionKeys.quests and sectionKeys.world and sectionKeys.events)
assert(questCount == 14 and eventCount == 2, "Quest lost or inactive/duplicate/locked event shown")
assert(not first.background.shown and first.body.shown and first.header.border.shown)
assert(first.title.text == string.upper(persistedAddon.panelText.trackerTitle))
local ready = FindTrackerRow(function(data) return data.questID == 202 and data.isQuestHeader end)
assert(ready.label.textColor[2] == 1 and ready.label.textColor[1] < 0.5)
local handInRow = FindTrackerRow(function(data) return data.name:find("Deliver the Plowhead", 1, true) end)
assert(handInRow.label.text:sub(1, 2) ~= "- ", "Hand-in instructions are rendered as unfinished objectives")
local event = FindTrackerRow(function(data) return data.eventID == 1 and data.isQuestHeader end)
assert(event.icon.atlas == "poi-workorders" and event.meta.text:find("The Ringing Deeps", 1, true))
event.scripts.OnClick(event); assert(openedMap == 161)
combat = true; openedMap = nil; event.scripts.OnClick(event); assert(not openedMap); combat = false
local campaignSection = FindTrackerRow(function(data) return data.trackerSection == "campaign" end)
LEM.callbacks.enter(); campaignSection.scripts.OnClick(campaignSection)
assert(not settings.questSections.campaign, "Editing unexpectedly folds tracker sections")
LEM.callbacks.exit()
campaignSection.scripts.OnClick(campaignSection)
assert(settings.questSections.campaign and not FindTrackerRow(function(data) return data.questID == 201 end))
assert(FindTrackerRow(function(data) return data.questID == 202 end), "Folding campaign hides ordinary quests")
LEM.callbacks.create("TrackerCopy", nil, LEM.active)
settings.questSections.campaign = false
assert(FunelQOLCharDB.layouts.TrackerCopy.panel1.questSections.campaign, "Section state is not copied independently")
persistedAddon.RefreshPanels()
for _, key in ipairs({ "campaign", "quests", "world", "events" }) do
    local section = FindTrackerRow(function(data) return data.trackerSection == key end)
    section.scripts.OnClick(section)
end
assert(first.scrollMaximum == 0 and not first.scrollHint.shown, "Folded sections leave obsolete scroll space")
settings.questSections = {}
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    assert(first.body.border.shown and not first.questGroups[1].shown)
end
SetSetting(first, "questEvents", false)
assert(not FindTrackerRow(function(data) return data.trackerSection == "events" end))
SetSetting(first, "questEvents", true)
local savedWatches, savedWorldWatches = watches, worldWatches
watches, worldWatches = {}, {}
persistedAddon.RefreshPanels()
assert(FindTrackerRow(function(data) return data.trackerSection == "events" end), "Events require a watched quest")
assert(not FindTrackerRow(function(data) return data.trackerSection == "quests" end), "Empty quest section is still shown")
C_AreaPoiInfo = nil
persistedAddon.RefreshPanels()
assert(not FindTrackerRow(function(data) return data.trackerSection == "events" end), "Missing event API does not degrade gracefully")
assert(first.rows[1].data.name == persistedAddon.panelText.questEmpty and not first.rows[2].shown)
watches, worldWatches = savedWatches, savedWorldWatches
persistedAddon.RefreshPanels()
SetSetting(first, "questTracker", false)
assert(not first.background.shown and first.questGroups[1].shown)
SetSetting(first, "questTracker", true)
SetSetting(first, "content", "currencies")
assert(not first.background.shown and first.body.shown and not first.rows[1].border.shown)
for _, row in ipairs(first.rows) do
    if row.shown then
        assert(not row.trackerLine or not row.trackerLine.shown)
        assert(not row.trackerAccent or not row.trackerAccent.shown)
    end
end
print("PASS: continuous tracker surface, campaign/quest/world/event sections, blue zones, quest icons and completion hierarchy, live deduplicated map events, map click guards, folding/edit guards, saved layout isolation, all themes and renderer switching.")

-- Delves: every supplied rating, localized criteria, authoritative map icons,
-- duplicate map pins, uncertainty, live rotation and independent panel content.
local delvePOIs, delveWidgets, delveQueries = {}, {}, 0
maps[2537] = { name = "Midnight", mapType = 2 }
maps[160] = { name = "Harandar", mapType = 3, parentMapID = 2537 }
C_Map.GetMapChildrenInfo = function(id, _, recursive)
    assert(id == 2537 and recursive)
    return { { mapID = 160 }, { mapID = 160 } }
end
C_AreaPoiInfo = {
    GetDelvesForMap = function(mapID)
        delveQueries = delveQueries + 1
        local ids = {}
        for id, poi in pairs(delvePOIs) do if poi.mapID == mapID then ids[#ids + 1] = id end end
        table.sort(ids)
        return ids
    end,
    GetAreaPOIInfo = function(_, id) return delvePOIs[id] end,
}
C_UIWidgetManager = {
    GetAllWidgetsBySetID = function(id) return { { widgetID = id, widgetType = 8 } } end,
    GetTextWithStateWidgetVisualizationInfo = function(id) return delveWidgets[id] end,
}
function GetAchievementInfo(id)
    if id == 61731 then return id, "Histoires du golfe des souvenirs" end
    return id, ""
end
function GetAchievementCriteriaInfoByID(_, id)
    if id == 220587 then return "Spécial sporasaure" end
end
local references = 0
local grades = {}
for _, definition in ipairs(persistedAddon.delveRatings) do
    for _, reference in ipairs(definition.stories) do
        references = references + 1
        grades[reference[3]] = (grades[reference[3]] or 0) + 1
        delvePOIs = { [1] = { name = definition.name, atlasName = "delves-bountiful", mapID = 2537, tooltipWidgetSet = 301 } }
        delveWidgets = { [301] = { shownState = 1, text = "Story Variant: |cnNORMAL_FONT_COLOR:" .. reference[1] .. "|r" } }
        persistedAddon.InvalidateDelves()
        local active = persistedAddon.GetActiveDelves({ delvesSort = "grade" })
        assert(#active == 1 and active[1].reference == reference and active[1].bountiful == true)
        assert(reference[2]:match("^%d+:%d%d%.%d%d$"), "Invalid reference time")
        for _, alias in ipairs(reference.aliases or {}) do
            delveWidgets[301].text = "Story Variant: " .. alias
            persistedAddon.InvalidateDelves()
            local aliased = persistedAddon.GetActiveDelves({})
            assert(aliased[1].reference == reference, "Story alias matched the wrong delve variant")
        end
    end
end
assert(references == 44 and #persistedAddon.delveRatings == 12)
assert(grades.S == 3 and grades.A == 13 and grades.B == 8 and grades.C == 13 and grades.D == 7 and not grades.F, "Grades differ from supplied tier table")
delvePOIs = {
    [1] = { name = "Le golfe des souvenirs", atlasName = "delves-bountiful", mapID = 2537, tooltipWidgetSet = 301 },
    [2] = { name = "The Darkway", atlasName = "delves-regular", mapID = 2537, tooltipWidgetSet = 302 },
    [3] = { name = "Collegiate Calamity", atlasName = "delves-bountiful", mapID = 2537, tooltipWidgetSet = 303 },
    [4] = { name = "Unknown Delve", atlasName = "future-delve-icon", mapID = 2537 },
    [5] = { name = "Locked Delve", atlasName = "delves-bountiful", mapID = 2537, isLocked = true },
    [11] = { name = "Le golfe des souvenirs", atlasName = "delves-bountiful", mapID = 160, tooltipWidgetSet = 301, isPrimaryMapForPOI = true },
}
delveWidgets = {
    [301] = { shownState = 1, text = "Variante de l’histoire : |cffaa00ffSpécial sporasaure|r" },
    [302] = { shownState = 1, text = "Story Variant: Ogre Powered" },
    [303] = { shownState = 1, text = "Story Variant: Academic Antitoxin" },
}
persistedAddon.InvalidateDelves()
local active = persistedAddon.GetActiveDelves({ delvesSort = "grade" })
assert(#active == 4 and active[1].name == "Le golfe des souvenirs" and active[1].reference[3] == "A")
assert(active[1].delveID == 11 and active[1].mapID == 160, "Primary map pin not used for map clicks")
assert(active[2].name == "Collegiate Calamity" and active[2].reference[3] == "C", "Achievement story alias lost its grade")
assert(active[3].bountiful == false and active[3].reference[3] == "A")
assert(active[4].bountiful == nil, "Unknown atlas falsely classified as a standard delve")
assert(#persistedAddon.GetActiveDelves({ delvesBountifulOnly = true }) == 2)
local queries = delveQueries
persistedAddon.GetActiveDelves({}); assert(delveQueries == queries, "Delves rescan on every render")
local delveEvents
for _, frame in ipairs(frames) do if frame.events.ACTIVE_DELVE_DATA_UPDATE then delveEvents = frame end end
assert(delveEvents and delveEvents.events.UPDATE_UI_WIDGET)
delveEvents.scripts.OnEvent(delveEvents, "UPDATE_UI_WIDGET", { widgetID = 99999 })
assert(delveQueries == queries, "Unrelated widgets rescan all delve maps")
SetSetting(first, "content", "quests")
SetSetting(first, "questTracker", true)
assert(not first.trackerTabs and FindTrackerRow(function(data) return data.questID == 201 end))
local second = persistedAddon.panels[2]
SetSetting(second, "content", "quests")
SetSetting(first, "content", "delves")
assert(first.title.text == "Delves" and second.rows[1].data.trackerSection == "campaign")
local delve = FindTrackerRow(function(data) return data.delveID == 11 end)
assert(delve and delve.value.shown and delve.value.text == "A" and delve.value.fontSize > delve.label.fontSize)
assert(delve.label.width < first.width - 65 and delve.meta.text:find("0:44.01", 1, true))
delve.scripts.OnEnter(delve)
delve.scripts.OnClick(delve); assert(openedMap == 160)
combat = true; openedMap = nil; delve.scripts.OnClick(delve); assert(not openedMap); combat = false
local collegiate = FindTrackerRow(function(data) return data.delveID == 3 end)
assert(collegiate.value.text == "C" and collegiate.meta.text:find("Academic Antitoxin", 1, true))
delveWidgets[303].text = "Story Variant: Unlisted story"
delveEvents.scripts.OnEvent(delveEvents, "UPDATE_UI_WIDGET", { widgetID = 303 })
local unrated = FindTrackerRow(function(data) return data.delveID == 3 end)
assert(unrated.value.text == "?", "Unknown story received a grade")
delveWidgets[303].text = "Story Variant: Academic Antitoxin"
delveEvents.scripts.OnEvent(delveEvents, "UPDATE_UI_WIDGET", { widgetID = 303 })
delveWidgets[301].text = "Story Variant: Descent of the Haranir"
delveEvents.scripts.OnEvent(delveEvents, "UPDATE_UI_WIDGET", { widgetID = 301 })
delve = FindTrackerRow(function(data) return data.delveID == 11 end)
assert(delve.value.text == "C" and delve.meta.text:find("2:14.10", 1, true), "Active story change keeps stale grade")
delvePOIs[1].atlasName, delvePOIs[11].atlasName = "delves-regular", "delves-regular"
delveEvents.scripts.OnEvent(delveEvents, "AREA_POIS_UPDATED")
assert(FindTrackerRow(function(data) return data.delveID == 11 end).data.bountiful == false)
SetSetting(first, "delvesBountifulOnly", true)
assert(not FindTrackerRow(function(data) return data.delveID == 11 end))
SetSetting(first, "delvesBountifulOnly", false)
settings.delvesSections.delves_normal = true
persistedAddon.RefreshPanels()
assert(not FindTrackerRow(function(data) return data.delveID == 11 end))
assert(not settings.questSections.delves_normal, "Delve folding is stored in quest settings")
settings.delvesSections.delves_normal = false
SetSetting(first, "content", "quests")
assert(FindTrackerRow(function(data) return data.questID == 201 end))
SetSetting(first, "content", "delves")
assert(not first.trackerTabs and first.background.shown)
assert(FindTrackerRow(function(data) return data.delveID == 11 end))
local questHeightBefore = settings.questHeight
SetSetting(first, "delvesHeight", 150)
assert(settings.questHeight == questHeightBefore)
assert(first.scrollMaximum > 0)
persistedAddon.ConfigurePanel(1)
local automaticHint
for _, frame in ipairs(frames) do if frame.text == persistedAddon.panelText.delvesHint then automaticHint = frame end end
assert(automaticHint, "Delves editor incorrectly offers static row selection")
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    for _, width in ipairs({ 180, 420 }) do
        SetSetting(first, "width", width)
        for _, fontSize in ipairs({ 10, 18 }) do
            SetSetting(first, "fontSize", fontSize)
            for _, scale in ipairs({ 0.7, 1.5 }) do
                SetSetting(first, "scale", scale)
                local row = FindTrackerRow(function(data) return data.delveID == 11 end)
                local gradeLeft = first.width + row.value.point[2] - row.value.width
                assert(row.label.point[2] + row.label.width <= gradeLeft, "Delve grade overlaps its title")
                assert(row.height >= row.value.fontSize and first.border.shown and not row.border.shown)
            end
        end
    end
end
settings.delvesSections.delves_normal = true
LEM.callbacks.create("DelveCopy", nil, LEM.active)
settings.delvesSections.delves_normal = false
assert(FunelQOLCharDB.layouts.DelveCopy.panel1.delvesSections.delves_normal, "Delve fold settings are not independently copied")
persistedAddon.RefreshPanels()
delveWidgets[301].shownState = 0
persistedAddon.InvalidateDelves(); persistedAddon.RefreshPanels()
assert(FindTrackerRow(function(data) return data.delveID == 11 end).value.text == "?", "Hidden story widget supplies a grade")
delveWidgets[301].shownState = 1
delvePOIs[11].tooltipWidgetSet = 304
delveWidgets[304] = { shownState = 1, text = "Story Variant: Alnmoth Munchies" }
persistedAddon.InvalidateDelves(); persistedAddon.RefreshPanels()
assert(FindTrackerRow(function(data) return data.delveID == 11 end).value.text == "?", "Conflicting map stories supply a grade")
delvePOIs = {}
persistedAddon.InvalidateDelves(); persistedAddon.RefreshPanels()
assert(first.rows[1].data.name == persistedAddon.panelText.delvesEmpty and not first.rows[2].shown)
SetSetting(first, "content", "currencies")
assert(not first.background.shown and not first.trackerTabs and first.rows[1].value.textColor[1] == 1)
print("PASS: all 44 grades across 12 delves, localized names and criteria, standard/bountiful/unknown icons, primary-map deduplication, unknown/hidden/conflicting stories, widget and rotation refresh, cache isolation, independent delve/quest panels and settings, all themes/widths/fonts/scales, automatic editor, folding/layout copy, scrolling and combat guards.")

-- Compact data trackers: one body, shared separators and value-side icons.
ITEM_QUALITY_COLORS = { [4] = { r = 0.64, g = 0.21, b = 0.93 } }
local baseCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
C_CurrencyInfo.GetCurrencyInfo = function(id)
    local info = baseCurrencyInfo(id)
    if info then info.quality = 4 end
    return info
end
settings = FunelQOLCharDB.layouts[LEM.active].panel1
settings.selections.currencies = { 2, -1, 3, 0, 0, 0, 0, 0 }
settings.collapsed = false
settings.title = first.definition.title
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    for _, width in ipairs({ 180, 260, 420 }) do
        SetSetting(first, "width", width)
        for _, fontSize in ipairs({ 10, 18 }) do
            SetSetting(first, "fontSize", fontSize)
            for _, scale in ipairs({ 0.7, 1.5 }) do
                SetSetting(first, "scale", scale)
                assert(first.body.shown and first.header.border.shown)
                assert(first.title.text == "MONNAIES" and first.arrow.point[1] == "LEFT")
                local row = first.rows[1]
                assert(not row.border.shown and not row.background.shown and not row.bar.shown)
                assert(row.separator.shown and not first.rows[3].separator.shown)
                assert(row.label.text == "TOKEN" and row.label.textColor[1] == 0.64 and row.value.textColor[3] == 0.93)
                assert(row.icon.shown and row.icon.point[1] == "RIGHT" and row.width == first.width)
                local iconLeft = row.width + row.icon.point[4] - row.icon.width
                assert(row.label.point[2] + row.label.width <= iconLeft, "Compact label overlaps value icon")
                assert(row.height >= fontSize + 7)
                assert(not first.rows[2].icon.shown, "Money duplicates its coin icons")
                local offset = first.rows[2].point[3] - row.point[3]
                assert(math.abs(offset + row.height) < 0.01, "Compact rows have external gaps")
            end
        end
    end
end
SetSetting(first, "collapsed", true)
assert(not first.body.shown and not first.viewport.shown and first.header.border.shown)
SetSetting(first, "collapsed", false)
assert(first.body.shown and first.viewport.shown)
persistedAddon.SetPanelTitle(1, "My resources")
assert(first.title.text == "MY RESOURCES")
for _, kind in ipairs({ "professions", "talents", "custom" }) do
    SetSetting(first, "content", kind)
    assert(first.body.shown and not first.rows[1].border.shown)
end
SetSetting(first, "content", "preview")
assert(not first.body.shown and first.rows[1].border.shown and not first.rows[1].separator.shown)
assert(first.rows[1].icon.point[1] == "TOPLEFT")
print("PASS: compact data trackers, shared body and separators, automatic/custom headers, rarity colors, icons beside values, coin reuse, collapse and renderer switching across themes, widths, fonts and scales.")

-- Quest tracking shares the compact shell while retaining multiline content.
settings.title = first.definition.title
SetSetting(first, "questReadable", true)
SetSetting(first, "questTracker", true)
SetSetting(first, "questAuto", true)
SetSetting(first, "questAll", true)
SetSetting(first, "content", "quests")
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    for _, width in ipairs({ 180, 260, 420 }) do
        SetSetting(first, "width", width)
        for _, fontSize in ipairs({ 10, 18 }) do
            SetSetting(first, "fontSize", fontSize)
            for _, scale in ipairs({ 0.7, 1.5 }) do
                SetSetting(first, "scale", scale)
                assert(first.body.shown and first.header.border.shown and not first.background.shown)
                assert(first.title.point[1] == "CENTER" and first.arrow.point[1] == "LEFT")
                assert(first.title.text == string.upper(persistedAddon.panelText.trackerTitle))
                local headers, objectives, separators = 0, 0, 0
                for _, row in ipairs(first.rows) do
                    if row.shown then
                        assert(not row.border.shown and not row.background.shown)
                        if row.data.isQuestHeader then
                            headers = headers + 1
                            assert(row.icon.point[1] == "TOPRIGHT" and row.meta.shown)
                            local iconLeft = row.width + row.icon.point[2] - row.icon.width
                            assert(row.label.point[2] + row.label.width <= iconLeft, "Quest title overlaps its right-side icon")
                            assert(row.meta.point[2] + row.meta.width <= iconLeft, "Quest details overlap icon column")
                        elseif row.data.questObjective then
                            objectives = objectives + 1
                            assert(row.label.wordWrap and row.label.point[2] > 6)
                            assert(row.height >= row.label:GetStringHeight(), "Compact quest objective is clipped")
                        elseif row.data.trackerSection then
                            assert(row.trackerLine.shown and row.label.text == (row.data.sectionCollapsed and "+ " or "− ") .. string.upper(row.data.name))
                        end
                        if row.separator.shown then separators = separators + 1 end
                    end
                end
                assert(headers == 14 and objectives > 0 and separators > 0, "Compact quest tracker loses watched content")
                assert(first.scrollMaximum > 0, "Long compact quest list loses scrolling")
            end
        end
    end
end
SetSetting(first, "collapsed", true)
assert(not first.body.shown and not first.viewport.shown and first.header.border.shown)
SetSetting(first, "collapsed", false)
local section = FindTrackerRow(function(data) return data.trackerSection == "campaign" end)
section.scripts.OnClick(section)
assert(not FindTrackerRow(function(data) return data.questID == 201 end))
section.scripts.OnClick(section)
assert(FindTrackerRow(function(data) return data.questID == 201 end))
SetSetting(first, "questTracker", false)
assert(not first.body.shown and first.questGroups[1].shown)
SetSetting(first, "questTracker", true)
assert(first.body.shown and not first.questGroups[1].shown)
print("PASS: compact quest shell, centered header, value-side quest icons, wrapped objectives and metadata, full watched list, section separators, scrolling, collapse/folding and legacy presentation across themes, widths, fonts and scales.")

-- Vault slots are sourced from live thresholds, never fixed seasonal counts.
Enum.WeeklyRewardChestThresholdType = { Activities = 1, RankedPvP = 2, Raid = 3, World = 6 }
local activities = {
    { type = 3, index = 2, id = 32, threshold = 4, progress = 3, level = 1, rewards = {} },
    { type = 1, index = 1, id = 11, threshold = 2, progress = 3, level = 8, rewards = {} },
    { type = 6, index = 1, id = 61, threshold = 2, progress = 1, level = 8, rewards = {} },
    { type = 3, index = 1, id = 31, threshold = 2, progress = 3, level = 1, rewards = {} },
    { type = 1, index = 2, id = 12, threshold = 4, progress = 3, level = 8, rewards = {} },
    { type = 1, index = 3, id = 13, threshold = 8, progress = 3, level = 8, rewards = {} },
    { type = 3, index = 3, id = 33, threshold = 6, progress = 3, level = 1, rewards = {} },
    { type = 6, index = 2, id = 62, threshold = 4, progress = 1, level = 8, rewards = {} },
    { type = 6, index = 3, id = 63, threshold = 8, progress = 1, level = 8, rewards = {} },
    { type = 2, index = 1, id = 21, threshold = 1250, progress = 0, rewards = {} },
    { type = 0, index = 1, id = 1, threshold = 0, progress = 0, rewards = {} },
}
local vaultClaim, rewardLevel = false, 285
C_WeeklyRewards = {
    GetActivities = function() return activities end,
    HasAvailableRewards = function() return vaultClaim end,
    AreRewardsForCurrentRewardPeriod = function() return not vaultClaim end,
    GetExampleRewardItemHyperlinks = function(id) return "item:" .. id end,
}
C_Item = { GetDetailedItemLevelInfo = function() return rewardLevel end }
settings = FunelQOLCharDB.layouts[LEM.active].panel1
settings.title = first.definition.title
SetSetting(first, "content", "vault")
assert(first.body.shown and first.title.text == "CHAMBRE FORTE")
local vaultRows = persistedAddon.GetPanelRows(settings)
assert(#vaultRows == 9 and vaultRows[1].vaultActivityID == 11 and vaultRows[1].valueText == "285")
assert(vaultRows[2].valueText == "3 / 4" and vaultRows[4].vaultActivityID == 31)
assert(vaultRows[1].tooltipLines[2]:find("3 / 2", 1, true), "Vault loses full progress in tooltip")
assert(settings.selections.vault[3] == 6, "Vault categories are not all selected by default")
settings.selections.vault = { 6, 1, 6, 0, 0, 0, 0, 0 }
assert(persistedAddon.GetPanelRows(settings)[1].vaultActivityID == 61 and #persistedAddon.GetPanelRows(settings) == 6)
vaultClaim = true
local progressEvents
for _, frame in ipairs(frames) do if frame.events.WEEKLY_REWARDS_UPDATE then progressEvents = frame end end
assert(progressEvents and progressEvents.events.MAJOR_FACTION_RENOWN_LEVEL_CHANGED and progressEvents.events.UPDATE_FACTION)
progressEvents.scripts.OnEvent(progressEvents, "WEEKLY_REWARDS_UPDATE")
assert(first.rows[1].value.text == "À récupérer" and first.rows[1].data.tooltipLines[1])
assert(first.rows[2].data.tooltipLines[#first.rows[2].data.tooltipLines]:find("précédente", 1, true))
rewardLevel = nil
assert(persistedAddon.GetPanelRows(settings)[5].valueText == "OK", "Uncached reward item level invents a value")
rewardLevel = 285
activities[3].progress = 8
progressEvents.scripts.OnEvent(progressEvents, "WEEKLY_REWARDS_UPDATE")
assert(first.rows[2].value.text == "285", "Vault progress event leaves stale values")
local vaultAPI = C_WeeklyRewards
C_WeeklyRewards = nil
assert(persistedAddon.GetPanelRows(settings)[1].name == "Chambre forte indisponible")
C_WeeklyRewards = vaultAPI

-- Midnight renown includes locked factions but excludes older/hidden entries.
local requestedExpansion
local factionData = {
    [1] = { name = "Current One", expansionID = 11, isUnlocked = true, renownLevel = 12, maxLevel = 20, renownReputationEarned = 1250, renownLevelThreshold = 2500, uiPriority = 1 },
    [2] = { name = "Current Max", expansionID = 11, isUnlocked = true, renownLevel = 20, maxLevel = 20, renownLevelThreshold = 0, uiPriority = 2 },
    [3] = { name = "Current Locked", expansionID = 11, isUnlocked = false, unlockDescription = "Finish the campaign", uiPriority = 3 },
    [4] = { name = "Old Faction", expansionID = 10, isUnlocked = true, renownLevel = 30, uiPriority = 0 },
    [5] = { name = "Current Four", expansionID = 11, isUnlocked = true, renownLevel = 3, renownReputationEarned = 0, renownLevelThreshold = 1000, uiPriority = 4 },
    [6] = { name = "Hidden", expansionID = 11, isUnlocked = true },
}
C_MajorFactions = {
    GetMajorFactionIDs = function(expansion) requestedExpansion = expansion; return { 4, 3, 2, 1, 5, 6, 1 } end,
    GetMajorFactionData = function(id) return factionData[id] end,
    IsMajorFactionHiddenFromExpansionPage = function(id) return id == 6 end,
    HasMaximumRenown = function(id) return id == 2 end,
}
SetSetting(first, "content", "renown")
local renownRows = persistedAddon.GetPanelRows(settings)
assert(requestedExpansion == 11 and #renownRows == 4 and settings.selections.renown[4] == 5)
assert(renownRows[1].valueText == "12 · 50%" and renownRows[2].valueText == "20 · MAX")
assert(renownRows[3].valueText == "Verrouillé" and renownRows[3].tooltipLines[2] == "Finish the campaign")
assert(first.body.shown and first.rows[1].data.factionID == 1)
factionData[1].renownLevel, factionData[1].renownReputationEarned = 13, 0
progressEvents.scripts.OnEvent(progressEvents, "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", 1)
assert(first.rows[1].value.text == "13 · 0%")
persistedAddon.ConfigurePanel(1)
assert(LEM.settings[first][1].values, "Renown content is missing from Edit Mode")
settings.selections.renown = { 3, 1, 0, 0, 0, 0, 0, 0 }
persistedAddon.RefreshPanels()
assert(first.rows[1].data.factionID == 3 and not first.rows[3].shown)
LEM.callbacks.create("ProgressCopy", nil, LEM.active)
settings.selections.renown[1] = 2
assert(FunelQOLCharDB.layouts.ProgressCopy.panel1.selections.renown[1] == 3)
local factionsAPI = C_MajorFactions
C_MajorFactions = nil
assert(persistedAddon.GetPanelRows(settings)[1].name == persistedAddon.panelText.empty)
C_MajorFactions = factionsAPI
for _, content in ipairs({ "vault", "renown" }) do
    SetSetting(first, "content", content)
    for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
        SetSetting(first, "style", style)
        for _, width in ipairs({ 180, 420 }) do
            SetSetting(first, "width", width)
            for _, fontSize in ipairs({ 10, 18 }) do
                SetSetting(first, "fontSize", fontSize)
                for _, row in ipairs(first.rows) do
                    if row.shown then
                        assert(row.value.width >= row.value:GetUnboundedStringWidth(), "Progress tracker value is clipped")
                        local iconLeft = row.width + row.icon.point[4] - row.icon.width
                        assert(row.label.point[2] + row.label.width <= iconLeft, "Progress tracker icon overlaps label")
                        row.scripts.OnEnter(row)
                    end
                end
            end
        end
    end
end
print("PASS: vault live slots/thresholds/reward levels, previous-period claim status, ordered category filtering, missing APIs/item cache, Midnight-only renown, max/locked factions, live events, editor/layout isolation, compact bounds and tooltips.")

-- Blizzard faction emblems retain their full atlas and reset on row reuse.
function methods:SetTexCoord(...) self.texCoords = { ... } end
local setAtlas = methods.SetAtlas
function methods:SetAtlas(atlas)
    setAtlas(self, atlas)
    -- Atlas regions occupy part of a texture sheet; preserve these native UVs.
    self.texCoords = { 0.1, 0.3, 0.2, 0.4 }
end
C_Texture = { GetAtlasInfo = function(atlas)
    if atlas == "majorfactions_icons_court512" or atlas == "majorfactions_icons_amani512" then return { width = 512, height = 512 } end
end }
factionData[1].textureKit = "court"
factionData[2].textureKit = "amani"
factionData[3].textureKit = "missing"
settings.selections.renown = { 1, 2, 3, 0, 0, 0, 0, 0 }
SetSetting(first, "content", "renown")
assert(first.rows[1].data.iconAtlas == "majorfactions_icons_court512")
assert(first.rows[2].icon.atlas == "majorfactions_icons_amani512" and not first.rows[3].data.iconAtlas)
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    for _, width in ipairs({ 180, 420 }) do
        SetSetting(first, "width", width)
        for _, fontSize in ipairs({ 10, 18 }) do
            SetSetting(first, "fontSize", fontSize)
            for _, scale in ipairs({ 0.7, 1.5 }) do
                SetSetting(first, "scale", scale)
                local row = first.rows[1]
                assert(row.icon.atlas == "majorfactions_icons_court512" and row.icon.shown)
                assert(row.icon.texCoords[1] == 0.1 and row.icon.texCoords[2] == 0.3 and row.icon.texCoords[3] == 0.2 and row.icon.texCoords[4] == 0.4, "Faction atlas UVs are overwritten with the entire texture sheet")
                assert(row.icon.width == first.rows[3].icon.width and row.height >= row.icon.height)
                local iconLeft = row.width + row.icon.point[4] - row.icon.width
                assert(row.label.point[2] + row.label.width <= iconLeft, "Renown emblem overlaps label")
                assert(row.value.width >= row.value:GetUnboundedStringWidth())
            end
        end
    end
end
local atlasAPI = C_Texture
C_Texture = nil
persistedAddon.RefreshPanels()
assert(not first.rows[1].data.iconAtlas and not first.rows[1].icon.atlas and first.rows[1].icon.texture == "Interface\\Icons\\Achievement_Reputation_01")
C_Texture = atlasAPI
persistedAddon.RefreshPanels()
SetSetting(first, "content", "currencies")
assert(not first.rows[1].icon.atlas and first.rows[1].icon.texCoords[1] == 0.08, "Faction atlas leaks into currency row")
SetSetting(first, "content", "renown")
assert(first.rows[1].icon.atlas == "majorfactions_icons_court512")
print("PASS: faction-specific Blizzard emblems, validated atlas fallback, uncropped larger logos, compact spacing across themes/widths/fonts/scales and texture reset on row reuse.")

-- Renown logos and values occupy fixed columns regardless of value length.
settings.selections.renown = { 1, 2, 3, 5, 0, 0, 0, 0 }
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    for _, width in ipairs({ 180, 260, 420 }) do
        SetSetting(first, "width", width)
        for _, fontSize in ipairs({ 10, 18 }) do
            SetSetting(first, "fontSize", fontSize)
            for _, scale in ipairs({ 0.7, 1.5 }) do
                SetSetting(first, "scale", scale)
                local topRow = first.rows[1]
                for index = 1, 4 do
                    local row = first.rows[index]
                    assert(row.icon.point[4] == topRow.icon.point[4] and row.icon.width == topRow.icon.width)
                    assert(row.value.point[2] == topRow.value.point[2] and row.value.width == topRow.value.width and row.value.fontSize == topRow.value.fontSize)
                    assert(row.label.width == topRow.label.width, "Renown labels do not share their column")
                    local valueLeft = row.width + row.value.point[2] - row.value.width
                    local iconLeft = row.width + row.icon.point[4] - row.icon.width
                    assert(row.label.point[2] + row.label.width < valueLeft, "Renown label overlaps value column")
                    assert(row.width + row.value.point[2] < iconLeft, "Renown value overlaps right logo column")
                    assert(row.value.width >= row.value:GetUnboundedStringWidth())
                end
            end
        end
    end
end
SetSetting(first, "content", "currencies")
assert(first.rows[1].value.point[2] >= -9, "Renown value column leaks into currency tracker")
print("PASS: fixed right-side renown logo column, aligned value/label columns, uniform value fonts, narrow panel bounds and currency renderer reuse.")

-- Per-character Delver's Call tracking survives quests leaving the journal.
local delveQuestStates = { [93416] = "active", [93385] = "ready", [93384] = "turnedIn", [93410] = "failed" }
local loadedTitles, questLoads = {}, {}
C_QuestLog.IsOnQuest = function(id) return delveQuestStates[id] == "active" or delveQuestStates[id] == "ready" or delveQuestStates[id] == "failed" end
C_QuestLog.IsComplete = function(id) return delveQuestStates[id] == "ready" end
C_QuestLog.IsFailed = function(id) return delveQuestStates[id] == "failed" end
C_QuestLog.IsQuestFlaggedCompleted = function(id) return delveQuestStates[id] == "turnedIn" end
C_QuestLog.IsQuestFlaggedCompletedOnAccount = function() return true end
C_QuestLog.GetTitleForQuestID = function(id) return loadedTitles[id] end
C_QuestLog.RequestLoadQuestByID = function(id) questLoads[id] = (questLoads[id] or 0) + 1 end
C_QuestLog.GetQuestObjectives = function(id) return { { text = "0/1 Complete delve " .. id, finished = false } } end
loadedTitles[93416] = "L’appel du gouffre : Le golfe des souvenirs"
settings = FunelQOLCharDB.layouts[LEM.active].panel1
settings.title = first.definition.title
SetSetting(first, "content", "delvequests")
local calls = persistedAddon.GetPanelRows(settings)
assert(#calls == 14 and first.rows[14].shown and first.body.shown)
local byID = {}
for _, call in ipairs(calls) do
    assert(not byID[call.delveQuestID]); byID[call.delveQuestID] = call
end
assert(byID[93416].delveQuestStatus == "active" and byID[93416].name == "Le golfe des souvenirs")
assert(byID[93385].valueText == "À rendre" and byID[93384].valueText == "Rendue" and byID[93410].valueText == "Échouée")
assert(byID[93386].valueText == "Non prise", "Account completion masks character quest status")
assert(byID[93416].tooltipLines[4]:find("0/1", 1, true), "Delve quest objective missing from hover")
assert(not byID[63436] and not byID[63437], "Unverified Coiled Isle quest invented")
persistedAddon.RefreshPanels(); persistedAddon.RefreshPanels()
for _, count in pairs(questLoads) do assert(count == 1, "Uncached quest title repeatedly requested") end
local function FindCall(id)
    for _, row in ipairs(first.rows) do if row.shown and row.data.delveQuestID == id then return row end end
end
local activeCall = FindCall(93416)
openedQuest = nil
activeCall.scripts.OnClick(activeCall)
assert(openedQuest == 93416)
combat = true; openedQuest = nil; activeCall.scripts.OnClick(activeCall); assert(not openedQuest); combat = false
LEM.callbacks.enter(); activeCall.scripts.OnClick(activeCall); assert(not openedQuest); LEM.callbacks.exit()
FindCall(93386).scripts.OnClick(FindCall(93386)); assert(not openedQuest, "Unaccepted quest opens quest details")
delveQuestStates[93416] = "ready"
progressEvents.scripts.OnEvent(progressEvents, "QUEST_LOG_UPDATE")
assert(FindCall(93416).value.text == "À rendre")
delveQuestStates[93416] = "turnedIn"
progressEvents.scripts.OnEvent(progressEvents, "QUEST_TURNED_IN", 93416)
assert(FindCall(93416).value.text == "Rendue", "Turned-in quest disappears from completion tracker")
delveQuestStates[93385] = nil
progressEvents.scripts.OnEvent(progressEvents, "QUEST_REMOVED", 93385)
assert(FindCall(93385).value.text == "Non prise", "Abandoned quest keeps accepted state")
SetSetting(first, "delveQuestsHideCompleted", true)
assert(not FindCall(93416) and not FindCall(93384) and FindCall(93385))
LEM.callbacks.create("DelveQuestCopy", nil, LEM.active)
SetSetting(first, "delveQuestsHideCompleted", false)
assert(FunelQOLCharDB.layouts.DelveQuestCopy.panel1.delveQuestsHideCompleted)
persistedAddon.ConfigurePanel(1)
local questHint
for _, frame in ipairs(frames) do if frame.text == persistedAddon.panelText.delveQuestsHint then questHint = frame end end
assert(questHint, "Automatic ten-quest tracker offers an eight-slot editor")
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    for _, width in ipairs({ 180, 420 }) do
        SetSetting(first, "width", width)
        for _, fontSize in ipairs({ 10, 18 }) do
            SetSetting(first, "fontSize", fontSize)
            for _, row in ipairs(first.rows) do if row.shown then
                assert(row.value.width >= row.value:GetUnboundedStringWidth())
                row.scripts.OnEnter(row)
            end end
        end
    end
end
local completionAPI = C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted = nil
assert(persistedAddon.GetDelveQuestState(persistedAddon.delveRatings[1]).status == "unknown")
C_QuestLog.IsQuestFlaggedCompleted = completionAPI
for _, definition in ipairs(persistedAddon.delveRatings) do if definition.levelingQuestID then delveQuestStates[definition.levelingQuestID] = "turnedIn" end end
for _, id in ipairs({89507, 95468, 90573, 89268, 92713}) do delveQuestStates[id] = "turnedIn" end
SetSetting(first, "delveQuestsHideCompleted", true)
assert(first.rows[1].data.name == "Toutes les quêtes sont rendues" and not first.rows[2].shown)
settings.delvesSections = {}
SetSetting(first, "delvesBountifulOnly", false)
delvePOIs = { [1] = { name = "The Gulf of Memory", atlasName = "delves-regular", mapID = 2537, tooltipWidgetSet = 301 } }
delveWidgets = { [301] = { shownState = 1, text = "Story Variant: Descent of the Haranir" } }
persistedAddon.InvalidateDelves()
SetSetting(first, "content", "delves")
local delveCall = FindTrackerRow(function(data) return data.delveID == 1 end)
assert(delveCall.data.delveGrade == "C" and delveCall.data.delveQuest.status == "turnedIn")
assert(delveCall.meta.text:find("Quête XP", 1, true) and delveCall.meta.text:find("Rendue", 1, true))
delveCall.scripts.OnEnter(delveCall)
print("PASS: ten verified Delver's Call quests, per-character accepted/ready/turned-in/failed/unknown states, localized title loading, quest events and abandonment, completed filter/layout copy, all-row compact rendering, guarded clicks and existing Delves metadata.")

-- Raid appearance collection: count slots, not duplicate sources or equipped items.
local raidSeason, raidClass, raidLoading = 18, 8, false
function UnitClass() return "Mage", "MAGE", raidClass end
C_MythicPlus = { GetCurrentSeason = function() return raidSeason end }
local learnedSources = { [100] = true, [900] = true }
C_TransmogCollection = {
    GetSourceInfo = function(id)
        if id == 999 then return nil end
        return { visualID = id == 101 and 800 or id, isCollected = learnedSources[id] or false, itemID = id + 10000 }
    end,
    GetAllAppearanceSources = function(visual) return visual == 800 and { 101, 900 } or { visual } end,
}
C_TransmogSets = {
    GetSetInfo = function(id) if not raidLoading then return { setID = id, name = "Mage saison " .. raidSeason } end end,
    GetSourcesForSlot = function(id, slot)
        if raidLoading then return nil end
        if slot == 1 then return { { sourceID = 100 }, { sourceID = 100 } } end
        if slot == 3 then return { { sourceID = 101 } } end
        if slot == 20 then return { { sourceID = 102 } } end
        return {}
    end,
}
local raidSettings = { content = "raidsets" }
local raidRows = persistedAddon.GetPanelRows(raidSettings)
assert(#raidRows == 4 and raidRows[1].raidSetID == 5857 and raidRows[4].raidSetID == 5860)
assert(raidRows[1].valueText == "2 / 3" and raidRows[1].maximum == 3, "Duplicate sources or robe inflate slot totals")
assert(table.concat(raidRows[1].tooltipLines, " "):find("autre objet", 1, true), "Identical learned appearance is missed")
assert(table.concat(raidRows[1].tooltipLines, " "):find("Manquant", 1, true))
raidSettings.selections.raidsets = { 4, 2, 4, 0, 0, 0, 0, 0 }
raidRows = persistedAddon.GetPanelRows(raidSettings)
assert(#raidRows == 2 and raidRows[1].raidSetID == 5860 and raidRows[2].raidSetID == 5858)
raidSeason = 17
assert(persistedAddon.GetPanelRows(raidSettings)[1].raidSetID == 5440, "Season switch retains the wrong raid")
raidSeason = 19
assert(not persistedAddon.GetPanelRows(raidSettings)[1].raidSetID, "Unsupported season falsely displays old sets")
raidSeason = 18
local classBases = { 5885, 5865, 5853, 5873, 5869, 5837, 5877, 5857, 5881, 5861, 5845, 5841, 5849 }
for classID = 1, 13 do
    raidClass = classID
    local variants = persistedAddon.GetPanelRows({ content = "raidsets" })
    assert(#variants == 4 and variants[1].raidSetID == classBases[classID] and variants[4].raidSetID == classBases[classID] + 3)
end
raidClass = 8
local originalBuildInfo = GetBuildInfo
GetBuildInfo = function() return "12.1.0", "123", "", 120100 end
raidSeason = 0
assert(persistedAddon.GetPanelRows(raidSettings)[1].raidSetID == 5860)
GetBuildInfo = function() return "12.0.0", "123", "", 120000 end
assert(persistedAddon.GetPanelRows(raidSettings)[1].raidSetID == 5440)
GetBuildInfo = originalBuildInfo
raidSeason = 18
local originalSources = C_TransmogSets.GetSourcesForSlot
C_TransmogSets.GetSourcesForSlot = function(_, slot) return slot == 1 and { { sourceID = 999 } } or {} end
assert(persistedAddon.GetPanelRows(raidSettings)[1].valueText == "…", "Missing source info reported as uncollected")
C_TransmogSets.GetSourcesForSlot = nil
assert(not persistedAddon.GetPanelRows(raidSettings)[1].raidSetID)
C_TransmogSets.GetSourcesForSlot = originalSources
raidLoading = true
assert(persistedAddon.GetPanelRows(raidSettings)[1].valueText == "…", "Loading data reported as uncollected")
raidLoading = false
SetSetting(first, "content", "raidsets")
assert(first.rows[1].data.raidSetID == 5857 and not first.rows[5].shown)
learnedSources[102] = true
assert(progressEvents.events.TRANSMOG_COLLECTION_UPDATED and progressEvents.events.CHALLENGE_MODE_MAPS_UPDATE)
progressEvents.scripts.OnEvent(progressEvents, "TRANSMOG_COLLECTION_UPDATED")
assert(first.rows[1].value.text == "3 / 3" and first.rows[1].data.compactColor[2] == 1)
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first, "style", style)
    for _, width in ipairs({ 180, 420 }) do
        SetSetting(first, "width", width)
        for _, fontSize in ipairs({ 10, 18 }) do
            SetSetting(first, "fontSize", fontSize)
            for _, row in ipairs(first.rows) do if row.shown then
                assert(row.value.width >= row.value:GetUnboundedStringWidth())
                assert(not row.border.shown and row.label.width > 0)
                row.scripts.OnEnter(row)
            end end
        end
    end
end
persistedAddon.ConfigurePanel(1)
print("PASS: current-season raid sets for all classes and four difficulties, account/shared appearances, duplicate-source and robe grouping, live collection updates, selection ordering, loading/unsupported states and compact rendering in all styles.")

-- Automatic instance context must be independent of the current season and of
-- the user's shared wardrobe / encounter-journal filters.
local raidInstance = { name = "Gouffre venimeux", kind = "raid", difficulty = 16, mapID = 3004 }
local difficultyNames = { [3] = "10 joueurs", [4] = "25 joueurs", [5] = "10 joueurs héroïque", [6] = "25 joueurs héroïque",
    [7] = "Outil Raids", [9] = "40 joueurs", [14] = "Normal", [15] = "Héroïque", [16] = "Mythique", [17] = "Outil Raids" }
function GetDifficultyInfo(id) return difficultyNames[id] end
function GetInstanceInfo() return raidInstance.name, raidInstance.kind, raidInstance.difficulty,
    difficultyNames[raidInstance.difficulty], 0, false, false, raidInstance.mapID end
local allSetCalls = 0
local legacySets = {
    { setID = 201, name = "Ancien set", label = "Citadelle test", description = "Normal", classMask = 128 },
    { setID = 202, name = "Ancien set", label = "Citadelle test", description = "Héroïque", classMask = 128 },
    { setID = 203, name = "Ancien set", label = "Citadelle test", description = "Mythique", classMask = 128 },
    { setID = 204, name = "Autre classe", label = "Citadelle test", description = "Mythique", classMask = 1 },
    { setID = 205, name = "PvP", label = "Saison PvP", description = "Gladiateur", classMask = 128 },
    { setID = 206, name = "Ancien format", label = "Raid ancien", description = "10 joueurs héroïque", classMask = 128 },
    { setID = 207, name = "Ancien format", label = "Raid ancien", description = "25 joueurs héroïque", classMask = 128 },
}
C_TransmogSets.GetAllSets = function() allSetCalls = allSetCalls + 1; return legacySets end
C_TransmogSets.GetVariantSets = function() return {} end
local priorSetInfo = C_TransmogSets.GetSetInfo
C_TransmogSets.GetSetInfo = function(id)
    for _, info in ipairs(legacySets) do if info.setID == id then return info end end
    return priorSetInfo(id)
end
local contextSettings = { content = "raidsets" }
persistedAddon.InvalidateRaidSets()
local instanceRows = persistedAddon.GetPanelRows(contextSettings)
assert(#instanceRows == 4 and instanceRows[4].raidSetCurrent and instanceRows[4].name == "» Mythique")
assert(persistedAddon.GetRaidSetTitle(contextSettings) == raidInstance.name)
contextSettings.selections.raidsets = { 1, 0, 0, 0, 0, 0, 0, 0 }
instanceRows = persistedAddon.GetPanelRows(contextSettings)
assert(#instanceRows == 2 and instanceRows[2].raidSetID == 5860, "Current difficulty hidden by saved selection")
assert(allSetCalls == 1, "Raid metadata rescanned on every render")
raidInstance.mapID, raidInstance.name = 2912, "Flèche du Vide"
instanceRows = persistedAddon.GetPanelRows(contextSettings)
assert(instanceRows[1].raidSetID == 5437 and instanceRows[2].raidSetID == 5440, "Entering an older raid keeps current-season set")
raidInstance.mapID, raidInstance.name, raidInstance.difficulty = 888, "Citadelle test", 15
contextSettings.selections = nil
instanceRows = persistedAddon.GetPanelRows(contextSettings)
assert(#instanceRows == 3 and instanceRows[1].raidSetID == 201 and instanceRows[2].raidSetCurrent and instanceRows[3].raidSetID == 203)
assert(instanceRows[2].tooltipLines[1] == "Citadelle test" and instanceRows[2].tooltipLines[4]:find("Héroïque", 1, true))
raidSeason = 19
assert(persistedAddon.GetPanelRows(contextSettings)[1].raidSetID == 201, "Live season blocks historical raid tracking")
raidSeason = 18
raidInstance.mapID, raidInstance.name, raidInstance.difficulty = 889, "Raid ancien", 5
instanceRows = persistedAddon.GetPanelRows(contextSettings)
assert(#instanceRows == 2 and instanceRows[1].raidSetCurrent and not instanceRows[2].raidSetCurrent, "Both legacy raid sizes marked current")
raidInstance.name, raidInstance.mapID = "Raid sans set", 9999
assert(not persistedAddon.GetPanelRows(contextSettings)[1].raidSetID, "Unidentified raid displays unrelated seasonal set")
raidInstance.kind = "party"
assert(persistedAddon.GetPanelRows(contextSettings)[1].raidSetID == 5857 and not persistedAddon.GetRaidSetTitle(contextSettings))
raidInstance.kind, raidInstance.mapID, raidInstance.name, raidInstance.difficulty = "raid", 3004, "Gouffre venimeux", 16
contextSettings.raidSetsFollowInstance = false
assert(not persistedAddon.GetRaidSetTitle(contextSettings) and not persistedAddon.GetPanelRows(contextSettings)[4].raidSetCurrent)
FunelQOLCharDB.layouts[LEM.active].panel1.title = persistedAddon.panelText.panel .. " 1"
progressEvents.scripts.OnEvent(progressEvents, "ZONE_CHANGED_NEW_AREA")
assert(first.title.text == string.upper(raidInstance.name) and first.rows[4].data.raidSetCurrent)
FunelQOLCharDB.layouts[LEM.active].panel1.title = "Mes apparences"
persistedAddon.RefreshPanels()
assert(first.title.text == "MES APPARENCES", "Automatic raid context overwrites a custom title")
SetSetting(first, "raidSetsFollowInstance", false)
assert(not first.rows[4].data.raidSetCurrent)
SetSetting(first, "raidSetsFollowInstance", true)
raidInstance.difficulty = 14
progressEvents.scripts.OnEvent(progressEvents, "PLAYER_DIFFICULTY_CHANGED")
assert(first.rows[2].data.raidSetCurrent and not first.rows[4].data.raidSetCurrent)
raidInstance.kind = "none"
progressEvents.scripts.OnEvent(progressEvents, "PLAYER_ENTERING_WORLD")
assert(not first.rows[2].data.raidSetCurrent and first.rows[2].data.raidSetID == 5858)
print("PASS: automatic current/historical raid sets, localized raid labels and difficulty variants, class/PvP isolation, legacy sizes, cached metadata, current difficulty visibility, season fallback on exit, follow toggle, custom titles and zone/difficulty events.")

-- Resolve real anchor geometry in physical coordinates rather than only checking
-- which SetPoint arguments were passed. Different panel scales are intentional.
UIParent:SetSize(1920, 1080)
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetClampedToScreen(value) self.clamped = value end
local fractions = { TOPLEFT = {0,1}, TOP = {.5,1}, TOPRIGHT = {1,1}, LEFT = {0,.5}, CENTER = {.5,.5}, RIGHT = {1,.5}, BOTTOMLEFT = {0,0}, BOTTOM = {.5,0}, BOTTOMRIGHT = {1,0} }
local function Rect(frame)
    local scale = frame:GetEffectiveScale()
    local width, height = frame.width * scale, frame.height * scale
    if frame == UIParent then return 0, height, width, 0 end
    local p = frame.point
    local target = p[2]
    local l, t, r, b = Rect(target)
    local own, rel = fractions[p[1]], fractions[p[3]]
    local left = l + (r-l)*rel[1] + p[4]*scale - width*own[1]
    local top = b + (t-b)*rel[2] + p[5]*scale + height*(1-own[2])
    return left, top, left + width, top - height
end
local oldLeft, oldTop = methods.GetLeft, methods.GetTop
function methods:GetLeft() if self == first or self == second then return select(1, Rect(self)) / self:GetEffectiveScale() end; return oldLeft(self) end
function methods:GetTop() if self == first or self == second then return select(2, Rect(self)) / self:GetEffectiveScale() end; return oldTop(self) end
local function Near(a,b) assert(math.abs(a-b) <= 768/physicalHeight + .0001, "Anchor geometry differs: " .. a .. " / " .. b) end
SetSetting(first, "content", "preview")
SetSetting(second, "content", "preview")
SetSetting(first, "scale", 1)
SetSetting(second, "scale", 1)
SetSetting(first, "collapsed", true)
SetSetting(second, "collapsed", true)
LEM.positions[first](first, LEM.active, "TOPLEFT", 200, -100)
SetSetting(second, "anchorTarget", "panel1")
assert(second.point[2] == first and not second.clamped)
local initialTop = select(2, Rect(second))
first.header.scripts.OnClick(first.header)
assert(select(2, Rect(second)) < initialTop - 20, "Opening upper panel overlaps the lower collapsed header")
local gap = 8 * UIParent:GetEffectiveScale()
Near(select(4,Rect(first)) - select(2,Rect(second)), gap)
second.header.scripts.OnClick(second.header)
Near(select(4,Rect(first)) - select(2,Rect(second)), gap)
first.header.scripts.OnClick(first.header)
Near(select(4,Rect(first)) - select(2,Rect(second)), gap)
for _, side in ipairs({ "BOTTOM", "TOP", "LEFT", "RIGHT" }) do
    SetSetting(second, "anchorSide", side)
    for _, align in ipairs({ "start", "center", "finish" }) do
        SetSetting(second, "anchorAlign", align)
        for _, scale in ipairs({ .7, 1.5 }) do
            SetSetting(second, "scale", scale)
            for _, collapsed in ipairs({ true, false }) do
                SetSetting(first, "collapsed", collapsed)
                SetSetting(second, "collapsed", collapsed)
                local l,t,r,b = Rect(first)
                local x,y,z,w = Rect(second)
                if side == "BOTTOM" then Near(b-y,gap)
                elseif side == "TOP" then Near(w-t,gap)
                elseif side == "LEFT" then Near(l-z,gap)
                else Near(x-r,gap) end
                if side == "TOP" or side == "BOTTOM" then
                    Near(align == "start" and x or align == "finish" and z or (x+z)/2,
                        align == "start" and l or align == "finish" and r or (l+r)/2)
                else
                    Near(align == "start" and y or align == "finish" and w or (y+w)/2,
                        align == "start" and t or align == "finish" and b or (t+b)/2)
                end
            end
        end
    end
end
SetSetting(first, "anchorTarget", "panel2")
assert(FunelQOLCharDB.layouts[LEM.active].panel1.anchorTarget == "screen", "Mutual link accepted")
SetSetting(second, "anchorSide", "RIGHT")
SetSetting(second, "anchorAlign", "start")
SetSetting(second, "anchorOffset", 15)
Near(select(2,Rect(second)) - select(2,Rect(first)), 15*UIParent:GetEffectiveScale())
local beforeL,beforeT = Rect(second)
SetSetting(second, "anchorTarget", "screen")
Near(select(1,Rect(second)),beforeL); Near(select(2,Rect(second)),beforeT)
assert(second.clamped)
for point in pairs(fractions) do
    local left,top = Rect(second)
    SetSetting(second, "point", point)
    Near(select(1,Rect(second)),left); Near(select(2,Rect(second)),top)
end
SetSetting(second, "anchorTarget", "panel1")
LEM.callbacks.create("AnchoredCopy", nil, LEM.active)
assert(FunelQOLCharDB.layouts.AnchoredCopy.panel2.anchorTarget == "panel1")
LEM.positions[second](second, LEM.active, "TOPLEFT", 600, -100)
assert(FunelQOLCharDB.layouts[LEM.active].panel2.anchorTarget == "screen" and second.point[2] == UIParent)
assert(FunelQOLCharDB.layouts.AnchoredCopy.panel2.anchorTarget == "panel1", "Anchor layout copy mutated")
local current = FunelQOLCharDB.layouts[LEM.active]
current.panel1.anchorTarget, current.panel2.anchorTarget = "panel2", "panel1"
persistedAddon.RefreshPanels()
assert(current.panel1.anchorTarget == "screen" and current.panel2.anchorTarget == "panel1", "Corrupt saved cycle reaches the frame engine")
print("PASS: persistent panel edge anchors, open/collapsed stacking, all four sides and three alignments at different scales, spacing/cross-offset geometry, nine screen anchors, cycle protection, detach/drag without jumps and layout-copy isolation.")

local function OwnedLink(id) return "|cffa335ee|Hitem:" .. id .. "|h[Objet " .. id .. "]|h|r" end
local ownedBags = { OwnedLink(7002), OwnedLink(7003), OwnedLink(7004), OwnedLink(7005), OwnedLink(7006) }
function GetInventoryItemLink(_, slot) return slot == 1 and OwnedLink(7001) or nil end
NUM_BAG_SLOTS = 4
C_Container = { GetContainerNumSlots = function(bag) return bag == 0 and #ownedBags or 0 end,
    GetContainerItemLink = function(_, slot) return ownedBags[slot] end }
local appearanceCollected, analysisCalls, warm = {}, 0, true
C_TransmogCollection.GetSourceInfo = function(id) return { visualID = id, itemID = id + 20000, isCollected = appearanceCollected[id] or false } end
C_TransmogCollection.GetAllAppearanceSources = function(id) return { id } end
C_TransmogSets.GetSourcesForSlot = function(id, slot)
    if id == 5858 then
        local map = { [1] = 2001, [3] = 2002, [20] = 2003, [6] = 2004 }
        return map[slot] and { { sourceID = map[slot] } } or {}
    end
    return {}
end
C_Item.GetItemUpgradeInfo = function() return { currentLevel = 2, maxLevel = 8 } end
TransmogUpgradeMaster = {
    data = { constants = { upgradeTransmogBreakpoints = { [18] = 6 } } },
    GetSetsForClass = function(_, class, season) assert(class == 8); return season == 18 and {5857,5858,5859,5860} or nil end,
    GetSourceIDsForItemID = function(_, id) return { [2] = id == 7001 and 2001 or 9999 } end,
}
TransmogUpgradeMaster_API = {
    IsCacheWarmedUp = function() return warm end,
    GetAppearanceMissingData = function(link)
        analysisCalls = analysisCalls + 1
        local id = tonumber(link:match("item:(%d+)"))
        local data = { canUpgrade = true, canCatalyse = true,
            contextData = { itemID = id, seasonID = 18, tier = id == 7002 and 2 or 1,
                slot = id == 7001 and 1 or id == 7002 and 3 or id == 7003 and 20 or id == 7005 and 9 or 6,
                isPvpItem = id == 7006 } }
        data.upgradeAppearanceMissing = id == 7001 or id == 7004
        data.catalystAppearanceMissing = id == 7002 or id == 7005 or id == 7006
        data.catalystAppearanceLearnedFromOtherItem = id == 7005
        data.catalystUpgradeAppearanceMissing = id == 7003 or id == 7006
        return data
    end,
}
persistedAddon.InvalidateRaidActions()
local actionsSettings = { content = "raidsets", selections = { raidsets = {2,0,0,0,0,0,0,0} } }
local actionRow = persistedAddon.GetPanelRows(actionsSettings)[1]
assert(actionRow.raidActionModes.upgrade and actionRow.raidActionModes.catalyst and actionRow.raidActionModes.both)
assert(actionRow.value == 0 and actionRow.maximum == 4, "Potential appearances counted as already collected")
local actionHover = table.concat(actionRow.tooltipLines, " ")
local blankLines, namedObjects = 0, 0
for index, line in ipairs(actionRow.tooltipLines) do
    if line == " " then blankLines = blankLines + 1 end
    if line:find("|Hitem:", 1, true) then
        namedObjects = namedObjects + 1
        assert(line:match("^  |c") and not line:find("Sac", 1, true) and not line:find("→", 1, true), "Item name shares its line with action details")
        assert(actionRow.tooltipLines[index + 1]:find("·", 1, true), "Object lacks separate method/location details")
    end
end
assert(blankLines >= 4 and namedObjects == 3, "Raid pieces lack spacing or exact owned-object names")
assert(actionHover:find("7001",1,true) and actionHover:find("7002",1,true) and actionHover:find("7003",1,true))
assert(not actionHover:find("7004",1,true) and not actionHover:find("7005",1,true) and not actionHover:find("7006",1,true), "Unrelated/shared/PvP appearances advertised")
assert(actionHover:find("2 → 6 / 8",1,true) and actionHover:find("Équipé",1,true) and actionHover:find("Sac 0",1,true))
assert(actionHover:find("ffffaa44",1,true) and actionHover:find("ffcc88ff",1,true) and actionHover:find("ffffdd44",1,true))
persistedAddon.GetPanelRows(actionsSettings)
assert(analysisCalls == 6, "Owned inventory reanalyzed for every set/slot")
local previewIDs
function DressUpTransmogSet(ids) previewIDs = ids end
assert(persistedAddon.PreviewRaidSet(actionRow) and #previewIDs == 4 and previewIDs[3] == 2003)
combat = true
previewIDs = nil
assert(not persistedAddon.PreviewRaidSet(actionRow) and not previewIDs)
combat = false
SetSetting(first, "content", "raidsets")
local function NormalSet() for _, row in ipairs(first.rows) do if row.shown and row.data.raidSetID == 5858 then return row end end end
local normal = NormalSet()
local tooltipWidth
GameTooltip.SetMinimumWidth = function(_, width) tooltipWidth = width end
normal.scripts.OnEnter(normal)
assert(tooltipWidth == 420, "Raid hover retains narrow wrapping width")
normal.scripts.OnLeave(normal)
assert(tooltipWidth == 0, "Raid hover width leaks to other tooltips")
normal.scripts.OnClick(normal)
assert(previewIDs and #previewIDs == 4)
previewIDs = nil
LEM.callbacks.enter()
NormalSet().scripts.OnClick(NormalSet())
assert(not previewIDs, "Edit Mode click opens dressing room")
LEM.callbacks.exit()
appearanceCollected[2001] = true
progressEvents.scripts.OnEvent(progressEvents, "TRANSMOG_COLLECTION_UPDATED")
assert(NormalSet().data.value == 1 and not NormalSet().data.raidActionModes.upgrade)
ownedBags = {}
progressEvents.scripts.OnEvent(progressEvents, "BAG_UPDATE_DELAYED")
assert(not NormalSet().data.raidActionModes.catalyst and not NormalSet().data.raidActionModes.both, "Removed item remains actionable")
warm = false
persistedAddon.InvalidateRaidActions()
persistedAddon.RefreshPanels()
assert(persistedAddon.raidUpgradePending and table.concat(NormalSet().data.tooltipLines," "):find("chargement",1,true))
warm = true
ownedBags = { OwnedLink(7002), OwnedLink(7003) }
progressEvents.scripts.OnUpdate(progressEvents, 2)
assert(NormalSet().data.raidActionModes.catalyst and not persistedAddon.raidUpgradePending)
-- Renderer keeps inline action marks within the measured value area.
local oldAtlasInfo = C_Texture.GetAtlasInfo
C_Texture.GetAtlasInfo = function(atlas)
    if atlas == "CreationCatalyst-32x32" or atlas == "CovenantSanctum-Upgrade-Icon-Available" then return {} end
    return oldAtlasInfo(atlas)
end
assert(persistedAddon.GetRaidActionIcon("both"):find("|A:",1,true))
for _, style in ipairs({ "pixels", "ayije", "blizzard" }) do
    SetSetting(first,"style",style)
    for _, width in ipairs({180,420}) do
        SetSetting(first,"width",width)
        for _, fontSize in ipairs({10,18}) do
            SetSetting(first,"fontSize",fontSize)
            local row = NormalSet()
            assert(row.value.width >= row.value:GetUnboundedStringWidth())
            row.scripts.OnEnter(row)
        end
    end
end
local originalActionAPI = TransmogUpgradeMaster_API
TransmogUpgradeMaster_API = { IsCacheWarmedUp = function() return true end, GetAppearanceMissingData = function() error("Changed TUM API") end }
persistedAddon.InvalidateRaidActions()
actionRow = persistedAddon.GetPanelRows(actionsSettings)[1]
assert(not next(actionRow.raidActionModes) and table.concat(actionRow.tooltipLines," "):find("incomplète",1,true))
TransmogUpgradeMaster_API = originalActionAPI
TransmogUpgradeMaster_API = nil
persistedAddon.InvalidateRaidActions()
actionRow = persistedAddon.GetPanelRows(actionsSettings)[1]
assert(not next(actionRow.raidActionModes) and actionRow.value == 1 and actionRow.valueText == "1 / 4")
assert(table.concat(actionRow.tooltipLines," "):find("Active Transmog Upgrade Master",1,true))
print("PASS: TUM-backed owned-item upgrade/catalyst/combined routes, exact target visuals, item links/locations/breakpoints, shared/PvP exclusion, inventory caching/events/warmup, uncollected-only indicators, compact bounds, full-set dressing-room preview and combat/Edit Mode guards.")
local originalCurrencyInfo, originalCrestSeason = C_CurrencyInfo.GetCurrencyInfo, C_MythicPlus.GetCurrentSeason
local crestSeason, crestQuantity = 18, 1234
C_MythicPlus.GetCurrentSeason = function() return crestSeason end
local queriedCrests = {}
C_CurrencyInfo.GetCurrencyInfo = function(id)
    queriedCrests[id] = true
    if id == 3444 or id == 3445 or id == 3446 or id == 3343 or id == 3345 or id == 3347 then
        return { name = "Crest " .. id, quantity = crestQuantity, iconFileID = id + 7000000,
            useTotalEarnedForMaxQty = true, totalEarned = 90, maxQuantity = 100 }
    end
    return originalCurrencyInfo(id)
end
local crestSettings = { content = "currencies", selections = { currencies = {-2,0,0,0,0,0,0,0} } }
local crestRow = persistedAddon.GetPanelRows(crestSettings)[1]
assert(#crestRow.crestAmounts == 3 and #crestRow.tooltipLines == 6 and crestRow.tooltipLines[2]:find("90 / 100",1,true))
assert(queriedCrests[3444] and queriedCrests[3445] and queriedCrests[3446] and not queriedCrests[3439], "Crests use hidden counters instead of spendable balances")
local crestChoice
for _, entry in ipairs(persistedAddon.GetContentCatalog("currencies")) do if entry.id == -2 then crestChoice = entry.name end end
assert(crestChoice == persistedAddon.panelText.crests)
SetSetting(first,"content","currencies")
FunelQOLCharDB.layouts[LEM.active].panel1.selections.currencies = {-2,0,0,0,0,0,0,0}
persistedAddon.RefreshPanels()
for _, style in ipairs({"pixels","ayije","blizzard"}) do
    SetSetting(first,"style",style)
    SetSetting(first,"width",180)
    SetSetting(first,"fontSize",18)
    local crestFrame = first.rows[1]
    assert(not crestFrame.value.shown and #crestFrame.crests == 3, "Crests still use baseline-aligned inline artwork")
    for _, crest in ipairs(crestFrame.crests) do
        assert(crest.icon.point[1] == "RIGHT" and crest.icon.point[2] == crestFrame and crest.icon.point[5] == 0)
        assert(-crest.icon.point[4] + crest.icon.width <= crestFrame.width - 6, "Crest exceeds horizontal row bounds")
        assert(crest.icon.height + 8 <= crestFrame.height + 1, "Crest exceeds vertical padded row bounds")
    end
end
crestQuantity = 42
progressEvents.scripts.OnEvent(progressEvents,"CURRENCY_DISPLAY_UPDATE")
assert(first.rows[1].data.crestAmounts[1].quantity == 42, "Grouped crests do not refresh")
SetSetting(first,"width",300)
SetSetting(first,"fontSize",10)
assert(first.rows[1].crests[1].icon.width >= 19, "Crest icons shrink with the text")
assert(first.rows[1].height >= 28, "Large crest icons lack vertical padding")
SetSetting(first,"content","custom")
for _, crest in ipairs(first.rows[1].crests) do assert(not crest.icon.shown and not crest.count.shown, "Crest widgets survive row reuse") end
crestSeason = 17
crestRow = persistedAddon.GetPanelRows(crestSettings)[1]
assert(crestRow.tooltipLines[1]:find("3343",1,true) and queriedCrests[3345] and queriedCrests[3347])
crestSeason = 99
assert(not persistedAddon.GetPanelRows(crestSettings)[1].crestAmounts, "Unknown season shows stale crests")
crestSeason = 18
C_CurrencyInfo.GetCurrencyInfo = function() return nil end
assert(persistedAddon.GetPanelRows(crestSettings)[1].valueText == "…", "Unloaded currencies look like zero balances")
C_CurrencyInfo.GetCurrencyInfo, C_MythicPlus.GetCurrentSeason = originalCurrencyInfo, originalCrestSeason
print("PASS: grouped Champion/Hero/Myth crests, spendable seasonal IDs, editor choice, earned cap tooltip, live updates, narrow icon bounds and loading/unsupported season handling.")
function methods:SetColorTexture(...) self.color = {...} end
local visualSettings = FunelQOLCharDB.layouts[LEM.active].panel1
visualSettings.backgroundRevision, visualSettings.opacity = nil, 0.94
SetSetting(first,"content","renown")
visualSettings.selections.renown = {1,2,3,0,0,0,0,0}
visualSettings.showBars = true
factionData[1].renownReputationEarned = 1250
persistedAddon.RefreshPanels()
assert(visualSettings.opacity == 0.8 and first.body.background.color[4] == 0.8 and first.header.background.color[4] == 0.8, "Old saved backgrounds did not migrate to 80 percent")
assert(first.rows[1].bar.shown and first.rows[1].bar.value == 1250 and first.rows[1].bar.maximum == 2500)
assert(first.rows[1].bar.barColor[4] == 0.3, "Compact gauge obscures text")
assert(first.rows[2].bar.shown and first.rows[2].bar.value == first.rows[2].bar.maximum, "Max renown lacks full gauge")
assert(not first.rows[3].bar.shown, "Locked faction shows invented progression")
visualSettings.opacity = 0.6
persistedAddon.RefreshPanels()
assert(first.body.background.color[4] == 0.6, "Opacity migration repeats over user adjustments")
visualSettings.opacity = 0.8
for _, style in ipairs({"pixels","ayije","blizzard"}) do
    SetSetting(first,"style",style)
    for _, width in ipairs({180,420}) do
        SetSetting(first,"width",width)
        assert(first.rows[1].bar.shown and first.rows[1].bar.points[1][1] == "TOPLEFT" and first.rows[1].bar.points[2][1] == "BOTTOMRIGHT")
        assert(first.rows[1].bar.points[1][2] == 0 and first.rows[1].bar.points[1][3] == 0 and first.rows[1].bar.points[2][2] == 0 and first.rows[1].bar.points[2][3] == 0, "Compact gauges retain unnecessary margins")
        assert(first.rows[1].width == first.width, "Compact rows retain side margins")
        assert(first.rows[1].separator.parent.level > first.rows[1].bar.level, "Divider lies underneath the gauge")
        assert(first.rows[1].separator.color[4] == 1, "Divider lacks contrast")
    end
end
visualSettings.showBars = false
persistedAddon.RefreshPanels()
assert(not first.rows[1].bar.shown, "Gauge setting ignored")
visualSettings.showBars = true
SetSetting(first,"content","vault")
for _, row in ipairs(first.rows) do
    if row.shown and row.data.vaultActivityID then assert(row.bar.shown and row.bar.value <= row.bar.maximum) end
end
SetSetting(first,"content","raidsets")
assert(NormalSet().bar.shown and NormalSet().bar.value == 1 and NormalSet().bar.maximum == 4)
SetSetting(first,"content","professions")
assert(first.rows[1].bar.shown and first.rows[1].bar.value == 25 and first.rows[1].bar.maximum == 100)
SetSetting(first,"content","currencies")
visualSettings.selections.currencies = {-2,-1,2,0,0,0,0,0}
persistedAddon.RefreshPanels()
for _, row in ipairs(first.rows) do if row.shown then assert(not row.bar.shown, "Balance-only currency gains misleading gauge") end end
print("PASS: one-time 80 percent saved-background migration, subsequent opacity edits, subtle compact renown next-level/max/locked gauges, styles/widths, gauge toggle, vault/raid/profession progress and balance-only exclusions.")
local beforeCurrencyInfo=C_CurrencyInfo.GetCurrencyInfo
for i=1,9 do persistedAddon.currencyRegistry[#persistedAddon.currencyRegistry+1]={90000+i,264} end
local menuQueries=0
C_CurrencyInfo.GetCurrencyInfo=function(id)
    menuQueries=menuQueries+1
    if id>90000 and id<=90009 then return {name="Currency "..(id-90000),iconFileID=134400,quantity=0} end
    return beforeCurrencyInfo(id)
end
visualSettings.selections.currencies={2,3,0,0,0,0,0,0}
persistedAddon.ConfigurePanel(1)
local currencyWindow=FindEditor()
assert(currencyWindow.height==620 and currencyWindow.shown)
local function InCurrencyWindow(frame)
    while frame do if frame==currencyWindow then return true end; frame=frame.parent end
end
local function VisibleCurrency(name)
    for _,frame in ipairs(frames) do if InCurrencyWindow(frame) and frame.entry and frame.shown and frame.entry.name==name then return frame end end
end
assert(VisibleCurrency("Token").check.checked and VisibleCurrency("Season").check.checked, "Saved selections were not retained")
assert(VisibleCurrency("Currency 1") and not VisibleCurrency("Currency 1").check.checked, "Undiscovered registered currency missing")
local hasMidnight, searchBox=false,nil
for _,frame in ipairs(frames) do
    if InCurrencyWindow(frame) and frame.text=="Midnight" then hasMidnight=true end
    if frame.parent==currencyWindow and frame.scripts.OnTextChanged then searchBox=frame end
end
assert(hasMidnight and searchBox, "Missing category heading/search")
searchBox:SetText("Currency 1"); searchBox.scripts.OnTextChanged(searchBox,true)
assert(VisibleCurrency("Currency 1") and not VisibleCurrency("Token"), "Search leaves unrelated currencies visible")
VisibleCurrency("Currency 1").scripts.OnClick(VisibleCurrency("Currency 1"))
assert(visualSettings.selections.currencies[3]==90001 and first.rows[3].data.valueText=="0", "Zero-balance currency could not be selected")
searchBox:SetText(""); searchBox.scripts.OnTextChanged(searchBox,true)
for i=2,6 do VisibleCurrency("Currency "..i).scripts.OnClick(VisibleCurrency("Currency "..i)) end
local checked=0
for _,id in ipairs(visualSettings.selections.currencies) do if id~=0 then checked=checked+1 end end
assert(checked==8)
VisibleCurrency("Currency 7").scripts.OnClick(VisibleCurrency("Currency 7"))
assert(not VisibleCurrency("Currency 7").check.checked and visualSettings.selections.currencies[8]==90006, "Checkbox cap silently replaces a saved row")
local moveDown, removeFirst, clearAll
for _,frame in ipairs(frames) do
    if frame.parent==currencyWindow then
        if frame.text=="↓" and frame.point[3]==-458 then moveDown=frame end
        if frame.text=="×" and frame.point[3]==-458 then removeFirst=frame end
        if frame.text=="Tout retirer" then clearAll=frame end
    end
end
-- There are two columns; use the first column's buttons.
for _,frame in ipairs(frames) do
    if frame.parent==currencyWindow and frame.point and frame.point[3]==-458 then
        if frame.text=="↓" and frame.point[2]==210 then moveDown=frame end
        if frame.text=="×" and frame.point[2]==236 then removeFirst=frame end
    end
end
moveDown.scripts.OnClick()
assert(visualSettings.selections.currencies[1]==3 and visualSettings.selections.currencies[2]==2)
removeFirst.scripts.OnClick()
assert(visualSettings.selections.currencies[1]==2 and not VisibleCurrency("Season").check.checked, "Removal fails to sync checks/order")
local frameCount=#frames
persistedAddon.CloseContentEditor(); assert(not currencyWindow.shown)
persistedAddon.ConfigurePanel(1); assert(#frames==frameCount and currencyWindow.shown, "Currency editor reopen leaks frames")
menuQueries=0
persistedAddon.RefreshPanels()
assert(menuQueries<20, "Every panel refresh scans entire currency registry")
clearAll.scripts.OnClick()
assert(first.rows[1].data.name==persistedAddon.panelText.empty and not VisibleCurrency("Token").check.checked)
persistedAddon.CloseContentEditor()
C_CurrencyInfo.GetCurrencyInfo=beforeCurrencyInfo
print("PASS: visual categorized two-column currency selection, native icons/check states, saved selections, undiscovered zero balances, search, eight-row cap, reorder/removal/clear, editor reuse and no full-catalog scans during tracking.")
SetSetting(first,"content","renown")
visualSettings.selections.renown={1,2,3,0,0,0,0,0}
persistedAddon.RefreshPanels()
local loadRenown, toggleRenown=0,0
local function CreateRenownSummary()
    MajorFactionRenownFrame={shown=false,currentFactionID=nil,
        IsShown=function(self) return self.shown end,
        GetCurrentFactionID=function(self) return self.currentFactionID end}
    ToggleMajorFactionRenown=function(id)
        toggleRenown=toggleRenown+1
        MajorFactionRenownFrame.currentFactionID=id; MajorFactionRenownFrame.shown=true
    end
end
MajorFactionRenownFrame,ToggleMajorFactionRenown=nil,nil
MajorFactions_LoadUI=function() loadRenown=loadRenown+1; CreateRenownSummary() end
local factionRow=first.rows[1]
assert(factionRow.clicks[2]=="RightButtonUp")
factionRow.scripts.OnClick(factionRow,"LeftButton")
assert(loadRenown==0)
factionRow.scripts.OnClick(factionRow,"RightButton")
assert(loadRenown==1 and toggleRenown==1 and MajorFactionRenownFrame.currentFactionID==1)
factionRow.scripts.OnClick(factionRow,"RightButton")
assert(toggleRenown==1 and MajorFactionRenownFrame.shown, "Repeated click closes renown summary")
first.rows[2].scripts.OnClick(first.rows[2],"RightButton")
assert(toggleRenown==2 and MajorFactionRenownFrame.currentFactionID==2, "Summary does not follow clicked faction")
combat=true
first.rows[1].scripts.OnClick(first.rows[1],"RightButton")
assert(toggleRenown==2)
combat=false
LEM.callbacks.enter()
first.rows[1].scripts.OnClick(first.rows[1],"RightButton")
assert(toggleRenown==2)
LEM.callbacks.exit()
MajorFactionRenownFrame,ToggleMajorFactionRenown,MajorFactions_LoadUI=nil,nil,nil
local beforeAddOns=C_AddOns
C_AddOns={LoadAddOn=function(name) assert(name=="Blizzard_MajorFactions"); CreateRenownSummary() end}
assert(persistedAddon.OpenRenownSummary(3) and MajorFactionRenownFrame.currentFactionID==3)
MajorFactionRenownFrame,ToggleMajorFactionRenown=nil,nil
C_AddOns={LoadAddOn=function() return false,"FAILED" end}
assert(not persistedAddon.OpenRenownSummary(1), "Missing Blizzard module not handled")
C_AddOns=beforeAddOns
print("PASS: right-click Blizzard renown summary, exact faction, load-on-demand and modern loader fallback, repeated-click open behavior, left-click isolation, combat/Edit Mode guards and unavailable UI handling.")

-- Retail 12.1's View Renown button opens the Adventure Guide Journeys page,
-- not the old MajorFactionRenownFrame (which is no longer created).
local oldShowPanel, oldAddOns = ShowUIPanel, C_AddOns
local journeyFaction, journeyTab, journalLoads=nil,nil,0
MajorFactionRenownFrame,ToggleMajorFactionRenown,MajorFactions_LoadUI=nil,nil,nil
local function CreateJournal()
    EncounterJournal={shown=false,JourneysTab={GetID=function() return 5 end},IsShown=function(self) return self.shown end}
    EncounterJournalJourneysFrame={ResetView=function(_,view,factionID) assert(view==nil); journeyFaction=factionID end}
end
EncounterJournal,EncounterJournalJourneysFrame=nil,nil
EncounterJournal_LoadUI=function() journalLoads=journalLoads+1; CreateJournal() end
EJ_ContentTab_Select=function(id) journeyTab=id end
ShowUIPanel=function(frame) assert(frame==EncounterJournal); frame.shown=true end
C_AddOns={LoadAddOn=function() return false end}
first.rows[1].scripts.OnClick(first.rows[1],"RightButton")
assert(journeyFaction==1 and journeyTab==5 and journalLoads==1 and EncounterJournal.shown, "Retail right click does not open the faction Journeys summary")
first.rows[2].scripts.OnClick(first.rows[2],"RightButton")
assert(journeyFaction==2 and journalLoads==1, "Journeys summary does not switch factions")
first.rows[2].scripts.OnClick(first.rows[2],"RightButton")
assert(EncounterJournal.shown and journeyFaction==2)
combat=true
first.rows[1].scripts.OnClick(first.rows[1],"RightButton")
assert(journeyFaction==2)
combat=false
EncounterJournal,EncounterJournalJourneysFrame,EncounterJournal_LoadUI=nil,nil,nil
C_AddOns={LoadAddOn=function(name) assert(name=="Blizzard_EncounterJournal"); CreateJournal(); return true end}
assert(persistedAddon.OpenRenownSummary(3) and journeyFaction==3)
EncounterJournal,EncounterJournalJourneysFrame=nil,nil
C_AddOns={LoadAddOn=function() return false end}
assert(not persistedAddon.OpenRenownSummary(1))
ShowUIPanel,C_AddOns=oldShowPanel,oldAddOns
EJ_ContentTab_Select=nil
print("PASS: Retail Adventure Guide Journeys renown routing, native View Renown path, load-on-demand, exact faction/tab, repeat clicks, combat guard, modern loader fallback and unavailable UI handling.")

-- XP summary integrates into compact delve rows and sectioned quest panels.
do
    UnitXP = function() return 1000 end
    UnitXPMax = function() return 10000 end
    GetQuestLogRewardXP = function(id) return id == 93416 and 7000 or 2000, id == 93416 and 5000 or 2000 end
    C_QuestLog.GetNumQuestLogEntries = function() return 2 end
    C_QuestLog.GetQuestIDForLogIndex = function(index) return index == 1 and 93416 or 999999 end
    C_QuestLog.GetInfo = function(index) return {questID = index == 1 and 93416 or 999999, title = "XP quest", level = 84} end
    C_QuestLog.IsComplete = function(id) return id == 93416 end
    C_QuestLog.IsFailed = function() return false end
    C_QuestLog.IsOnQuest = function(id) return id == 93416 or id == 999999 end
    for _, content in ipairs({"delvequests", "quests"}) do
        SetSetting(first, "content", content)
        assert(first.rows[1].data.questXPSummary and first.rows[2].data.questXPSummary)
        assert(first.rows[1].data.name:find("XP", 1, true))
        first.rows[1].scripts.OnEnter(first.rows[1])
        first.rows[1].scripts.OnClick(first.rows[1])
        if content == "delvequests" then assert(first.rows[1].value.text == "7000")
        else assert(first.rows[1].label.text:find("7000", 1, true)) end
    end
    assert(persistedAddon.GetQuestXPSummary().total == 9000, "Unwatched quest is excluded from journal XP")
    print("PASS: XP summary rendered in compact delve and sectioned quest trackers, hover/click and unwatched journal totals.")
end

-- Raid collection integrates into the compact renderer, scrolling and editor.
do
    EncounterJournal = nil
    GetInstanceInfo = function() return "Collection Raid", "raid", 15, "Heroic", nil, nil, nil, 555 end
    persistedAddon.GetRaidSetRows = function() return {{raidSetCurrent=true, raidPreviewSources={900}, raidSetPieces={{name="Head: Missing tier",itemID=9,state="missing",routes={}}}}} end
    EJ_GetSelectedInstance = function() return 42 end
    EJ_GetDifficulty = function() return 14 end
    EJ_GetLootFilter = function() return 0, 0 end
    EJ_SelectInstance = function() end
    EJ_SetDifficulty = function() end
    EJ_SetLootFilter = function() end
    EJ_IsValidInstanceDifficulty = function() return true end
    EJ_GetNumLoot = function() return 30 end
    EJ_GetEncounterInfo = function() return "Collection boss" end
    C_EncounterJournal = {
        GetInstanceForGameMap=function() return 55 end,
        GetLootInfoByIndex=function(index) return {itemID=index+10,encounterID=11,name="Missing mount "..index,icon=132143,link="item:"..(index+10)} end,
    }
    C_Item.IsItemDataCachedByID = function() return true end
    C_MountJournal = {GetMountFromItem=function(id) return id end,GetMountInfoByID=function() return nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,false end}
    local itemTooltip
    GameTooltip.SetHyperlink = function(_,link) itemTooltip=link end
    settings = FunelQOLCharDB.layouts[LEM.active].panel1
    settings.title = first.definition.title
    SetSetting(first,"questHeight",150)
    SetSetting(first,"content","raidcollection")
    assert(first.title.text=="COLLECTION RAID" and first.body.shown and first.scrollMaximum>0)
    local boss, reward
    for _,row in ipairs(first.rows) do
        if row.shown and row.data.raidCollectionBossKey=="boss:11" then boss=row end
        if row.shown and row.data.raidCollectionLink then reward=reward or row end
    end
    assert(boss and reward)
    reward.scripts.OnEnter(reward)
    assert(itemTooltip==reward.data.raidCollectionLink)
    local previewLink
    DressUpMountLink = function(link) previewLink=link; return true end
    reward.scripts.OnClick(reward, "LeftButton")
    assert(previewLink==reward.data.raidCollectionLink, "Reward row did not open the native preview")
    previewLink=nil; combat=true
    reward.scripts.OnClick(reward, "LeftButton")
    assert(not previewLink, "Reward preview opened in combat")
    combat=false
    boss.scripts.OnClick(boss)
    assert(settings.raidCollection.collapsed["boss:11"])
    for _,row in ipairs(first.rows) do assert(not(row.shown and row.data.raidCollectionLink)) end
    persistedAddon.ConfigurePanel(1)
    persistedAddon.CloseContentEditor()
    print("PASS: raid collection content menu, contextual title, compact rows, height/scroll, native reward tooltip, boss fold and category editor.")
end

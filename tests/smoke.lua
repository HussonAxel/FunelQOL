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
GameTooltip = { SetOwner = function() end, SetCurrencyByID = function() end, SetText = function() end, AddLine = function() end, Show = function() end, Hide = function() end }
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
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "QuestContent.lua", "TrackerContent.lua", "DelveRatings.lua", "DelveContent.lua", "ProgressContent.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
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
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "QuestContent.lua", "TrackerContent.lua", "DelveRatings.lua", "DelveContent.lua", "ProgressContent.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
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
        if frame.width == 560 and frame.height == 414 then return frame end
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
local dropdown
for _, frame in ipairs(frames) do if frame.parent == editor and frame.menu then dropdown = frame; break end end
local choices = {}
local root = { SetScrollMode = function() end, CreateRadio = function(_, name, selected, click) choices[name] = click end }
dropdown.menu(dropdown, root)
choices.Token()
assert(settings.selections.currencies[1] == 2 and first.rows[1].data.name == "Token")
local idBox
for _, frame in ipairs(frames) do
    if frame.parent == editor and frame.point and frame.point[2] == 48 and frame.point[3] == -380 then idBox = frame end
end
idBox:SetText("4")
EditorButton("Ajouter un ID monnaie", -380).scripts.OnClick()
assert(settings.selections.currencies[4] == 4 and first.rows[4].data.name == "Hidden currency")
LEM.active = "Classic"; LEM.callbacks.layout("Classic")
assert(not editor.shown and newAddon.panels[1].rows[1].data.name == "Aperçu 1")
LEM.active = "Modern"; LEM.callbacks.layout("Modern")
assert(first.rows[1].data.name == "Token" and first.rows[4].data.name == "Hidden currency")
LEM.callbacks.create("ContentCopy", 4, "Modern")
local copy = FunelQOLCharDB.layouts.ContentCopy.panel1
copy.selections.currencies[1] = 0
assert(settings.selections.currencies[1] == 2 and copy.customRows ~= settings.customRows)
settings.selections.currencies = { 0, 0, 0, 0, 0, 0, 0, 0 }
newAddon.RefreshPanels()
assert(first.rows[1].data.name == newAddon.panelText.empty and not first.rows[2].shown)
settings.content = "invalid"
newAddon.RefreshPanels()
assert(settings.content == "preview")
settings.content = "custom"
local persistedAddon = { LibEditMode = LEM }
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "QuestContent.lua", "TrackerContent.lua", "DelveRatings.lua", "DelveContent.lua", "ProgressContent.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
    assert(loadfile(file))("FunelQOL", persistedAddon)
end
local persistedCore = frames[#frames]
persistedCore.scripts.OnEvent(persistedCore, "ADDON_LOADED", "FunelQOL")
persistedCore.scripts.OnEvent(persistedCore, "PLAYER_LOGIN")
assert(persistedAddon.panels[1].rows[1].data.name == "Notes" and persistedAddon.panels[1].rows[2].data.name == "Bank")
assert(persistedAddon.panels[2].rows[1].data.name == "Aperçu 1")
print("PASS: live currencies, seasonal caps, money events, sparse professions, selected talents, custom rows, native editor selection/reorder/remove/reuse, manual IDs, layout isolation and deep copies.")
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
    local plain = (self.text or ""):gsub("|T([^|]+)|t", function(tag)
        local height, width = tag:match("^[^:]+:(%d+):(%d+)")
        textureWidth = textureWidth + (tonumber(width) ~= 0 and tonumber(width) or self.fontSize or 14)
        return ""
    end)
    return #plain * (self.fontSize or 11) * 0.55 + textureWidth
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
                assert(row.icon.shown and row.icon.point[1] == "RIGHT" and row.width < first.width)
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

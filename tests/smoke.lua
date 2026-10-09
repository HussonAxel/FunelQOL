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
function methods:SetTexture(texture) self.texture = texture; return true end
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
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "QuestContent.lua", "TrackerContent.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
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
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "QuestContent.lua", "TrackerContent.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
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
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Content.lua", "QuestContent.lua", "TrackerContent.lua", "ContentEditor.lua", "Panels.lua", "Core.lua" }) do
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
                assert(row.label.width + naturalWidth + 40 <= first.width + 1, "Money overlaps its label")
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
            assert(row.background.shown and row.trackerLine.shown)
        elseif row.data.isQuestHeader then
            assert(not row.background.shown and row.icon.shown and row.meta.shown)
            assert(row.meta.text:find("|cff4da6e6", 1, true), "Zone lacks its blue text hierarchy")
            assert(row.label.point[2] == row.meta.point[2] and row.label.point[2] >= 35)
            if row.data.questID then questCount = questCount + 1 else eventCount = eventCount + 1 end
        end
    end
end
assert(sectionKeys.campaign and sectionKeys.quests and sectionKeys.world and sectionKeys.events)
assert(questCount == 14 and eventCount == 2, "Quest lost or inactive/duplicate/locked event shown")
assert(first.background.shown and first.border.shown and not first.header.border.shown)
assert(first.title.text == persistedAddon.panelText.trackerTitle)
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
    assert(first.border.shown and not first.questGroups[1].shown)
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
assert(not first.background.shown and first.rows[1].border.shown)
for _, row in ipairs(first.rows) do
    if row.shown then
        assert(not row.trackerLine or not row.trackerLine.shown)
        assert(not row.trackerAccent or not row.trackerAccent.shown)
    end
end
print("PASS: continuous tracker surface, campaign/quest/world/event sections, blue zones, quest icons and completion hierarchy, live deduplicated map events, map click guards, folding/edit guards, saved layout isolation, all themes and renderer switching.")

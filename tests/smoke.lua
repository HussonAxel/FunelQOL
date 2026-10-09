-- Minimal stateful WoW mock. The actual Blizzard UI still needs in-game testing.
local frames, messages = {}, {}
local methods = {}
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetPoint(...) self.point = { ... } end
function methods:ClearAllPoints() self.point = nil end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:SetScale(scale) self.scale = scale end
function methods:SetFrameLevel(level) self.level = level end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetShown(shown) self.shown = shown end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:SetTexture(texture) self.texture = texture; return true end
function methods:SetText(text) self.text = text end
function methods:SetFont(font, size) self.font, self.fontSize = font, size end
function methods:GetStringWidth() return #(self.text or "") * 6 end
function methods:SetBackdrop(backdrop) self.backdrop = backdrop end
function methods:SetStatusBarTexture(texture) self.texture = texture end
function methods:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
function methods:SetValue(value) self.value = value end
for _, name in ipairs({ "SetAllPoints", "SetClampedToScreen", "SetFrameStrata", "SetBackdropColor", "SetBackdropBorderColor", "SetStatusBarColor", "SetTexCoord", "SetJustifyH", "SetWordWrap", "SetTextColor" }) do
    methods[name] = function() end
end
function CreateFrame(kind, name, parent)
    local frame = setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, events = {}, shown = true }, { __index = methods })
    frames[#frames + 1] = frame
    return frame
end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
function methods:CreateFontString() return CreateFrame("FontString", nil, self) end
UIParent = CreateFrame("Frame")
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
function LEM:GetActiveLayoutName() return self.active end
function LEM:AddFrame(frame, callback) self.positions[frame] = callback end
function LEM:AddFrameSettings(frame, settings) self.settings[frame] = settings end
local addon = { LibEditMode = LEM }
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Panels.lua", "Core.lua" }) do
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
assert(not first.shown and first.width == 320 and first.point[1] == "CENTER" and first.point[4] == 42)
LEM.callbacks.create("Copied", 3, "Modern")
assert(FunelQOLCharDB.layouts.Copied.panel1.width == 320)
assert(FunelQOLCharDB.layouts.Copied.panel1 ~= FunelQOLCharDB.layouts.Modern.panel1)
LEM.callbacks.rename("Copied", "Renamed")
assert(FunelQOLCharDB.layouts.Copied == nil and FunelQOLCharDB.layouts.Renamed.panel1.width == 320)
LEM.callbacks.delete("Renamed")
assert(FunelQOLCharDB.layouts.Renamed == nil)

first.header.scripts.OnClick()
assert(not first.content.shown and first.height == 26)
first.header.scripts.OnClick()
assert(first.content.shown)
LEM.callbacks.enter()
first.header.scripts.OnClick()
assert(first.content.shown)
LEM.callbacks.exit()
SetSetting(first, "rowCount", 8)
SetSetting(first, "rowHeight", 30)
SetSetting(first, "fontSize", 16)
assert(#first.rows == 8 and first.rows[8].shown and first.rows[1].height == 30 and first.rows[1].label.fontSize == 16)
SetSetting(first, "rowCount", 1)
assert(first.rows[1].shown and not first.rows[2].shown)
SetSetting(first, "showBars", false)
assert(not first.rows[1].bar.shown)
SetSetting(first, "style", "ayije")
assert(first.header.backdrop.edgeFile == addon.media.ayije.borders.Ayije_Thin.edgeFile)
SetSetting(first, "style", "pixels")
assert(first.header.backdrop.edgeFile == addon.media.borders.pixels.edgeFile)
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
for _, file in ipairs({ "Media.lua", "PanelPreview.lua", "Panels.lua", "Core.lua" }) do
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
print("PASS: initialization, preview controls, independent titles, collapse, visibility, layout switching/copy/rename/delete, and combat guard.")

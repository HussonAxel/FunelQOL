local _, addon = ...
local fr = GetLocale()=="frFR"
local template = "FunelQOLRareMapPinTemplate"
local provider, queued, mapLoader
local events = { "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "PLAYER_ENTERING_WORLD" }

local function Config()
    addon.db.rareMapPins = addon.db.rareMapPins or {}
    local config = addon.db.rareMapPins
    local defaults = { enabled=true, labels=true, showKilled=true, iconScale=1, fontSize=12 }
    for key,value in pairs(defaults) do
        if type(config[key])~=type(value) then config[key]=value end
    end
    return config
end

FunelQOLRareMapPinMixin = CreateFromMixins(MapCanvasPinMixin)
function FunelQOLRareMapPinMixin:OnLoad()
    self:SetScalingLimits(1,1,1.2)
    self:UseFrameLevelType("PIN_FRAME_LEVEL_VIGNETTE")
    self.Icon = self:CreateTexture(nil,"ARTWORK")
    self.Icon:SetAllPoints()
    self.Icon:SetAtlas("VignetteKillElite")
    self.Label = self:CreateFontString(nil,"OVERLAY")
    self.Label:SetPoint("BOTTOM",self,"TOP",0,8)
    self.Label:SetWidth(180)
    self.Label:SetJustifyH("CENTER")
    self.Label:SetWordWrap(true)
    self.Label:SetMaxLines(2)
end
function FunelQOLRareMapPinMixin:OnAcquired(entry,dataProvider)
    self.entry = entry
    self:SetDataProvider(dataProvider)
    local config = Config()
    local size = 24*math.max(.8,math.min(1.4,config.iconScale))
    self:SetSize(size,size)
    self.Icon:SetDesaturated(entry.killed==true)
    self.Icon:SetAlpha(entry.killed and .55 or 1)
    local refine = _G.RefineUI
    local font = refine and refine.Media and refine.Media.Fonts and refine.Media.Fonts.Default or addon.media.refine.font
    addon.SetFont(self.Label,math.max(10,math.min(16,config.fontSize)),"OUTLINE",font)
    self.Label:SetText(entry.rareName or tostring(entry.rareNpcID))
    self.Label:SetTextColor(1,entry.killed and 1 or .82,entry.killed and 1 or .2,entry.killed and .65 or 1)
    self.Label:SetShown(config.labels)
    self:SetPosition(entry.rareX,entry.rareY)
end
function FunelQOLRareMapPinMixin:ShouldMouseButtonBePassthrough() return false end
function FunelQOLRareMapPinMixin:GetDisplayName() return self.entry and self.entry.rareName or "Rares" end
function FunelQOLRareMapPinMixin:OnMouseClickAction(button)
    if self.entry and (button=="LeftButton" or button=="RightButton") then addon.SetRareWaypoint(self.entry) end
end
function FunelQOLRareMapPinMixin:OnMouseEnter()
    local entry = self.entry
    if not entry then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(entry.rareName or tostring(entry.rareNpcID))
    GameTooltip:AddLine(("%.1f, %.1f"):format(entry.rareX*100,entry.rareY*100),1,1,1)
    local status = entry.killed and (entry.daily and (fr and "Vaincu aujourd’hui" or "Defeated today") or (fr and "Déjà vaincu" or "Already defeated"))
        or entry.killed==false and (fr and "Pas encore vaincu" or "Not defeated yet") or (fr and "Statut de mort inconnu" or "Kill status unknown")
    GameTooltip:AddLine(status,.8,.8,.8)
    GameTooltip:AddLine(fr and "Emplacement connu · présence non vérifiée" or "Known location · presence not verified",.7,.7,.7)
    GameTooltip:AddLine(fr and "Clic : point de passage" or "Click: waypoint",1,1,1)
    GameTooltip:Show()
end
function FunelQOLRareMapPinMixin:OnMouseLeave() GameTooltip:Hide() end
function FunelQOLRareMapPinMixin:OnReleased()
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    self.entry=nil
    self:SetDataProvider(nil)
    MapCanvasPinMixin.OnReleased(self)
end

local Provider = CreateFromMixins(MapCanvasDataProviderMixin)
function Provider:SetWatching(on)
    for _,event in ipairs(events) do
        if on then self:RegisterEvent(event) else self:UnregisterEvent(event) end
    end
end
function Provider:RemoveAllData() self:GetMap():RemoveAllPinsByTemplate(template) end
function Provider:RefreshAllData()
    local map = self:GetMap()
    if not map or not map:IsShown() then return end
    local config = Config()
    self:SetWatching(config.enabled)
    self:RemoveAllData()
    if not config.enabled then return end
    for _,entry in ipairs(addon.GetRareMapEntries(map:GetMapID())) do
        if config.showKilled or not entry.killed then map:AcquirePin(template,entry,self) end
    end
end
local function QueueRefresh()
    if queued or not provider or not provider:GetMap():IsShown() then return end
    queued=true
    C_Timer.After(0,function()
        queued=nil
        if provider then provider:RefreshAllData() end
    end)
end
function Provider:OnShow()
    self:SetWatching(Config().enabled)
end
function Provider:OnHide()
    self:SetWatching(false)
    self:RemoveAllData()
end
function Provider:OnEvent() QueueRefresh() end

function addon.InitializeRareMapPins()
    if provider or not addon.db then return end
    if not WorldMapFrame then
        if not mapLoader then
            mapLoader=CreateFrame("Frame")
            mapLoader:RegisterEvent("ADDON_LOADED")
            mapLoader:SetScript("OnEvent",function(self)
                if WorldMapFrame then
                    self:UnregisterEvent("ADDON_LOADED")
                    addon.InitializeRareMapPins()
                end
            end)
        end
        return
    end
    provider=CreateFromMixins(Provider)
    addon.rareMapProvider=provider
    WorldMapFrame:SetPinTemplateType(template,"Button")
    WorldMapFrame:AddDataProvider(provider)
    if Menu and Menu.ModifyMenu then
        Menu.ModifyMenu("MENU_QUEST_MAP_FRAME_SETTINGS",function(_,root)
            root:CreateDivider()
            local menu=root:CreateButton("FunelQOL · Rares")
            for _,entry in ipairs({ {"enabled",fr and "Afficher les rares" or "Show rares"},
                {"labels",fr and "Afficher les noms" or "Show names"},
                {"showKilled",fr and "Afficher les rares déjà vaincus" or "Show defeated rares"} }) do
                local key=entry[1]
                menu:CreateCheckbox(entry[2],function() return Config()[key] end,function()
                    Config()[key]=not Config()[key]; QueueRefresh()
                end)
            end
            local sizes=menu:CreateButton(fr and "Taille des icônes" or "Icon size")
            for _,value in ipairs({.8,1,1.2,1.4}) do
                sizes:CreateRadio(("%d%%"):format(value*100),function() return Config().iconScale==value end,
                    function() Config().iconScale=value; QueueRefresh() end)
            end
            local fonts=menu:CreateButton(fr and "Taille des noms" or "Name size")
            for _,value in ipairs({10,12,14,16}) do
                fonts:CreateRadio(tostring(value),function() return Config().fontSize==value end,
                    function() Config().fontSize=value; QueueRefresh() end)
            end
        end)
    end
end

local timers, created, loads, reads, menuBuilder = {}, 0, 0, 0
local now, secretTooltip = 0, true
local secretName="Protected rare name"
function GetTime() return now end
function issecretvalue(value) return rawequal(value,secretName) end
function GetLocale() return "frFR" end
function UnitFactionGroup() return "Alliance" end
function CreateFromMixins(...)
    local value={}
    for i=1,select("#",...) do for k,v in pairs(select(i,...)) do value[k]=v end end
    return value
end
C_QuestLog={IsQuestFlaggedCompleted=function(id) return id==11 end}
C_Item={GetItemInfoInstant=function() error("Opening a rare map classified loot") end}
C_TooltipInfo={GetHyperlink=function(link)
    if link:find("%-1%-0000000000") then return {lines={{leftText=secretTooltip and secretName or "Rare localisé"}}} end
end}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
local addon={db={},panelText={},media={refine={font="RefineUI-Demi"}}}
addon.LoadRareData=function()
    loads=loads+1
    return {zones={ [2410]={ [1]={2500,7500},[2]={5000,6000},[3]={100,200},[4]={3000,4000},[5]={10001,100} },
        [2405]={ [1]={2000,3000} } }, npcs={
        [1]={n="English fallback",q={11},r=true,l={1}},[2]={n="Pas vaincu",q={12}},
        [3]={n="Inconnu"},[4]={n="Allié",f="A"},[5]={n="Invalide"} } }
end
assert(loadfile("RareContent.lua"))("FunelQOL",addon)
local entries=addon.GetRareMapEntries(2410)
assert(#entries==3 and loads==1,"Invalid coordinates or friendly rares reached the map")
for _,entry in ipairs(entries) do
    if entry.rareNpcID==1 then assert(entry.rareName=="English fallback","Protected tooltip name escaped into map entries or the name cache") end
end
secretTooltip=false
now=4
for _,entry in ipairs(addon.GetRareMapEntries(2410)) do
    if entry.rareNpcID==1 then assert(entry.rareName=="English fallback","Protected name bypassed the retry throttle") end
end
now=5; entries=addon.GetRareMapEntries(2410)
local byID={}; for _,e in ipairs(entries) do byID[e.rareNpcID]=e end
assert(byID[1].rareMapID==2410 and byID[1].rareX==.25 and byID[1].rareY==.75)
assert(byID[1].rareName=="Rare localisé" and byID[1].killed and byID[1].daily)
assert(byID[2].killed==false and byID[3].killed==nil)
assert(#addon.GetRareMapEntries(999)==0 and #addon.GetRareMapEntries(2405)==1 and loads==1)
local getter=addon.GetRareMapEntries
addon.GetRareMapEntries=function(id) reads=reads+1; return getter(id) end

local methods={}
function methods:SetAllPoints() end
function methods:SetAtlas(value) self.atlas=value end
function methods:SetAlpha(value) self.alpha=value end
function methods:SetDesaturated(value) self.desaturated=value end
function methods:SetPoint(...) self.point={...} end
function methods:SetWidth(value) self.width=value end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetJustifyH() end
function methods:SetWordWrap() end
function methods:SetMaxLines() end
function methods:SetText(value) assert(self.font,"Font not initialized"); self.text=value end
function methods:SetTextColor(...) self.color={...} end
function methods:SetShown(value) self.shown=value end
function methods:CreateTexture() return setmetatable({}, {__index=methods}) end
function methods:CreateFontString() return setmetatable({}, {__index=methods}) end
function addon.SetFont(object,size,flags,font) object.font,object.fontSize,object.flags=font,size,flags end
MapCanvasPinMixin={}
function MapCanvasPinMixin:SetPosition(x,y) self.x,self.y=x,y end
function MapCanvasPinMixin:SetDataProvider(value) self.dataProvider=value end
function MapCanvasPinMixin:SetScalingLimits(...) self.scaling={...} end
function MapCanvasPinMixin:UseFrameLevelType(value) self.levelType=value end
function MapCanvasPinMixin:OnReleased() self.released=true end
MapCanvasDataProviderMixin={}
function MapCanvasDataProviderMixin:GetMap() return self.map end
function MapCanvasDataProviderMixin:OnAdded(map) self.map=map; self.events={} end
function MapCanvasDataProviderMixin:RegisterEvent(event) self.events[event]=true end
function MapCanvasDataProviderMixin:UnregisterEvent(event) self.events[event]=nil end
function MapCanvasDataProviderMixin:OnMapChanged() self:RefreshAllData() end
WorldMapFrame={shown=false,mapID=2410,pins={},pool={}}
function WorldMapFrame:IsShown() return self.shown end
function WorldMapFrame:GetMapID() return self.mapID end
function WorldMapFrame:SetPinTemplateType(template,kind) assert(kind=="Button"); self.template=template end
function WorldMapFrame:AddDataProvider(provider)
    assert(not self.provider,"Rare provider registered twice")
    self.provider=provider; provider:OnAdded(self)
end
function WorldMapFrame:RemoveAllPinsByTemplate(template)
    assert(template==self.template)
    for _,pin in ipairs(self.pins) do pin:OnReleased(); self.pool[#self.pool+1]=pin end
    self.pins={}
end
function WorldMapFrame:AcquirePin(template,entry,provider)
    assert(template==self.template)
    local pin=table.remove(self.pool)
    if not pin then
        created=created+1; pin=CreateFromMixins(methods,FunelQOLRareMapPinMixin); pin:OnLoad()
    end
    pin:OnAcquired(entry,provider); self.pins[#self.pins+1]=pin; return pin
end
GameTooltip={}
function GameTooltip:IsOwned(pin) return self.owner==pin end
function GameTooltip:Hide() self.owner=nil end
function GameTooltip:SetOwner(pin) self.owner=pin; self.lines={} end
function GameTooltip:SetText(text) self.title=text end
function GameTooltip:AddLine(text) self.lines[#self.lines+1]=text end
function GameTooltip:Show() end
Menu={ModifyMenu=function(tag,fn) assert(tag=="MENU_QUEST_MAP_FRAME_SETTINGS"); menuBuilder=fn end}
local waypoint
function addon.SetRareWaypoint(entry) waypoint=entry end
assert(loadfile("RareMapPins.lua"))("FunelQOL",addon)
local waiting, waitingCreated
function CreateFrame()
    assert(not waitingCreated,"Multiple map load watchers created")
    waitingCreated=true
    waiting={events={},RegisterEvent=MapCanvasDataProviderMixin.RegisterEvent,UnregisterEvent=MapCanvasDataProviderMixin.UnregisterEvent,
        SetScript=function(self,_,fn) self.callback=fn end}
    return waiting
end
local map=WorldMapFrame; WorldMapFrame=nil
addon.InitializeRareMapPins(); addon.InitializeRareMapPins()
assert(waiting.events.ADDON_LOADED and not addon.rareMapProvider)
WorldMapFrame=map; waiting.callback(waiting,"ADDON_LOADED")
assert(not waiting.events.ADDON_LOADED)
addon.InitializeRareMapPins(); addon.InitializeRareMapPins()
local provider=addon.rareMapProvider
provider:RefreshAllData(); assert(reads==0 and created==0,"Closed map loaded rare data")
WorldMapFrame.shown=true; provider:OnShow(); provider:RefreshAllData()
assert(#WorldMapFrame.pins==3 and created==3 and provider.events.QUEST_LOG_UPDATE)
local killed
for _,pin in ipairs(WorldMapFrame.pins) do if pin.entry.rareNpcID==1 then killed=pin end end
assert(killed.x==.25 and killed.y==.75 and killed.Icon.desaturated and killed.Icon.atlas=="VignetteKillElite")
assert(killed.Label.font=="RefineUI-Demi" and killed.Label.flags=="OUTLINE" and killed.Label.shown)
assert(killed.Label.point[1]=="BOTTOM" and killed.Label.point[3]=="TOP" and not killed.RefineBorder)
killed:OnMouseEnter(); assert(GameTooltip.title=="Rare localisé" and GameTooltip.lines[2]:find("aujourd"))
killed:OnMouseClickAction("RightButton"); assert(waypoint.rareNpcID==1 and waypoint.rareMapID==2410)
assert(not killed:ShouldMouseButtonBePassthrough("RightButton"))
local before=reads
for _=1,20 do provider:OnEvent("QUEST_LOG_UPDATE") end
assert(#timers==1 and reads==before,"Quest event burst caused repeated map scans")
table.remove(timers)(); assert(reads==before+1 and created==3,"Pins were not pooled")
local config=addon.db.rareMapPins
RefineUI={Media={Fonts={Default="LiveRefineFont"}}}
config.showKilled=false; config.labels=false; config.iconScale=1.4; config.fontSize=16
provider:RefreshAllData(); assert(#WorldMapFrame.pins==2)
for _,pin in ipairs(WorldMapFrame.pins) do
    assert(pin.width==24*1.4 and not pin.Label.shown and pin.Label.fontSize==16 and pin.Label.font=="LiveRefineFont")
end
WorldMapFrame.mapID=2405; provider:OnMapChanged(); assert(#WorldMapFrame.pins==0,"Killed rare escaped the filter on a different map")
config.showKilled=true; provider:RefreshAllData(); assert(#WorldMapFrame.pins==1 and WorldMapFrame.pins[1].x==.2)
WorldMapFrame.mapID=999; provider:OnMapChanged(); assert(#WorldMapFrame.pins==0)
WorldMapFrame.mapID=2410; config.enabled=false; before=reads; provider:RefreshAllData()
assert(reads==before and not next(provider.events) and #WorldMapFrame.pins==0)
config.enabled=true; provider:RefreshAllData(); provider:OnEvent("QUEST_LOG_UPDATE")
WorldMapFrame.shown=false; provider:OnHide(); before=reads
table.remove(timers)(); assert(reads==before and not next(provider.events) and #WorldMapFrame.pins==0)
provider:OnEvent("QUEST_LOG_UPDATE"); assert(#timers==0)
local menu={toggles={},children={}}
function menu:CreateDivider() end
function menu:CreateButton(name) local child=setmetatable({toggles={},children={},name=name},{__index=self}); self.children[#self.children+1]=child; return child end
function menu:CreateCheckbox(name,get,set) self.toggles[#self.toggles+1]={name=name,get=get,set=set} end
function menu:CreateRadio() end
menuBuilder(nil,menu); assert(#menu.children[1].toggles==3)
print("PASS: shared rare database, viewed-zone coordinates, localized names, faction and kill filters, no loot loads, pooled borderless RefineUI labels, waypoints, menu, coalesced events and no closed-map work.")

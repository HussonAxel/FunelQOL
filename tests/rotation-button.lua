local frames, target, combat, available, nextSpell, scans = {}, false, false, true, nil, 0
local secret={}
local unloaded, textures, loadRequests = {}, {}, 0
local now, cooldowns, hooks = 100, {}, {}
function GetTime() return now end
function UseAction() end
function CastSpellByID() end
function CastSpellByName() end
function hooksecurefunc(name, callback) hooks[name] = callback end
ERR_SPELL_COOLDOWN = "Ce sort n'est pas encore prêt."
function issecretvalue(value) return value==secret end
function GetLocale() return "frFR" end
function UnitExists() return target end
function InCombatLockdown() return combat end
local methods={}
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetPoint(...) self.point={...} end
function methods:ClearAllPoints() self.point=nil end
function methods:SetText(text)
    assert(not self.isFontString or self.font,"Font not set: SetText called before the FontString font was initialized")
    self.text=text
end
function methods:SetTexture(value) self.texture=value end
function methods:SetShown(value) self.shown=value end
function methods:IsShown() return self.shown end
function methods:SetBackdrop() end
function methods:SetBackdropColor() end
function methods:SetFrameStrata() end
function methods:SetTexCoord() end
function methods:SetTextColor() end
function methods:SetAllPoints() end
function methods:SetHideCountdownNumbers(value) self.hideNumbers=value end
function methods:SetDrawEdge() end
function methods:Clear() self.duration=nil end
function methods:SetCooldownFromDurationObject(value) self.duration=value end
function methods:EnableMouse() end
function methods:SetFrameLevel(level) self.level=level end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
function CreateFrame(_,name) local f=setmetatable({name=name,scripts={},events={},shown=true},{__index=methods}); frames[#frames+1]=f; return f end
function methods:CreateTexture() return setmetatable({}, {__index=methods}) end
function methods:CreateFontString() return setmetatable({isFontString=true}, {__index=methods}) end
UIParent=CreateFrame("Frame")
local keys={ACTIONBUTTON1="SHIFT-Q",MULTIACTIONBAR1BUTTON1="E"}
function GetBindingKey(command) return keys[command] end
function GetBindingText(key) return key end
function GetActionInfo(slot) scans=scans+1; if slot==1 then return "spell",100 elseif slot==13 then return "macro",1 end end
function GetMacroSpell() return 200 end
ActionButton1={action=1,IsShown=function() return true end}
MultiBarBottomLeftButton1={action=13,IsShown=function() return true end}
C_Spell={GetBaseSpell=function(id) return id==101 and 100 or id end,
    GetSpellCooldown=function(id) return cooldowns[id] or {isActive=false,isOnGCD=false} end,
    GetSpellCooldownDuration=function(id,ignoreGCD) assert(ignoreGCD); return cooldowns[id] and cooldowns[id].object end,
    GetOverrideSpell=function(id) return id==100 and 101 or id end,
    GetSpellTexture=function(id) if unloaded[id] then return nil end; return textures[id] or "icon"..id end,
    RequestLoadSpellData=function() loadRequests=loadRequests+1 end}
C_AssistedCombat={IsAvailable=function() return available end,GetNextCastSpell=function() return nextSpell end}
function CopyTable(value) local r={}; for k,v in pairs(value) do r[k]=type(v)=="table" and CopyTable(v) or v end; return r end
local lem={active="Common",callbacks={},SettingType={Checkbox=1,Slider=2}}
function lem:GetActiveLayoutName() return self.active end
function lem:AddFrame(frame, callback) self.position=callback end
function lem:AddFrameSettings(frame, settings) self.settings=settings end
function lem:RegisterCallback(event,fn) self.callbacks[event]=fn end
local addon={db={},LibEditMode=lem,media={font="Bold",borders={pixels={edgeFile="Pixels"}},refine={border="RefineBorder",boldFont="RefineBold"}}}
function addon.SetFont(object,size,flags,font) object.font,object.fontSize=font,size end
assert(loadfile("RotationButton.lua"))("FunelQOL",addon)
addon.InitializeRotationButton()
local button,driver=addon.rotationButton,frames[#frames]
assert(button.hotkey.font=="RefineBold","Keybind does not use RefineUI's bold font")
assert(button.border.borderColor[1]==.6,"RefineUI border colour missing")
GameTooltip=GameTooltip or {SetOwner=function() end,SetText=function() end,SetSpellByID=function() end,AddLine=function() end,Show=function() end,Hide=function() end}
button.scripts.OnEnter(button); assert(button.border.borderColor[2]==.82,"Hover does not use RefineUI's gold border")
button.scripts.OnLeave(button); assert(button.border.borderColor[1]==.6)
assert(not button.shown and not driver.scripts.OnUpdate,"Idle polling without a target")
assert(addon.GetRotationButtonStatus():find("visible=false"),"Initialization did not reach the recommendation driver")
lem.callbacks.enter(); assert(button.shown and button.icon.texture:find("QuestionMark"))
lem.callbacks.exit()
target=true; nextSpell=101; driver.scripts.OnEvent(driver,"PLAYER_TARGET_CHANGED")
assert(button.shown and button.icon.texture=="icon101" and button.hotkey.text=="S-Q")
local oldScans=scans
nextSpell=200; driver.scripts.OnUpdate(driver,.1)
assert(button.hotkey.text=="E" and button.icon.texture=="icon200" and scans==oldScans,"Bindings rescanned on each suggestion")
keys.MULTIACTIONBAR1BUTTON1="CTRL-E"; driver.scripts.OnEvent(driver,"UPDATE_BINDINGS")
assert(button.hotkey.text=="C-E" and scans>oldScans)
nextSpell=300; driver.scripts.OnUpdate(driver,.1); assert(button.hotkey.text=="—")
local missingScans, previousRequests=scans,loadRequests
unloaded[400]=true; nextSpell=400; driver.scripts.OnUpdate(driver,.1)
local requested=loadRequests
assert(requested==previousRequests+1,"Missing spell data was not requested")
driver.scripts.OnUpdate(driver,.1)
assert(loadRequests==requested and scans==missingScans,"Missing textures caused repeated requests or binding rescans")
unloaded[400]=nil; driver.scripts.OnUpdate(driver,.1)
assert(button.icon.texture=="icon400","Missing spell texture stayed cached after data became available")
textures[500]=134400; nextSpell=500; driver.scripts.OnUpdate(driver,.1)
assert(button.icon.texture:find("QuestionMark"))
textures[500]=nil; driver.scripts.OnEvent(driver,"SPELL_DATA_LOAD_RESULT",500,true)
assert(button.icon.texture=="icon500","Spell-load event did not refresh a placeholder icon")
assert(addon.GetRotationButtonStatus():find("sort=500") and addon.GetRotationButtonStatus():find("icône=icon500"))
nextSpell=secret; driver.scripts.OnUpdate(driver,.1); assert(not button.shown)
assert(addon.GetRotationButtonStatus():find("recommandation protégée"))
available=false; driver.scripts.OnEvent(driver,"SPELLS_CHANGED"); assert(not driver.scripts.OnUpdate)
available=true; nextSpell=101; driver.scripts.OnEvent(driver,"SPELLS_CHANGED")
lem.callbacks.create("Copied",nil,"Common")
lem.callbacks.layout("Copied"); lem.settings[2].set("Copied",64); assert(button.width==64)
lem.callbacks.layout("Common"); assert(button.width==48)
addon.ToggleRotationButton(); assert(not button.shown and not driver.scripts.OnUpdate)
lem.callbacks.enter(); assert(button.shown); lem.callbacks.exit()
assert(not button.scripts.OnClick,"Recommendation button unexpectedly casts spells")
local timers={}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
target=true; addon.ToggleRotationButton()
local burstScans=scans
for _=1,50 do driver.scripts.OnEvent(driver,"ACTIONBAR_SLOT_CHANGED") end
assert(#timers==1 and scans==burstScans,"Action bar slot bursts rescanned bindings synchronously")
timers[1](); assert(scans>burstScans,"Deferred binding rescan did not run")
C_Timer=nil
local alert=addon.rotationCooldownAlert
assert(not alert.shown and not alert.scripts.OnUpdate, "Idle cooldown alert polls")
assert(alert.point[2]==button and alert.width==48, "Alert does not follow the rotation button")
local duration={remaining=secret}
cooldowns[101]={isActive=true,isOnGCD=false,startTime=secret,duration=secret,object=duration}
driver.scripts.OnEvent(driver,"UNIT_SPELLCAST_FAILED","party1","cast",101)
assert(not alert.shown,"Another player's failed cast triggered the alert")
driver.scripts.OnEvent(driver,"UNIT_SPELLCAST_FAILED","player","cast",secret)
assert(not alert.shown,"Secret spell ID triggered the alert")
driver.scripts.OnEvent(driver,"UNIT_SPELLCAST_FAILED","player","cast",100)
assert(alert.shown and alert.icon.texture=="icon101" and alert.cooldown.duration==duration)
assert(alert.label.text=="CD" and alert.cooldown.hideNumbers==false)
target=false; nextSpell=nil; driver.scripts.OnEvent(driver,"PLAYER_TARGET_CHANGED")
assert(not button.shown and alert.shown and not driver.scripts.OnUpdate,"Cooldown requires a target/recommendation")
cooldowns[101].isActive=false
driver.scripts.OnEvent(driver,"SPELL_UPDATE_COOLDOWN")
assert(alert.label.text=="Prêt" and alert.cooldown.duration==nil)
now=101; alert.scripts.OnUpdate(alert,.1); assert(alert.shown)
now=102; alert.scripts.OnUpdate(alert,.1)
assert(not alert.shown and not alert.scripts.OnUpdate,"Ready notice did not expire")
cooldowns[200]={isActive=true,isOnGCD=true,object=duration}
driver.scripts.OnEvent(driver,"UNIT_SPELLCAST_FAILED_QUIET","player","cast",200)
assert(not alert.shown,"Global cooldown triggered an alert")
cooldowns[200].isOnGCD=false
driver.scripts.OnEvent(driver,"UNIT_SPELLCAST_FAILED_QUIET","player","cast",200)
assert(alert.spellID==200 and alert.icon.texture=="icon200")
addon.ToggleRotationButton(); assert(not alert.shown and not alert.scripts.OnUpdate)
driver.scripts.OnEvent(driver,"UNIT_SPELLCAST_FAILED","player","cast",200)
assert(not alert.shown,"Disabled rotation still triggers alerts")
addon.ToggleRotationButton()
timers={}; C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
-- UI errors can arrive before the secure UseAction post-hook.
driver.scripts.OnEvent(driver,"UI_ERROR_MESSAGE",1,ERR_SPELL_COOLDOWN)
hooks.UseAction(13); timers[1]()
assert(alert.spellID==200,"Macro action cooldown error was not detected")
C_Timer=nil
driver.scripts.OnEvent(driver,"PLAYER_ENTERING_WORLD"); assert(not alert.shown)
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
hooks.UseAction(13); now=103
driver.scripts.OnEvent(driver,"UI_ERROR_MESSAGE",1,ERR_SPELL_COOLDOWN); timers[2]()
assert(not alert.shown,"Old action was reused for a later error")
driver.scripts.OnEvent(driver,"UI_ERROR_MESSAGE",1,"Hors de portée")
assert(#timers==2,"Unrelated errors scheduled cooldown alerts")
cooldowns[200].isActive=secret
driver.scripts.OnEvent(driver,"UNIT_SPELLCAST_FAILED","player","cast",200)
assert(not alert.shown,"Secret cooldown flags were inspected")
print("PASS: cooldown attempts, macros, secret duration objects, GCD filtering, target independence, ready notice, expiry and disable guards.")
print("PASS: Blizzard recommendations, override/base spell bindings, macros, missing bindings, caching, secret/unavailable APIs, idle/disable guards and shared Edit Mode layouts.")

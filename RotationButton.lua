local addonName, addon = ...
local LEM = addon.LibEditMode
local fr = GetLocale() == "frFR"
local title = fr and "FunelQOL · Rotation Blizzard" or "FunelQOL · Blizzard rotation"
local button, driver, editing, layoutName, bindings, lastSpell, lastKey, running
local textureReady, lastTexture, recommendationState, initialized, refreshQueued
local questionMark = "Interface\\Icons\\INV_Misc_QuestionMark"
local bars = { { "ActionButton", "ACTIONBUTTON" }, { "MultiBarBottomLeftButton", "MULTIACTIONBAR1BUTTON" },
    { "MultiBarBottomRightButton", "MULTIACTIONBAR2BUTTON" }, { "MultiBarRightButton", "MULTIACTIONBAR3BUTTON" },
    { "MultiBarLeftButton", "MULTIACTIONBAR4BUTTON" }, { "MultiBar5Button", "MULTIACTIONBAR5BUTTON" },
    { "MultiBar6Button", "MULTIACTIONBAR6BUTTON" }, { "MultiBar7Button", "MULTIACTIONBAR7BUTTON" } }
local function Safe(value) return not (issecretvalue and issecretvalue(value)) end
local function RotationFont()
    local refine = _G.RefineUI
    return refine and refine.Media and refine.Media.Fonts and refine.Media.Fonts.Bold or addon.media.refine.boldFont
end
local borderColor, hoverColor = { .6, .6, .6, 1 }, { 1, .82, 0, 1 }
-- Mirrors RefineUI's action button skin: 1-unit icon inset, transparent "Icon"
-- template whose 12-unit RefineBorder reaches 4 units outside the button.
local function CreateRefineBorder(overlay)
    local refine = _G.RefineUI
    if refine and refine.SetTemplate and pcall(refine.SetTemplate, overlay, "Icon") and overlay.border then
        return overlay.border
    end
    local border = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -4, 4); border:SetPoint("BOTTOMRIGHT", 4, -4)
    border:SetBackdrop({ edgeFile = addon.media.refine.border, edgeSize = 12 })
    border:EnableMouse(false)
    return border
end
local function SetBorderColor(color)
    if button.border and button.border.SetBackdropBorderColor then button.border:SetBackdropBorderColor(unpack(color)) end
end
local defaults = { enabled = true, size = 48, fontSize = 12, point = "CENTER", x = 0, y = -130 }
-- Defaults are validated once per layout table; settings only write valid types.
local checked = setmetatable({}, { __mode = "k" })
local function Config(name)
    addon.db.rotation = addon.db.rotation or { layouts = {} }
    addon.db.rotation.layouts = addon.db.rotation.layouts or {}
    local layouts = addon.db.rotation.layouts
    name = name or layoutName or LEM:GetActiveLayoutName()
    layouts[name] = layouts[name] or {}
    local config = layouts[name]
    if not checked[config] then
        for key,value in pairs(defaults) do if type(config[key]) ~= type(value) then config[key] = value end end
        checked[config] = true
    end
    return config
end
local cooldownAlert, attemptedSpell, attemptedAt
local function ClearCooldownAlert()
    if not cooldownAlert then return end
    cooldownAlert.spellID, cooldownAlert.readyAt = nil, nil
    cooldownAlert:SetShown(false)
    cooldownAlert:SetScript("OnUpdate", nil)
    cooldownAlert.cooldown:Clear()
end
local function SpellCooldown(id)
    if not C_Spell.GetSpellCooldown then return end
    local info = C_Spell.GetSpellCooldown(id)
    -- Midnight exposes these flags without exposing cooldown timestamps. Never
    -- do arithmetic on the start/duration: the native widget handles secrets.
    if not info or not Safe(info.isActive) or not Safe(info.isOnGCD) then return end
    return info.isActive == true and info.isOnGCD ~= true
end
local function UpdateCooldownAlert()
    if not Config().enabled then ClearCooldownAlert(); return end
    local id = cooldownAlert.spellID
    if not id then return end
    local active = SpellCooldown(id)
    if active == nil then ClearCooldownAlert(); return end
    if active then
        local duration = C_Spell.GetSpellCooldownDuration and C_Spell.GetSpellCooldownDuration(id, true)
        if not duration then ClearCooldownAlert(); return end
        cooldownAlert.readyAt = nil
        cooldownAlert.cooldown:SetCooldownFromDurationObject(duration)
        cooldownAlert.label:SetText("CD")
        cooldownAlert.label:SetTextColor(1, .65, .2, 1)
    else
        if not cooldownAlert.readyAt then
            cooldownAlert.readyAt = GetTime()
            cooldownAlert.cooldown:Clear()
            cooldownAlert.label:SetText(fr and "Prêt" or "Ready")
            cooldownAlert.label:SetTextColor(.3, 1, .3, 1)
        end
        if GetTime() - cooldownAlert.readyAt >= 2 then ClearCooldownAlert() end
    end
end
local function ShowCooldownAlert(id)
    if not Config().enabled or not Safe(id) or type(id) ~= "number" or id <= 0 then return end
    if C_Spell.GetOverrideSpell then
        local override = C_Spell.GetOverrideSpell(id)
        if Safe(override) and type(override) == "number" and override > 0 then id = override end
    end
    if not SpellCooldown(id) then return end
    cooldownAlert.spellID, cooldownAlert.readyAt = id, nil
    local texture = C_Spell.GetSpellTexture(id)
    cooldownAlert.icon:SetTexture(Safe(texture) and texture or questionMark)
    cooldownAlert:SetShown(true)
    local elapsed = 0
    cooldownAlert:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= .1 then elapsed = 0; UpdateCooldownAlert() end
    end)
    UpdateCooldownAlert()
end
local function RememberSpell(id)
    attemptedSpell, attemptedAt = nil, nil
    if Safe(id) and type(id) == "number" and id > 0 then attemptedSpell, attemptedAt = id, GetTime() end
end
local function InitializeCooldownAlert()
    -- A sibling of the recommendation: remains visible when Blizzard has no
    -- next spell (or the target disappears), while following the same anchor.
    cooldownAlert = CreateFrame("Frame", addonName .. "RotationCooldownAlert", UIParent)
    addon.rotationCooldownAlert = cooldownAlert
    cooldownAlert:SetFrameStrata("MEDIUM")
    cooldownAlert:EnableMouse(false)
    cooldownAlert:SetPoint("LEFT", button, "RIGHT", 12, 0)
    cooldownAlert.icon = cooldownAlert:CreateTexture(nil, "ARTWORK")
    cooldownAlert.icon:SetPoint("TOPLEFT", 1, -1); cooldownAlert.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    cooldownAlert.icon:SetTexCoord(.08, .92, .08, .92)
    cooldownAlert.cooldown = CreateFrame("Cooldown", nil, cooldownAlert, "CooldownFrameTemplate")
    cooldownAlert.cooldown:SetAllPoints(cooldownAlert.icon)
    cooldownAlert.cooldown:SetHideCountdownNumbers(false)
    cooldownAlert.cooldown:SetDrawEdge(false)
    cooldownAlert.cooldown:EnableMouse(false)
    local overlay = CreateFrame("Frame", nil, cooldownAlert)
    overlay:SetAllPoints(cooldownAlert); overlay:SetFrameLevel(cooldownAlert.cooldown:GetFrameLevel() + 2)
    overlay:EnableMouse(false)
    local border = CreateRefineBorder(overlay)
    border:SetBackdropBorderColor(unpack(borderColor))
    cooldownAlert.label = overlay:CreateFontString(nil, "OVERLAY")
    cooldownAlert.label:SetPoint("TOP", cooldownAlert, "BOTTOM", 0, -5)
    addon.SetFont(cooldownAlert.label, Config().fontSize, "OUTLINE", RotationFont())
    ClearCooldownAlert()
    -- Failed-cast events supply the actual spell, including macro casts. Some
    -- action attempts only emit UI_ERROR_MESSAGE; remember their action slot
    -- via a secure post-hook, then resolve the error on the following frame.
    if hooksecurefunc then
        if UseAction then hooksecurefunc("UseAction", function(slot)
            RememberSpell(nil)
            if not Safe(slot) or type(slot) ~= "number" then return end
            local kind, id = GetActionInfo(slot)
            if Safe(kind) and Safe(id) then
                RememberSpell(kind == "spell" and id or kind == "macro" and GetMacroSpell and GetMacroSpell(id))
            end
        end) end
        if CastSpellByID then hooksecurefunc("CastSpellByID", RememberSpell) end
        if CastSpellByName then hooksecurefunc("CastSpellByName", function(name)
            RememberSpell(nil)
            if not Safe(name) or type(name) ~= "string" or not C_Spell.GetSpellInfo then return end
            local info = C_Spell.GetSpellInfo(name)
            if info then RememberSpell(info.spellID) end
        end) end
    end
end
local function BaseSpell(id)
    if not Safe(id) or type(id) ~= "number" or id <= 0 then return end
    if C_Spell.GetBaseSpell then
        local base = C_Spell.GetBaseSpell(id)
        if Safe(base) and type(base) == "number" and base > 0 then return base end
    end
    return id
end
local function RebuildBindings()
    bindings = {}
    local visible = {}
    for _, bar in ipairs(bars) do
        for index = 1,12 do
            local frame = _G[bar[1] .. index]
            local slot = frame and frame.action
            if Safe(slot) and type(slot) == "number" and slot > 0 then
                local kind, id = GetActionInfo(slot)
                if Safe(kind) and Safe(id) then
                    local spell = kind == "spell" and id or kind == "macro" and GetMacroSpell and GetMacroSpell(id)
                    local base = BaseSpell(spell)
                    if base then
                        local key = GetBindingKey(frame.bindingAction or bar[2] .. index)
                            or GetBindingKey("CLICK " .. bar[1] .. index .. ":LeftButton")
                        local shown = frame:IsShown()
                        if key and (not bindings[base] or shown and not visible[base]) then
                            bindings[base], visible[base] = key, shown
                        end
                    end
                end
            end
        end
    end
end
local function Available()
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then return false, "API absente" end
    if not C_AssistedCombat.IsAvailable then return true end
    local ok, value, reason = pcall(C_AssistedCombat.IsAvailable)
    return ok and Safe(value) and value == true, Safe(reason) and type(reason)=="string" and reason or "indisponible"
end
local function Update()
    local config = Config()
    local spell
    local available, reason = Available()
    recommendationState = not config.enabled and "désactivé" or not available and reason or "aucun sort recommandé"
    if config.enabled and available then
        local ok, value = pcall(C_AssistedCombat.GetNextCastSpell, false)
        if not ok then recommendationState = "erreur API : " .. (Safe(value) and tostring(value) or "protégée")
        elseif not Safe(value) then recommendationState = "recommandation protégée"
        elseif type(value) == "number" and value > 0 then spell = value; recommendationState = "OK" end
    end
    if not bindings then RebuildBindings() end
    local base = spell and BaseSpell(spell)
    local key = base and bindings[base]
    if spell ~= lastSpell or not textureReady then
        local changed = spell ~= lastSpell
        local texture = spell and C_Spell.GetSpellTexture(spell)
        textureReady = Safe(texture) and texture ~= nil and texture ~= 134400 and texture ~= questionMark
        lastTexture = textureReady and texture or questionMark
        button.icon:SetTexture(lastTexture)
        lastSpell = spell
        -- A recommendation may precede its spell data. Retry the texture without
        -- rescanning bindings, and request data only once per changed recommendation.
        if spell and not textureReady and changed and C_Spell.RequestLoadSpellData then
            C_Spell.RequestLoadSpellData(spell)
        end
    end
    if key ~= lastKey then
        local text = key and GetBindingText(key, 1) or "—"
        text = text:gsub("SHIFT%-", "S-"):gsub("CTRL%-", "C-"):gsub("ALT%-", "A-")
        button.hotkey:SetText(text)
        lastKey = key
    end
    button.spellID = spell
    button:SetShown(editing or config.enabled and spell ~= nil)
end
function addon.GetRotationButtonStatus()
    if not button then return "Rotation : non initialisée." end
    if not initialized then return "Rotation : initialisation interrompue avant le démarrage du bouton. Vérifie les erreurs Lua." end
    Update()
    return "Rotation : " .. (recommendationState or "?") .. "; sort=" .. tostring(lastSpell)
        .. "; icône=" .. tostring(lastTexture) .. "; raccourci=" .. (lastKey or "aucun")
        .. "; édition=" .. tostring(editing == true) .. "; visible=" .. tostring(button:IsShown()) .. "."
end
local function RefreshDriver()
    if not button then return end
    local target = UnitExists("target")
    local active = Config().enabled and Available() and ((Safe(target) and target) or InCombatLockdown())
    if active ~= running then
        running = active
        local elapsed = 0
        driver:SetScript("OnUpdate", active and function(_, delta)
            elapsed = elapsed + delta
            if elapsed >= .1 then elapsed = 0; Update() end
        end or nil)
    end
    Update()
end
local function Render()
    local config = Config()
    button:SetSize(config.size, config.size)
    local anchors = _G.RefineUI and _G.RefineUI.EditModeAnchors
    if not (anchors and anchors:OwnsPosition(button)) then
        button:ClearAllPoints(); button:SetPoint(config.point, UIParent, config.point, config.x, config.y)
    end
    addon.SetFont(button.hotkey, config.fontSize, "OUTLINE", RotationFont())
    cooldownAlert:SetSize(config.size, config.size)
    addon.SetFont(cooldownAlert.label, config.fontSize, "OUTLINE", RotationFont())
    if not config.enabled then ClearCooldownAlert() end
    if anchors then anchors:Refresh() end
    RefreshDriver()
end
function addon.ToggleRotationButton()
    Config().enabled = not Config().enabled
    Render()
end
function addon.InitializeRotationButton()
    if button then return end
    layoutName = LEM:GetActiveLayoutName()
    button = CreateFrame("Button", addonName .. "RotationButton", UIParent)
    button:SetShown(false)
    addon.rotationButton = button
    button.editModeName = title
    button:SetFrameStrata("MEDIUM")
    button.icon = button:CreateTexture(nil,"ARTWORK")
    button.icon:SetPoint("TOPLEFT",1,-1); button.icon:SetPoint("BOTTOMRIGHT",-1,1)
    button.icon:SetTexCoord(.08,.92,.08,.92)
    button.icon:SetTexture(questionMark)
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button); overlay:SetFrameLevel(button:GetFrameLevel() + 1); overlay:EnableMouse(false)
    button.border = CreateRefineBorder(overlay)
    SetBorderColor(borderColor)
    -- The keybind sits above the border, as on RefineUI action buttons.
    local text = CreateFrame("Frame", nil, button)
    text:SetAllPoints(button); text:SetFrameLevel(overlay:GetFrameLevel() + 3); text:EnableMouse(false)
    button.hotkey = text:CreateFontString(nil,"OVERLAY")
    button.hotkey:SetPoint("TOPRIGHT",-2,-4); button.hotkey:SetTextColor(1,1,1,1)
    -- WoW requires a font before SetText; otherwise initialization stops before
    -- the recommendation driver is created, leaving only the placeholder icon.
    addon.SetFont(button.hotkey, Config().fontSize, "OUTLINE", RotationFont())
    button.hotkey:SetText("—")
    button:SetScript("OnEnter",function(self)
        SetBorderColor(hoverColor)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        if self.spellID then
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:AddLine(fr and "Appuie sur le raccourci du sort sur ta barre d’action." or "Press the spell's action bar keybind.",1,1,1,true)
        else GameTooltip:SetText(title) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() SetBorderColor(borderColor); GameTooltip:Hide() end)
    InitializeCooldownAlert()
    driver = CreateFrame("Frame")
    local bindingEvents = { UPDATE_BINDINGS=true, ACTIONBAR_SLOT_CHANGED=true, ACTIONBAR_PAGE_CHANGED=true,
        UPDATE_MACROS=true, SPELLS_CHANGED=true, PLAYER_SPECIALIZATION_CHANGED=true, PLAYER_ENTERING_WORLD=true,
        UPDATE_OVERRIDE_ACTIONBAR=true, UPDATE_VEHICLE_ACTIONBAR=true, UPDATE_BONUS_ACTIONBAR=true }
    driver:SetScript("OnEvent",function(_,event,spellID,castGUID,failedSpellID)
        if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET" then
            if Safe(spellID) and spellID == "player" then ShowCooldownAlert(failedSpellID) end
            return
        elseif event == "UI_ERROR_MESSAGE" then
            local message = castGUID
            if Safe(message) and type(message) == "string" and
                ((ERR_SPELL_COOLDOWN and message == ERR_SPELL_COOLDOWN) or
                 (SPELL_FAILED_NOT_READY and message == SPELL_FAILED_NOT_READY)) and C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if attemptedAt and GetTime() - attemptedAt <= .25 then ShowCooldownAlert(attemptedSpell) end
                end)
            end
            return
        elseif event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
            if cooldownAlert.spellID then UpdateCooldownAlert() end
            return
        elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            ClearCooldownAlert(); RememberSpell(nil)
        end
        if event == "SPELL_DATA_LOAD_RESULT" then
            if not Safe(spellID) or spellID ~= lastSpell then return end
            textureReady = false
        end
        if bindingEvents[event] then
            -- Slot events fire per slot (and on highlight changes): rescan once, next frame.
            bindings = nil
            if C_Timer and C_Timer.After then
                if not refreshQueued then
                    refreshQueued = true
                    C_Timer.After(0, function() refreshQueued = false; RefreshDriver() end)
                end
                return
            end
        end
        RefreshDriver()
    end)
    for _, event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED",
        "UPDATE_BINDINGS","ACTIONBAR_SLOT_CHANGED","ACTIONBAR_PAGE_CHANGED","UPDATE_MACROS","SPELLS_CHANGED",
        "PLAYER_SPECIALIZATION_CHANGED","UPDATE_OVERRIDE_ACTIONBAR","UPDATE_VEHICLE_ACTIONBAR","UPDATE_BONUS_ACTIONBAR",
        "ASSISTED_COMBAT_ACTION_SPELL_CAST","SPELL_DATA_LOAD_RESULT","UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_FAILED_QUIET","UI_ERROR_MESSAGE","SPELL_UPDATE_COOLDOWN","SPELL_UPDATE_CHARGES"}) do driver:RegisterEvent(event) end
    LEM:AddFrame(button,function(_,name,point,x,y)
        local config = Config(name); config.point,config.x,config.y = point,x,y; Render()
    end,{point="CENTER",x=0,y=-130})
    LEM:AddFrameSettings(button,{
        {name=fr and "Activer" or "Enabled",kind=LEM.SettingType.Checkbox,default=true,get=function(name) return Config(name).enabled end,
            set=function(name,value) Config(name).enabled=value; Render() end},
        {name=fr and "Taille du bouton" or "Button size",kind=LEM.SettingType.Slider,default=48,minValue=32,maxValue=80,valueStep=2,
            get=function(name) return Config(name).size end,set=function(name,value) Config(name).size=value; Render() end},
        {name=fr and "Taille du raccourci" or "Keybind size",kind=LEM.SettingType.Slider,default=12,minValue=10,maxValue=18,valueStep=1,
            get=function(name) return Config(name).fontSize end,set=function(name,value) Config(name).fontSize=value; Render() end},
    })
    LEM:RegisterCallback("enter",function() editing=true; Render() end)
    LEM:RegisterCallback("exit",function() editing=false; Render() end)
    LEM:RegisterCallback("layout",function(name) layoutName=name; Render() end)
    LEM:RegisterCallback("create",function(name,_,source)
        addon.db.rotation.layouts[name]=CopyTable(Config(source))
    end)
    LEM:RegisterCallback("rename",function(old,new)
        local layouts=addon.db.rotation.layouts; layouts[new],layouts[old]=layouts[old],nil
        if layoutName==old then layoutName=new end
    end)
    LEM:RegisterCallback("delete",function(name) addon.db.rotation.layouts[name]=nil end)
    if _G.RefineUI and _G.RefineUI.EditModeAnchors then
        _G.RefineUI.EditModeAnchors:RegisterFrame(button,LEM,title,function()
            local config=Config()
            config.point="TOPLEFT"; config.x=button:GetLeft()
            config.y=button:GetTop()-UIParent:GetHeight()*UIParent:GetEffectiveScale()/button:GetEffectiveScale()
        end)
    end
    Render()
    initialized = true
end

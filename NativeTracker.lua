local _, addon = ...
local fr = GetLocale() == "frFR"
local modules, blocks, moduleSet = {}, {}, {}
local initialized = false
local options
local styles = {
    blizzard = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 },
    pixels = { edgeFile = addon.media.borders.pixels.edgeFile, edgeSize = 16 },
    ayije = { edgeFile = addon.media.ayije.borders.Ayije_Thin.edgeFile, edgeSize = 16 },
}

local function Settings()
    if type(addon.characterDB.tracker) ~= "table" then addon.characterDB.tracker = {} end
    local settings = addon.characterDB.tracker
    for key, default in pairs({ enabled = true, details = true, colors = true, progress = true, style = "blizzard" }) do
        if type(settings[key]) ~= type(default) then settings[key] = default end
    end
    if not styles[settings.style] then settings.style = "blizzard" end
    return settings
end

function addon.IsNativeTrackerEnabled()
    return initialized and Settings().enabled
end

local function DecorateHeader(block, title)
    if type(title) ~= "string" or not moduleSet[block.parentModule] or InCombatLockdown() or not Settings().enabled then return end
    local settings = Settings()
    local details = settings.details and addon.GetQuestMetadata(block.id) or ""
    local progress = settings.progress and addon.GetQuestProgress(block.id)
    if progress then details = details .. (details ~= "" and " · " or "") .. string.format("%.0f%%", progress) end
    if details == "" then return end
    -- Reuse Blizzard's text measurement before objectives and block layout run.
    block.height = block:SetStringText(block.HeaderText, title .. "\n" .. details, true,
        OBJECTIVE_TRACKER_COLOR["Header"], block.isHighlighted)
end

local function DecorateBorder(block)
    if InCombatLockdown() then return end
    local settings = Settings()
    if not settings.enabled then
        if block.funelBorder then block.funelBorder:Hide() end
        return
    end
    if not block.funelBorder then
        block.funelBorder = CreateFrame("Frame", nil, block, "BackdropTemplate")
        block.funelBorder:EnableMouse(false)
    end
    local style = styles[settings.style]
    local _, height = GetPhysicalScreenSize()
    local pixel = (768 / (height and height > 0 and height or 1080)) / block:GetEffectiveScale()
    local reach = style.edgeSize == 16 and math.floor(8 / pixel + 0.5) * pixel or 0
    local verticalReach = style.edgeSize == 16 and math.ceil(math.max(8, (32 - block:GetHeight()) / 2) / pixel) * pixel or 0
    local border = block.funelBorder
    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", block, "TOPLEFT", -reach, verticalReach)
    border:SetPoint("BOTTOMRIGHT", block, "BOTTOMRIGHT", reach, -verticalReach)
    border:SetFrameLevel(block:GetFrameLevel() + 1)
    border:SetBackdrop({ edgeFile = style.edgeFile, edgeSize = style.edgeSize })
    local _, color = addon.GetQuestMetadata(block.id)
    color = settings.colors and color or { 0.38, 0.35, 0.29, 1 }
    border:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
    for _, region in ipairs({ border:GetRegions() }) do
        if region.SetSnapToPixelGrid then region:SetSnapToPixelGrid(false); region:SetTexelSnappingBias(0) end
    end
    border:Show()
end

function addon.RefreshNativeTracker()
    if not initialized or InCombatLockdown() then return end
    for _, block in ipairs(blocks) do
        if block.funelBorder then block.funelBorder:Hide() end
    end
    -- A normal Blizzard rebuild restores original headers or applies the new options.
    for _, module in ipairs(modules) do module:MarkDirty() end
    addon.RefreshPanels()
end

function addon.InitializeNativeTracker()
    if initialized then return end
    for _, module in ipairs({ QuestObjectiveTracker, CampaignQuestObjectiveTracker, WorldQuestObjectiveTracker }) do
        if module.GetBlock and module.GetExistingBlock and module.LayoutBlock then
            modules[#modules + 1] = module
            moduleSet[module] = true
            hooksecurefunc(module, "GetBlock", function(self, id, template)
                local block = self:GetExistingBlock(id, template)
                if not block or block.funelHooked or InCombatLockdown() then return end
                block.funelHooked = true
                blocks[#blocks + 1] = block
                hooksecurefunc(block, "SetHeader", DecorateHeader)
            end)
            hooksecurefunc(module, "LayoutBlock", function(_, block) DecorateBorder(block) end)
            hooksecurefunc(module, "FreeBlock", function(_, block)
                if not InCombatLockdown() and block.funelBorder then block.funelBorder:Hide() end
            end)
        end
    end
    initialized = #modules > 0
    if not initialized then return end
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_REGEN_ENABLED", "QUEST_DATA_LOAD_RESULT", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do events:RegisterEvent(event) end
    events:SetScript("OnEvent", addon.RefreshNativeTracker)
    addon.RefreshNativeTracker()
end

function addon.OpenTrackerOptions()
    if not addon.characterDB then return end
    if not options then
        options = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        options:SetSize(360, 270)
        options:SetPoint("CENTER")
        options:SetFrameStrata("DIALOG")
        options:SetClampedToScreen(true)
        options:EnableMouse(true)
        options:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = styles.blizzard.edgeFile, edgeSize = 16 })
        options:SetBackdropColor(0.04, 0.04, 0.04, 1)
        local title = options:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 18, -18)
        title:SetText(fr and "FunelQOL · Suivi Blizzard" or "FunelQOL · Blizzard tracker")
        local close = CreateFrame("Button", nil, options, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -3, -3)
        close:SetScript("OnClick", function() options:Hide() end)
        options.checks = {}
        for index, spec in ipairs({
            { "enabled", fr and "Personnaliser le suivi Blizzard" or "Customize Blizzard tracker" },
            { "details", addon.panelText.questDetails },
            { "colors", addon.panelText.questColors },
            { "progress", fr and "Afficher le pourcentage d’avancée" or "Show progress percentage" },
        }) do
            local check = CreateFrame("CheckButton", nil, options, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", 14, -48 - (index - 1) * 32)
            local label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("LEFT", check, "RIGHT", 2, 0)
            label:SetText(spec[2])
            check:SetScript("OnClick", function(self) Settings()[spec[1]] = self:GetChecked(); addon.RefreshNativeTracker() end)
            options.checks[spec[1]] = check
        end
        local dropdown = CreateFrame("DropdownButton", nil, options, "WowStyle1DropdownTemplate")
        dropdown:SetSize(220, 26)
        dropdown:SetPoint("TOPLEFT", 22, -190)
        dropdown:SetupMenu(function(_, root)
            for _, value in ipairs({ "blizzard", "pixels", "ayije" }) do
                root:CreateRadio(value == "blizzard" and "Blizzard" or value == "pixels" and "Pixels" or "Ayije",
                    function() return Settings().style == value end,
                    function() Settings().style = value; addon.RefreshNativeTracker() end)
            end
        end)
        local hint = options:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", 22, -228)
        hint:SetWidth(316)
        hint:SetText(fr and "Placement : mode édition Blizzard. Changements appliqués hors combat." or "Position: Blizzard Edit Mode. Changes apply outside combat.")
    end
    for key, check in pairs(options.checks) do check:SetChecked(Settings()[key]) end
    options:Show()
end

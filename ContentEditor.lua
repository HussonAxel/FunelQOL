local addonName, addon = ...
local text = addon.panelText
local editor
local editors = setmetatable({}, { __mode = "k" })

local function Button(parent, label, x, y, width, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(label)
    button:SetScript("OnClick", click)
    return button
end

local function Edit(parent, x, y, width, changed)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width, 24)
    box:SetPoint("TOPLEFT", x, y)
    box:SetAutoFocus(false)
    box:SetMaxLetters(80)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnTextChanged", function(self, userInput) if userInput then changed(self:GetText()) end end)
    return box
end

function addon.CloseContentEditor()
    if editor then editor:Hide() end
end

function addon.OpenContentEditor(settings, refresh)
    addon.CloseContentEditor()
    local cache = editors[settings]
    if cache and cache[settings.content] then
        editor = cache[settings.content]
        editor.update()
        editor:Show()
        return
    end
    editor = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    local window = editor
    cache = cache or {}
    editors[settings] = cache
    cache[settings.content] = window
    editor:SetSize(560, 414)
    editor:SetPoint("CENTER")
    editor:SetFrameStrata("DIALOG")
    editor:SetClampedToScreen(true)
    editor:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
    editor:SetBackdropColor(0.04, 0.04, 0.04, 1)
    local title = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText("FunelQOL · " .. settings.title)
    Button(editor, "×", 510, -12, 30, addon.CloseContentEditor)
    local hint = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 20, -54)
    hint:SetWidth(520)
    hint:SetJustifyH("LEFT")
    hint:SetText(text.hint)
    if settings.content == "preview" then
        hint:SetText(text.content .. ": " .. text.preview)
        window.update = function() title:SetText("FunelQOL · " .. settings.title) end
        editor:Show()
        return
    end
    local catalog = addon.GetContentCatalog(settings.content)
    local list = addon.GetContentSelection(settings, catalog)
    settings.selections[settings.content] = list
    if type(settings.customRows) ~= "table" then settings.customRows = {} end
    local slots = {}
    local function Update()
        title:SetText("FunelQOL · " .. settings.title)
        for index, slot in ipairs(slots) do
            if settings.content == "custom" then
                local entry = settings.customRows[index] or {}
                slot.name:SetText(entry.name or "")
                slot.value:SetText(entry.valueText or "")
            else
                local label = text.none
                for _, entry in ipairs(catalog) do if entry.id == list[index] then label = entry.name; break end end
                if list[index] ~= 0 and label == text.none then label = "ID " .. list[index] end
                slot.dropdown:OverrideText(label)
            end
        end
        refresh()
    end
    if settings.content == "custom" then
        for _, field in ipairs({ { text.label, 48 }, { text.value, 288 } }) do
            local label = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", field[2], -78)
            label:SetText(field[1])
        end
    end
    for index = 1, 8 do
        local y = -92 - (index - 1) * 35
        local slot = {}
        slots[index] = slot
        local label = editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 18, y - 6)
        label:SetText(tostring(index))
        if settings.content == "custom" then
            local function Change(key, value)
                if type(settings.customRows[index]) ~= "table" then settings.customRows[index] = {} end
                settings.customRows[index][key] = value
                refresh()
            end
            slot.name = Edit(editor, 48, y, 228, function(value) Change("name", value) end)
            slot.value = Edit(editor, 288, y, 112, function(value) Change("valueText", value) end)
        else
            slot.dropdown = CreateFrame("DropdownButton", nil, editor, "WowStyle1DropdownTemplate")
            slot.dropdown:SetSize(355, 24)
            slot.dropdown:SetPoint("TOPLEFT", 44, y)
            slot.dropdown:SetupMenu(function(_, root)
                root:SetScrollMode(300)
                local function Choice(name, id)
                    root:CreateRadio(name, function() return list[index] == id end, function() list[index] = id; Update() end)
                end
                Choice(text.none, 0)
                for _, entry in ipairs(catalog) do Choice(entry.name, entry.id) end
            end)
        end
        local function Move(offset)
            local target = index + offset
            if target < 1 or target > 8 then return end
            local entries = settings.content == "custom" and settings.customRows or list
            entries[index], entries[target] = entries[target], entries[index]
            Update()
        end
        Button(editor, "↑", 414, y, 32, function() Move(-1) end)
        Button(editor, "↓", 450, y, 32, function() Move(1) end)
        Button(editor, "×", 486, y, 32, function()
            if settings.content == "custom" then settings.customRows[index] = nil else list[index] = 0 end
            Update()
        end)
    end
    if settings.content == "currencies" then
        local idBox = Edit(editor, 48, -380, 160, function() end)
        Button(editor, GetLocale() == "frFR" and "Ajouter un ID monnaie" or "Add currency ID", 222, -380, 210, function()
            local id = tonumber(idBox:GetText())
            if not id or id <= 0 or id ~= math.floor(id) then hint:SetText(GetLocale() == "frFR" and "Saisis un ID de monnaie valide." or "Enter a valid currency ID."); return end
            local info = C_CurrencyInfo.GetCurrencyInfo(id)
            if not info or not info.name or info.name == "" then hint:SetText(GetLocale() == "frFR" and "Monnaie introuvable." or "Currency not found."); return end
            for index = 1, 8 do
                if list[index] == 0 then
                    list[index] = id
                    hint:SetText(text.hint)
                    window.update()
                    idBox:SetText("")
                    return
                end
            end
            hint:SetText(GetLocale() == "frFR" and "Les huit lignes sont occupées. Retire une ligne avant d’ajouter une monnaie." or "All eight rows are occupied. Clear a row before adding a currency.")
        end)
    end
    window.update = function()
        catalog = addon.GetContentCatalog(settings.content)
        if settings.content == "currencies" then
            local seen = {}
            for _, entry in ipairs(catalog) do seen[entry.id] = true end
            for _, id in ipairs(list) do
                if id > 0 and not seen[id] then
                    local info = C_CurrencyInfo.GetCurrencyInfo(id)
                    if info and info.name and info.name ~= "" then
                        catalog[#catalog + 1] = { id = id, name = info.name }
                        seen[id] = true
                    end
                end
            end
        end
        Update()
    end
    window.update()
    editor:Show()
end

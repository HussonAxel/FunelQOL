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
    if addon.CloseRaidCollectionEditor then addon.CloseRaidCollectionEditor() end
    if editor then editor:Hide() end
    if addon.CloseCurrencyEditor then addon.CloseCurrencyEditor() end
end

function addon.OpenContentEditor(settings, refresh)
    addon.CloseContentEditor()
    if settings.content == "currencies" then return addon.OpenCurrencyEditor(settings, refresh) end
    if settings.content == "raidcollection" then return addon.OpenRaidCollectionEditor(settings, refresh) end
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
    if settings.content == "quests" then hint:SetText(text.questHint) end
    if settings.content == "vault" then hint:SetText(text.vaultHint) end
    if settings.content == "raidsets" then hint:SetText(text.raidSetsHint) end
    if settings.content == "renown" then hint:SetText(text.renownHint) end
    if settings.content == "preview" or settings.content == "delves" or settings.content == "delvequests" then
        hint:SetText(settings.content == "delvequests" and text.delveQuestsHint or settings.content == "delves" and text.delvesHint or text.content .. ": " .. text.preview)
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
                    root:CreateRadio(name, function() return list[index] == id end, function()
                        list[index] = id
                        if settings.content == "quests" then settings.questAuto = false end
                        Update()
                    end)
                end
                Choice(text.none, 0)
                for _, entry in ipairs(catalog) do Choice(entry.name, entry.id) end
            end)
        end
        local function Move(offset)
            local target = index + offset
            if target < 1 or target > 8 then return end
            local entries = settings.content == "custom" and settings.customRows or list
            if settings.content == "quests" then settings.questAuto = false end
            entries[index], entries[target] = entries[target], entries[index]
            Update()
        end
        Button(editor, "↑", 414, y, 32, function() Move(-1) end)
        Button(editor, "↓", 450, y, 32, function() Move(1) end)
        Button(editor, "×", 486, y, 32, function()
            if settings.content == "quests" then settings.questAuto = false end
            if settings.content == "custom" then settings.customRows[index] = nil else list[index] = 0 end
            Update()
        end)
    end
    window.update = function()
        catalog = addon.GetContentCatalog(settings.content)
        Update()
    end
    window.update()
    editor:Show()
end

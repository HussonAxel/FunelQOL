local _, addon = ...
local fr = GetLocale() == "frFR"
local text = addon.panelText
text.content = fr and "Contenu" or "Content"
text.configure = fr and "Configurer les lignes" or "Configure rows"
text.empty = fr and "Aucune ligne · configurer le contenu" or "No rows · configure content"
text.none = fr and "Vide" or "Empty"
text.money = fr and "Or" or "Money"
text.label = fr and "Libellé" or "Label"
text.value = fr and "Valeur" or "Value"
text.hint = fr and "Choisis les lignes ; ↑ / ↓ changent leur ordre. Modifications enregistrées immédiatement." or "Choose rows; ↑ / ↓ change their order. Changes are saved immediately."
addon.contentTypes = {
    { text = text.preview, value = "preview" },
    { text = fr and "Monnaies" or "Currencies", value = "currencies" },
    { text = fr and "Métiers" or "Professions", value = "professions" },
    { text = fr and "Talents sélectionnés" or "Selected talents", value = "talents" },
    { text = fr and "Quêtes suivies" or "Tracked quests", value = "quests" },
    { text = fr and "Menu personnalisé" or "Custom menu", value = "custom" },
}

local function Sort(rows)
    table.sort(rows, function(a, b) return a.name == b.name and a.id < b.id or a.name < b.name end)
    return rows
end

function addon.GetContentCatalog(kind)
    if kind == "quests" then return addon.GetQuestCatalog() end
    local rows = {}
    if kind == "currencies" then
        rows[1] = { id = -1, name = text.money, icon = 133784, valueText = C_CurrencyInfo.GetCoinTextureString(GetMoney()) }
        local seen = { [-1] = true }
        for index = 1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(index)
            local link = info and not info.isHeader and C_CurrencyInfo.GetCurrencyListLink(index)
            local id = link and C_CurrencyInfo.GetCurrencyIDFromLink(link)
            if id and not seen[id] then
                rows[#rows + 1] = { id = id, name = info.name }
                seen[id] = true
            end
        end
    elseif kind == "professions" then
        local professions = { GetProfessions() }
        -- GetProfessions has nil holes (e.g. an unlearned second profession).
        for slot = 1, 5 do
            local index = professions[slot]
            if index then
                local name, icon, rank, maximum, _, _, skillLine, _, _, _, expansionName = GetProfessionInfo(index)
                if name and skillLine then
                    rows[#rows + 1] = { id = skillLine, name = expansionName or name, icon = icon,
                        value = rank, maximum = maximum, valueText = rank .. " / " .. maximum }
                end
            end
        end
    elseif kind == "talents" then
        local configID = C_ClassTalents.GetActiveConfigID()
        local config = configID and C_Traits.GetConfigInfo(configID)
        local seen = {}
        for _, treeID in ipairs(config and config.treeIDs or {}) do
            for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
                local node = C_Traits.GetNodeInfo(configID, nodeID)
                if node and node.activeEntry and node.activeEntry.rank > 0 and node.subTreeActive ~= false then
                    local entry = C_Traits.GetEntryInfo(configID, node.activeEntry.entryID)
                    local definition = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
                    local spellID = definition and definition.spellID
                    local spell = spellID and C_Spell.GetSpellInfo(spellID)
                    if spell and not seen[spellID] then
                        rows[#rows + 1] = { id = spellID, spellID = spellID, name = definition.overrideName or spell.name,
                            icon = definition.overrideIcon or spell.iconID, value = node.activeEntry.rank,
                            maximum = entry.maxRanks, valueText = node.activeEntry.rank .. " / " .. entry.maxRanks }
                        seen[spellID] = true
                    end
                end
            end
        end
    end
    return Sort(rows)
end

function addon.GetContentSelection(settings, catalog)
    if type(settings.selections) ~= "table" then settings.selections = {} end
    local list = settings.selections[settings.content]
    if type(list) ~= "table" then
        list = {}
        if #catalog > 0 then
            for index = 1, 8 do list[index] = index <= 3 and catalog[index] and catalog[index].id or 0 end
            settings.selections[settings.content] = list
        end
    end
    for index = 1, 8 do if type(list[index]) ~= "number" then list[index] = 0 end end
    return list
end

local function Currency(id)
    if id == -1 then return { name = text.money, icon = 133784, valueText = C_CurrencyInfo.GetCoinTextureString(GetMoney()) } end
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    if not info or not info.name or info.name == "" then return nil end
    local maximum = not info.useTotalEarnedForMaxQty and info.maxQuantity or 0
    return { name = info.name, icon = info.iconFileID, value = info.quantity, maximum = maximum,
        currencyID = id, valueText = tostring(info.quantity) .. (maximum > 0 and " / " .. maximum or ""), description = info.description }
end

function addon.GetPanelRows(settings)
    if settings.content == "preview" then return addon.GetPreviewRows(settings.rowCount) end
    if settings.content == "quests" then return addon.GetQuestRows(settings) end
    local rows = {}
    if settings.content == "custom" then
        if type(settings.customRows) ~= "table" then settings.customRows = {} end
        for index = 1, 8 do
            local entry = settings.customRows[index]
            if type(entry) == "table" and type(entry.name) == "string" and entry.name ~= "" then
                rows[#rows + 1] = { name = entry.name, valueText = type(entry.valueText) == "string" and entry.valueText or "" }
            end
        end
    else
        local catalog = addon.GetContentCatalog(settings.content)
        local lookup = {}
        for _, entry in ipairs(catalog) do lookup[entry.id] = entry end
        for _, id in ipairs(addon.GetContentSelection(settings, catalog)) do
            if id ~= 0 then
                local entry
                if settings.content == "currencies" then entry = Currency(id) else entry = lookup[id] end
                if entry then rows[#rows + 1] = entry end
            end
        end
    end
    if #rows == 0 then rows[1] = { name = text.empty } end
    return rows
end

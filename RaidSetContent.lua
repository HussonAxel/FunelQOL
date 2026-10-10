local _, addon = ...
local fr = GetLocale() == "frFR"
local text = addon.panelText
text.raidSetsHint = fr and "Choisis les difficultés. Chaque ligne compte les emplacements d'apparence débloqués pour ta classe ; survole pour voir les pièces. Collection du compte, y compris les apparences identiques apprises via un autre objet." or "Choose difficulties. Each row counts collected appearance slots for your class; hover for pieces. Account collection, including identical appearances learned from other items."

-- Client transmog-set IDs, in LFR / Normal / Heroic / Mythic order.
-- Verified against the installed Transmog Upgrade Master v1.5.27 data.
local seasons = {
    [17] = { number = 1, bases = { 5465, 5445, 5433, 5453, 5449, 5417, 5457, 5437, 5461, 5441, 5425, 5421, 5429 } },
    [18] = { number = 2, bases = { 5885, 5865, 5853, 5873, 5869, 5837, 5877, 5857, 5881, 5861, 5845, 5841, 5849 } },
}
local difficulties = { fr and "Outil Raids" or "Raid Finder", fr and "Normal" or "Normal", fr and "Héroïque" or "Heroic", fr and "Mythique" or "Mythic" }
local colors = { { .3, .8, 1 }, { .3, 1, .3 }, { .75, .4, 1 }, { 1, .55, .1 } }
-- InventoryType values, not equipped inventory-slot indices.
local slots = {
    { 1, "HEADSLOT", "Tête", "Head" }, { 3, "SHOULDERSLOT", "Épaules", "Shoulders" },
    { 5, "CHESTSLOT", "Torse", "Chest" }, { 6, "WAISTSLOT", "Taille", "Waist" },
    { 7, "LEGSSLOT", "Jambes", "Legs" }, { 8, "FEETSLOT", "Pieds", "Feet" },
    { 9, "WRISTSLOT", "Poignets", "Wrists" }, { 10, "HANDSSLOT", "Mains", "Hands" },
    { 16, "BACKSLOT", "Dos", "Back" },
}

local function CurrentSeason()
    local id = C_MythicPlus and C_MythicPlus.GetCurrentSeason and C_MythicPlus.GetCurrentSeason()
    if id and id > 0 then return seasons[id] end -- Never label an unsupported live season as an older one.
    local interface = GetBuildInfo and select(4, GetBuildInfo())
    if interface and interface >= 120000 and interface < 120200 then
        return seasons[interface >= 120100 and 18 or 17]
    end
end

function addon.GetRaidSetCatalog()
    local rows = {}
    for index, name in ipairs(difficulties) do rows[index] = { id = index, name = name } end
    return rows
end

function addon.GetRaidSetRows(settings)
    local season = CurrentSeason()
    local classID = UnitClass and select(3, UnitClass("player"))
    local api, collection = C_TransmogSets, C_TransmogCollection
    if not season or not classID or not season.bases[classID] or not api or not api.GetSetInfo or not api.GetSourcesForSlot or not collection or not collection.GetSourceInfo or not collection.GetAllAppearanceSources then
        return { { name = fr and "Sets de la saison indisponibles" or "Season sets unavailable", tooltipLines = { fr and "Saison non prise en charge ou données de collection en cours de chargement." or "Unsupported season or collection data still loading." } } }
    end
    local rows, sourceCache = {}, {}
    local function Learned(sourceID)
        if not sourceID then return "unknown" end
        if sourceCache[sourceID] then return sourceCache[sourceID][1], sourceCache[sourceID][2] end
        local info = collection.GetSourceInfo(sourceID)
        local state = info and (info.isCollected and "direct" or "missing") or "unknown"
        if info and not info.isCollected and info.visualID then
            for _, otherID in ipairs(collection.GetAllAppearanceSources(info.visualID) or {}) do
                local other = collection.GetSourceInfo(otherID)
                if other and other.isCollected then state = "shared"; break end
            end
        end
        sourceCache[sourceID] = { state, info }
        return state, info
    end
    local selected = addon.GetContentSelection(settings, addon.GetRaidSetCatalog())
    local seen = {}
    for _, difficulty in ipairs(selected) do
        if difficulties[difficulty] and not seen[difficulty] then
            seen[difficulty] = true
            local setID = season.bases[classID] + difficulty - 1
            local info = api.GetSetInfo(setID)
            local lines = { "Midnight · " .. (fr and "Saison " or "Season ") .. season.number, info and info.name or (fr and "Données en cours de chargement" or "Data loading"), fr and "Apparences du compte · classe actuelle" or "Account appearances · current class" }
            local collected, total, unknown = 0, 0, not info
            for _, slot in ipairs(slots) do
                local sources = api.GetSourcesForSlot(setID, slot[1])
                -- Robes use a separate inventory type but occupy the same chest slot.
                if slot[1] == 5 then
                    local robes = api.GetSourcesForSlot(setID, 20)
                    if robes and #robes > 0 then
                        local merged = {}
                        for _, source in ipairs(sources or {}) do merged[#merged + 1] = source end
                        for _, source in ipairs(robes) do merged[#merged + 1] = source end
                        sources = merged
                    end
                end
                if not sources then unknown = true end
                if sources and #sources > 0 then
                    total = total + 1
                    local state, itemID = "missing", nil
                    for _, source in ipairs(sources) do
                        local learned, sourceInfo = Learned(source.sourceID)
                        itemID = itemID or sourceInfo and sourceInfo.itemID
                        if source.isCollected or learned == "direct" then state = "direct"; break end
                        if learned == "shared" then state = "shared" elseif learned == "unknown" and state == "missing" then state = "unknown" end
                    end
                    local name = _G[slot[2]] or (fr and slot[3] or slot[4])
                    local itemName = itemID and C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
                    if itemName then name = name .. " : " .. itemName end
                    local unlocked = state == "direct" or state == "shared"
                    if unlocked then collected = collected + 1 end
                    if state == "unknown" then unknown = true end
                    local status = unlocked and (fr and "Débloqué" or "Collected") or state == "unknown" and (fr and "Chargement" or "Loading") or (fr and "Manquant" or "Missing")
                    if state == "shared" then status = status .. (fr and " (autre objet)" or " (other item)") end
                    lines[#lines + 1] = (unlocked and "|cff4dff4d" or state == "unknown" and "|cffaaaaaa" or "|cffff7777") .. name .. " — " .. status .. "|r"
                end
            end
            if total == 0 then unknown = true end
            if unknown then lines[#lines + 1] = fr and "Collection en cours de chargement ; le total sera affiché quand les données seront disponibles." or "Collection loading; the total will appear once data is available." end
            local complete = not unknown and collected == total
            rows[#rows + 1] = { name = difficulties[difficulty], raidSetID = setID, value = collected, maximum = total,
                valueText = unknown and "…" or collected .. " / " .. total, fitValue = true,
                compactColor = complete and { .3, 1, .3 } or colors[difficulty],
                icon = complete and "Interface\\RaidFrame\\ReadyCheck-Ready" or 132143, tooltipLines = lines }
        end
    end
    if #rows == 0 then rows[1] = { name = text.empty } end
    return rows
end

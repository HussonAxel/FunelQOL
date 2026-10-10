local _, addon = ...
local fr = GetLocale() == "frFR"
local cache
local modes = {
    upgrade = { color = "ffffaa44", name = fr and "Amélioration" or "Upgrade", atlas = "CovenantSanctum-Upgrade-Icon-Available", fallback = "↑" },
    catalyst = { color = "ffcc88ff", name = fr and "Catalyse" or "Catalyst", atlas = "CreationCatalyst-32x32", fallback = "◇" },
    both = { color = "ffffdd44", name = fr and "Catalyse + amélioration" or "Catalyst + upgrade" },
}
addon.raidAppearanceModes = modes
function addon.InvalidateRaidActions() cache = nil end

local function Icon(mode)
    if mode == "both" then return Icon("catalyst") .. Icon("upgrade") end
    local data = modes[mode]
    local atlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(data.atlas)
    return atlas and ("|A:" .. data.atlas .. ":14:14|a") or ("|c" .. data.color .. data.fallback .. "|r")
end
addon.GetRaidActionIcon = Icon

local function ReadActions()
    local classID = UnitClass and select(3, UnitClass("player"))
    if cache and cache.classID == classID then
        if cache.pending then addon.raidUpgradePending = true end
        return cache
    end
    local result = { classID = classID, sets = {}, visuals = {}, pending = false }
    cache = result
    local api, core = TransmogUpgradeMaster_API, TransmogUpgradeMaster
    if not api or not api.GetAppearanceMissingData or not core or not core.GetSetsForClass then result.status = "unavailable"; return result end
    if api.IsCacheWarmedUp then
        local ok, ready = pcall(api.IsCacheWarmedUp)
        if not ok or not ready then result.pending = true; addon.raidUpgradePending = true; result.status = "loading"; return result end
    end
    result.status = "ready"
    local function Add(index, key, slot, mode, item)
        if not key or not slot then return end
        index[key] = index[key] or {}
        index[key][slot] = index[key][slot] or {}
        index[key][slot][#index[key][slot] + 1] = { mode = mode, itemLink = item.link, location = item.location, upgrade = item.upgrade }
    end
    local analyzed = {}
    local function Check(link, location)
        if not link or analyzed[link] then return end
        analyzed[link] = true
        local ok, data = pcall(api.GetAppearanceMissingData, link, classID)
        if not ok or type(data) ~= "table" then result.status = "partial"; return end
        if data.canCatalyse == nil or data.canUpgrade == nil then
            result.pending = true; addon.raidUpgradePending = true
            local id = tonumber(link:match("item:(%d+)"))
            if id and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
            return
        end
        local context = data.contextData
        if not context or not context.tier or not context.slot or context.isPvpItem then return end
        local slot = context.slot == 20 and 5 or context.slot
        local item = { link = link, location = location }
        local upgradeInfo = C_Item and C_Item.GetItemUpgradeInfo and C_Item.GetItemUpgradeInfo(link)
        local constants = core.data and core.data.constants
        local breakpoint = constants and constants.upgradeTransmogBreakpoints and constants.upgradeTransmogBreakpoints[context.seasonID]
        if upgradeInfo and breakpoint then item.upgrade = tostring(upgradeInfo.currentLevel) .. " → " .. breakpoint .. " / " .. tostring(upgradeInfo.maxLevel) end
        local setOK, sets = false, nil
        if context.seasonID then setOK, sets = pcall(core.GetSetsForClass, core, classID, context.seasonID) end
        if setOK and sets then
            if data.canCatalyse and data.catalystAppearanceMissing and not data.catalystAppearanceLearnedFromOtherItem then Add(result.sets, sets[context.tier], slot, "catalyst", item) end
            if data.canCatalyse and data.canUpgrade and data.catalystUpgradeAppearanceMissing and not data.catalystUpgradeAppearanceLearnedFromOtherItem then Add(result.sets, sets[context.tier + 1], slot, "both", item) end
        end
        -- Upgrade alone must lead to this exact raid visual. Being on the same
        -- track/slot is insufficient: non-tier armor can have another appearance.
        if data.canUpgrade and data.upgradeAppearanceMissing and not data.upgradeAppearanceLearnedFromOtherItem and core.GetSourceIDsForItemID then
            local sourceOK, ids = pcall(core.GetSourceIDsForItemID, core, context.itemID)
            local sourceID = sourceOK and ids and ids[context.tier + 1]
            local info = sourceID and C_TransmogCollection.GetSourceInfo(sourceID)
            if info then Add(result.visuals, info.visualID, slot, "upgrade", item) end
        end
    end
    for slot = 1, 19 do
        Check(GetInventoryItemLink and GetInventoryItemLink("player", slot), fr and "Équipé" or "Equipped")
    end
    if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemLink then
        for bag = 0, NUM_BAG_SLOTS or 4 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                Check(C_Container.GetContainerItemLink(bag, slot), (fr and "Sac " or "Bag ") .. bag .. ", " .. (fr and "emplacement " or "slot ") .. slot)
            end
        end
    end
    return result
end

function addon.GetRaidSlotActions(setID, slot, sources)
    local index = ReadActions()
    local routes, seen = {}, {}
    local function Include(list)
        for _, route in ipairs(list or {}) do
            local key = route.mode .. route.itemLink
            if not seen[key] then routes[#routes + 1] = route; seen[key] = true end
        end
    end
    Include(index.sets[setID] and index.sets[setID][slot])
    for _, source in ipairs(sources or {}) do
        local info = source.sourceID and C_TransmogCollection.GetSourceInfo(source.sourceID)
        if info then Include(index.visuals[info.visualID] and index.visuals[info.visualID][slot]) end
    end
    return routes, index.status, index.pending
end

function addon.GetRaidActionText(route)
    local mode = modes[route.mode]
    return "|c" .. mode.color .. Icon(route.mode) .. " " .. mode.name .. "|r : " .. route.itemLink .. " · " .. route.location ..
        (route.mode ~= "catalyst" and route.upgrade and (" · " .. route.upgrade) or "")
end

function addon.PreviewRaidSet(data)
    if InCombatLockdown() or not data or not data.raidPreviewSources or #data.raidPreviewSources == 0 or not DressUpTransmogSet then return false end
    DressUpTransmogSet(data.raidPreviewSources)
    return true
end

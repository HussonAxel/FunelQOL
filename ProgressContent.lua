local _, addon = ...
local fr = GetLocale() == "frFR"
local text = addon.panelText
text.vault = fr and "Chambre forte" or "Great Vault"
text.renown = fr and "Renoms · Midnight" or "Renown · Midnight"
text.vaultHint = fr and "Choisis les catégories : chacune affiche tous ses emplacements de la chambre forte. Survole une ligne pour les détails." or "Choose categories: each displays all its Great Vault slots. Hover a row for details."
text.renownHint = fr and "Choisis les renoms de Midnight à afficher. Toutes les factions disponibles sont sélectionnées au départ ; survole pour la progression détaillée." or "Choose Midnight renown factions. Available factions are initially selected; hover for detailed progress."
local green, cyan, gray, gold = { 0.3, 1, 0.3 }, { 0.15, 0.8, 1 }, { 0.65, 0.65, 0.65 }, { 1, 0.82, 0 }
local midnight = LE_EXPANSION_MIDNIGHT or 11

function addon.OpenRenownSummary(factionID)
    if not factionID or InCombatLockdown() then return false end
    -- Follow Retail's ReputationDetailViewRenownButtonMixin:OnClick path.
    -- Modern clients use the Adventure Guide's Journeys tab for renown.
    if EncounterJournal_LoadUI or EJ_ContentTab_Select or EncounterJournalJourneysFrame then
        if not EncounterJournal then
            if EncounterJournal_LoadUI then EncounterJournal_LoadUI()
            elseif C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_EncounterJournal") end
        end
        local journal, journeys = EncounterJournal, EncounterJournalJourneysFrame
        if journal and journal.JourneysTab and journeys and journeys.ResetView and EJ_ContentTab_Select then
            if not journal:IsShown() then ShowUIPanel(journal) end
            EJ_ContentTab_Select(journal.JourneysTab:GetID())
            journeys:ResetView(nil, factionID)
            return true
        end
    end
    -- Compatibility with clients that still provide the old renown window.
    if not MajorFactionRenownFrame then
        if MajorFactions_LoadUI then MajorFactions_LoadUI()
        elseif C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_MajorFactions") end
    end
    local frame = MajorFactionRenownFrame
    if not frame or not ToggleMajorFactionRenown then return false end
    -- A repeated right click should leave the requested summary open.
    if frame:IsShown() and frame:GetCurrentFactionID() == factionID then return true end
    ToggleMajorFactionRenown(factionID)
    return true
end

function addon.GetVaultCatalog()
    local rows, groups = {}, {}
    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return rows end
    local kinds = Enum and Enum.WeeklyRewardChestThresholdType or {}
    local names = {
        { kinds.Raid, fr and "Raids" or "Raids" },
        { kinds.Activities, fr and "Donjons" or "Dungeons" },
        { kinds.World, fr and "Gouffres et monde" or "Delves and world" },
        { kinds.RankedPvP, fr and "JcJ classé" or "Rated PvP" },
    }
    local activities = C_WeeklyRewards.GetActivities() or {}
    local hasWorld = false
    for _, activity in ipairs(activities) do if kinds.World and activity.type == kinds.World then hasWorld = true end end
    for _, activity in ipairs(activities) do
        -- Match Blizzard's conditional world/PvP row and ignore concession rewards.
        if activity.threshold and activity.threshold > 0 and activity.index and activity.type
            and not (hasWorld and kinds.RankedPvP and activity.type == kinds.RankedPvP) then
            local group = groups[activity.type]
            if not group then
                local name = (fr and "Activité " or "Activity ") .. activity.type
                for _, kind in ipairs(names) do if kind[1] == activity.type then name = kind[2]; break end end
                group = { id = activity.type, name = name, activities = {} }
                groups[activity.type] = group
                rows[#rows + 1] = group
            end
            group.activities[#group.activities + 1] = activity
        end
    end
    table.sort(rows, function(a, b) return a.id < b.id end)
    for _, row in ipairs(rows) do table.sort(row.activities, function(a, b) return a.index < b.index end) end
    return rows
end

function addon.GetVaultRows(settings)
    local catalog, rows, lookup, seen = addon.GetVaultCatalog(), {}, {}, {}
    for _, category in ipairs(catalog) do lookup[category.id] = category end
    local claim = C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards and C_WeeklyRewards.HasAvailableRewards()
    if claim then
        rows[#rows + 1] = { name = fr and "Récompense" or "Reward", valueText = fr and "À récupérer" or "Claim",
            icon = "Interface\\Icons\\INV_Misc_TreasureChest01", labelColor = gold, fitValue = true,
            tooltipLines = { fr and "Une récompense de la chambre forte est disponible." or "A Great Vault reward is available." } }
    end
    local currentPeriod = not C_WeeklyRewards or not C_WeeklyRewards.AreRewardsForCurrentRewardPeriod
        or C_WeeklyRewards.AreRewardsForCurrentRewardPeriod()
    for _, id in ipairs(addon.GetContentSelection(settings, catalog)) do
        local category = lookup[id]
        if category and not seen[id] then
            seen[id] = true
            for _, activity in ipairs(category.activities) do
                local progress = math.max(0, activity.progress or 0)
                local unlocked = progress >= activity.threshold
                local link, level
                if unlocked and activity.id and C_WeeklyRewards.GetExampleRewardItemHyperlinks then
                    link = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activity.id)
                    if link and C_Item and C_Item.GetDetailedItemLevelInfo then level = C_Item.GetDetailedItemLevelInfo(link) end
                end
                local count = math.min(progress, activity.threshold) .. " / " .. activity.threshold
                local lines = { category.name .. " · " .. (fr and "Emplacement " or "Slot ") .. activity.index,
                    (fr and "Progression : " or "Progress: ") .. progress .. " / " .. activity.threshold,
                    unlocked and (fr and "Emplacement débloqué" or "Slot unlocked") or (fr and "Emplacement verrouillé" or "Slot locked") }
                if level then lines[#lines + 1] = (fr and "Niveau d’objet : " or "Item level: ") .. level end
                if link then lines[#lines + 1] = link end
                if claim and not currentPeriod then lines[#lines + 1] = fr and "Récompenses de la période précédente affichées par Blizzard." or "Blizzard is displaying rewards from the previous period." end
                rows[#rows + 1] = { name = category.name .. " · " .. activity.index,
                    valueText = unlocked and (level and tostring(level) or "OK") or count,
                    labelColor = unlocked and green or cyan, icon = "Interface\\Icons\\INV_Misc_TreasureChest01",
                    gaugeValue = math.min(progress, activity.threshold), gaugeMaximum = activity.threshold,
                    vaultActivityID = activity.id, tooltipLines = lines, fitValue = true }
            end
        end
    end
    if #rows == 0 then rows[1] = { name = #catalog == 0 and (fr and "Chambre forte indisponible" or "Great Vault unavailable") or text.empty, labelColor = gray } end
    return rows
end

function addon.GetRenownCatalog()
    local rows, seen = {}, {}
    if not C_MajorFactions or not C_MajorFactions.GetMajorFactionIDs or not C_MajorFactions.GetMajorFactionData then return rows end
    for _, id in ipairs(C_MajorFactions.GetMajorFactionIDs(midnight) or {}) do
        local info = C_MajorFactions.GetMajorFactionData(id)
        local hidden = C_MajorFactions.IsMajorFactionHiddenFromExpansionPage and C_MajorFactions.IsMajorFactionHiddenFromExpansionPage(id)
        if info and info.name and info.name ~= "" and info.expansionID == midnight and not hidden and not seen[id] then
            seen[id] = true
            local maximum = C_MajorFactions.HasMaximumRenown and C_MajorFactions.HasMaximumRenown(id)
                or info.maxLevel and info.maxLevel > 0 and (info.renownLevel or 0) >= info.maxLevel
            local level, earned, threshold = info.renownLevel or 0, info.renownReputationEarned or 0, info.renownLevelThreshold or 0
            local value = tostring(level)
            local lines = { (fr and "Renom : " or "Renown: ") .. level }
            local color = cyan
            if not info.isUnlocked then
                value, color = fr and "Verrouillé" or "Locked", gray
                lines[#lines + 1] = info.unlockDescription or (fr and "Faction à débloquer." or "Unlock this faction first.")
            elseif maximum then
                value, color = level .. " · MAX", green
                lines[#lines + 1] = fr and "Renom maximum atteint." or "Maximum renown reached."
            elseif threshold > 0 then
                value = level .. " · " .. math.floor(math.max(0, math.min(1, earned / threshold)) * 100) .. "%"
                lines[#lines + 1] = (fr and "Prochain niveau : " or "Next level: ") .. earned .. " / " .. threshold
            end
            if info.description and info.description ~= "" then lines[#lines + 1] = info.description end
            lines[#lines + 1] = fr and "Clic droit : ouvrir le résumé du renom" or "Right click: open renown summary"
            local iconAtlas
            if type(info.textureKit) == "string" and info.textureKit ~= "" and C_Texture and C_Texture.GetAtlasInfo then
                local candidate = "majorfactions_icons_" .. info.textureKit .. "512"
                if C_Texture.GetAtlasInfo(candidate) then iconAtlas = candidate end
            end
            rows[#rows + 1] = { id = id, factionID = id, name = info.name, valueText = value, labelColor = color,
                gaugeValue = info.isUnlocked and (maximum and 1 or math.max(0, math.min(earned, threshold))) or nil,
                gaugeMaximum = info.isUnlocked and (maximum and 1 or threshold > 0 and threshold or nil) or nil,
                icon = "Interface\\Icons\\Achievement_Reputation_01", iconAtlas = iconAtlas, iconSize = iconAtlas and 20 or nil,
                tooltipLines = lines, priority = info.uiPriority or 0, fitValue = true }
        end
    end
    table.sort(rows, function(a, b) return a.priority == b.priority and a.name < b.name or a.priority < b.priority end)
    return rows
end

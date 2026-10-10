local _, addon = ...
local fr = GetLocale() == "frFR"
local text = addon.panelText
text.delveQuests = fr and "Quêtes de gouffres" or "Delve quests"
text.delveQuestsHideCompleted = fr and "Masquer les quêtes déjà rendues" or "Hide turned-in quests"
text.delveQuestsHint = fr and "Les dix quêtes Delver’s Call de Midnight sont suivies automatiquement pour ce personnage, même hors du journal. Masquer les quêtes rendues : mode édition." or "The ten Midnight Delver's Call quests are tracked automatically for this character, even outside the quest log. Hide turned-in quests in Edit Mode."
local requested = {}
local statuses = {
    unaccepted = { fr and "Non prise" or "Not accepted", { 0.65, 0.65, 0.65 } },
    active = { fr and "En cours" or "In progress", { 0.15, 0.8, 1 } },
    ready = { fr and "À rendre" or "Ready", { 1, 0.82, 0 } },
    turnedIn = { fr and "Rendue" or "Turned in", { 0.3, 1, 0.3 } },
    failed = { fr and "Échouée" or "Failed", { 1, 0.3, 0.3 } },
    unknown = { fr and "Indéterminé" or "Unknown", { 0.65, 0.65, 0.65 } },
}

function addon.GetDelveQuestState(definition)
    local id = definition and definition.levelingQuestID
    if not id then return nil end
    local api = C_QuestLog or {}
    local title = api.GetTitleForQuestID and api.GetTitleForQuestID(id)
    if not title or title == "" then
        if not requested[id] and api.RequestLoadQuestByID then requested[id] = true; api.RequestLoadQuestByID(id) end
        title = "Delver's Call: " .. definition.name
    end
    local onQuest = api.IsOnQuest and api.IsOnQuest(id)
    if onQuest == nil and api.GetLogIndexForQuestID then onQuest = (api.GetLogIndexForQuestID(id) or 0) > 0 end
    local state = "unknown"
    if onQuest then
        state = api.IsFailed and api.IsFailed(id) and "failed" or api.IsComplete and api.IsComplete(id) and "ready" or "active"
    elseif onQuest ~= nil and api.IsQuestFlaggedCompleted then
        state = api.IsQuestFlaggedCompleted(id) and "turnedIn" or "unaccepted"
    end
    local info = statuses[state]
    local lines = { title .. " · ID " .. id, info[1], definition.zone }
    if state == "unaccepted" then
        lines[#lines + 1] = fr and "Pas dans le journal. La disponibilité dépend des prérequis du personnage." or "Not in your quest log. Availability depends on this character's prerequisites."
    elseif onQuest and api.GetQuestObjectives then
        for _, objective in ipairs(api.GetQuestObjectives(id) or {}) do
            if objective.text and objective.text ~= "" then lines[#lines + 1] = objective.text end
        end
    end
    return { id = id, title = title, status = state, label = info[1], color = info[2], onQuest = onQuest, tooltipLines = lines }
end

function addon.GetDelveQuestRows(settings)
    local rows = {}
    for _, definition in ipairs(addon.delveRatings) do
        local quest = addon.GetDelveQuestState(definition)
        if quest and not (settings.delveQuestsHideCompleted and quest.status == "turnedIn") then
            local name = quest.title:match(":%s*(.+)$") or definition.name
            rows[#rows + 1] = { name = name, valueText = quest.label, labelColor = quest.color, fitValue = true,
                delveQuestID = quest.id, delveQuestActive = quest.onQuest, delveQuestStatus = quest.status,
                tooltipLines = quest.tooltipLines, icon = (quest.status == "ready" or quest.status == "turnedIn")
                    and "Interface\\GossipFrame\\ActiveQuestIcon" or "Interface\\GossipFrame\\AvailableQuestIcon" }
        end
    end
    if #rows == 0 then rows[1] = { name = fr and "Toutes les quêtes sont rendues" or "All quests turned in" } end
    return rows
end

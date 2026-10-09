local _, addon = ...
local text = addon.panelText
local fr = GetLocale() == "frFR"
text.questAuto = fr and "Suivre automatiquement les quêtes" or "Follow tracked quests automatically"
text.questLimit = fr and "Nombre de quêtes automatiques" or "Automatic quest count"
text.questObjectives = fr and "Afficher les objectifs des quêtes" or "Show quest objectives"
text.questEmpty = fr and "Aucune quête suivie · suis une quête dans le journal" or "No tracked quests · track a quest in the quest log"
text.questReady = fr and "À rendre" or "Ready"
text.questFailed = fr and "Échouée" or "Failed"
text.questLoading = fr and "Chargement…" or "Loading…"
text.questActive = fr and "En cours" or "In progress"
text.questHint = fr and "Choisir, déplacer ou retirer une quête active la sélection manuelle. Le suivi automatique se règle en mode édition." or "Choosing, moving or clearing a quest switches to manual selection. Enable automatic tracking in Edit Mode."
local requested = {}

function addon.GetQuestCatalog()
    local rows, seen = {}, {}
    local function Add(id)
        if not id or seen[id] then return end
        seen[id] = true
        local title = C_QuestLog.GetTitleForQuestID(id)
        if not title or title == "" then
            if not requested[id] then
                requested[id] = true
                C_QuestLog.RequestLoadQuestByID(id)
            end
            title = (fr and "Quête " or "Quest ") .. id
        end
        rows[#rows + 1] = { id = id, name = title }
    end
    for index = 1, C_QuestLog.GetNumQuestWatches() do Add(C_QuestLog.GetQuestIDForQuestWatchIndex(index)) end
    for index = 1, C_QuestLog.GetNumWorldQuestWatches() do Add(C_QuestLog.GetQuestIDForWorldQuestWatchIndex(index)) end
    return rows
end

function addon.GetQuestRows(settings)
    local catalog = addon.GetQuestCatalog()
    local lookup, selected, rows = {}, {}, {}
    for _, quest in ipairs(catalog) do lookup[quest.id] = quest end
    if settings.questAuto then
        for index = 1, math.min(#catalog, settings.questLimit) do selected[index] = catalog[index].id end
    else
        selected = addon.GetContentSelection(settings, catalog)
    end
    local seen = {}
    for _, id in ipairs(selected) do
        local quest = lookup[id]
        if quest and not seen[id] then
            seen[id] = true
            local objectives = C_QuestLog.GetQuestObjectives(id)
            local complete, failed = C_QuestLog.IsComplete(id), C_QuestLog.IsFailed(id)
            local finished = 0
            for _, objective in ipairs(objectives or {}) do if objective.finished then finished = finished + 1 end end
            local status = failed and text.questFailed or complete and text.questReady
                or not objectives and text.questLoading or #objectives > 0 and finished .. " / " .. #objectives or text.questActive
            rows[#rows + 1] = { name = quest.name, valueText = status, questID = id,
                questTitle = quest.name, objectives = objectives, wrap = true }
            if settings.questObjectives and not complete and not failed then
                for _, objective in ipairs(objectives or {}) do
                    local value, maximum = objective.numFulfilled or 0, objective.numRequired or 0
                    local valueText = objective.finished and (fr and "Terminé" or "Done") or ""
                    if objective.type == "progressbar" then
                        value, maximum = GetQuestProgressBarPercent(id) or 0, 100
                        valueText = string.format("%.0f%%", value)
                    elseif maximum > 1 then
                        valueText = value .. " / " .. maximum
                    end
                    rows[#rows + 1] = { name = "  " .. objective.text, valueText = valueText,
                        value = value, maximum = maximum, questID = id, questTitle = quest.name,
                        objectives = objectives, wrap = true }
                end
            end
        end
    end
    if #rows == 0 then rows[1] = { name = #catalog == 0 and text.questEmpty or text.empty, wrap = true } end
    return rows
end

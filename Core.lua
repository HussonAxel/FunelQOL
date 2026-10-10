local addonName, addon = ...

addon.version = "0.16.0"

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffFunelQOL|r: " .. message)
end

local function ShowHelp()
    Print("/funelqol status - Show addon status.")
    Print("/funelqol greeting - Toggle the login greeting.")
    Print("/funelqol perf - Report performance; start/stop or bench to measure.")
    Print("/funelqol edit - Open Blizzard Edit Mode for panel settings.")
    Print("/funelqol title <number> <text> - Rename a panel in the current layout.")
    Print("/funelqol content <number> - Configure panel rows.")
    Print("/funelqol add - Create a new panel.")
    Print("/funelqol remove - Delete the last panel and its settings.")
    Print("/funelqol rotation - Toggle Blizzard's rotation suggestion button.")
    Print("/funelqol rotation status - Diagnose the rotation suggestion and icon.")
    Print("/funelqol raidsets status - Diagnose equipped waist, wrist and feet appearance routes.")
    Print("/funelqol help - Show these commands.")
end

local function HandleCommand(message)
    local input = string.match(message or "", "^%s*(.-)%s*$")
    local command = string.lower(input)
    local action, arguments = string.match(input, "^(%S+)%s*(.*)$")

    if action and string.lower(action) == "perf" then
        addon.HandlePerformanceCommand(arguments)
    elseif action and string.lower(action) == "title" then
        local panelID, title = string.match(arguments, "^(%d+)%s+(.+)$")
        if panelID and addon.panels[tonumber(panelID)] and #title <= 80 then
            addon.SetPanelTitle(tonumber(panelID), title)
        else
            Print("Usage: /funelqol title <1-" .. #addon.panels .. "> <short title>")
        end
    elseif action and string.lower(action) == "content" then
        local panelID = tonumber(string.match(arguments, "^(%d+)$"))
        if panelID and addon.panels[panelID] then addon.ConfigurePanel(panelID) else Print("Usage: /funelqol content <1-" .. #addon.panels .. ">") end
    elseif command == "add" then
        Print("Panel " .. addon.AddPanel() .. " created.")
    elseif command == "remove" then
        local index = addon.RemovePanel()
        if index then Print("Panel " .. index .. " removed.") else Print("The last remaining panel cannot be removed.") end
    elseif command == "raidsets status" and addon.GetRaidActionsDiagnostics then
        for _,line in ipairs(addon.GetRaidActionsDiagnostics()) do Print(line) end
    elseif command == "rotation status" and addon.GetRotationButtonStatus then
        Print(addon.GetRotationButtonStatus())
    elseif command == "rotation" and addon.ToggleRotationButton then
        addon.ToggleRotationButton()
    elseif command == "edit" then
        if InCombatLockdown() then
            Print("Edit Mode is unavailable in combat.")
        else
            ShowUIPanel(EditModeManagerFrame)
        end
    elseif command == "status" then
        Print("Version " .. addon.version .. "; login greeting " .. (addon.db.showGreeting and "on" or "off") .. ".")
    elseif command == "greeting" then
        addon.db.showGreeting = not addon.db.showGreeting
        Print("Login greeting " .. (addon.db.showGreeting and "enabled" or "disabled") .. ".")
    else
        if command ~= "" and command ~= "help" then
            Print("Unknown command: " .. command)
        end
        ShowHelp()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event == "ADDON_LOADED" then
        if loadedAddonName ~= addonName then
            return
        end

        if type(FunelQOLDB) ~= "table" then
            FunelQOLDB = {}
        end
        if type(FunelQOLDB.showGreeting) ~= "boolean" then
            FunelQOLDB.showGreeting = true
        end
        addon.db = FunelQOLDB

        SLASH_FUNELQOL1 = "/funelqol"
        SlashCmdList.FUNELQOL = HandleCommand
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        addon.InitializePanels()
        if addon.InitializeRareMapPins then addon.InitializeRareMapPins() end
        if addon.InitializeRotationButton then addon.InitializeRotationButton() end
        if addon.db and addon.db.showGreeting then
            Print("Loaded v" .. addon.version .. ". Type /funelqol for help.")
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

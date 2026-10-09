local addonName, addon = ...

addon.version = "0.1.0"

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffFunelQOL|r: " .. message)
end

local function ShowHelp()
    Print("/funelqol status - Show addon status.")
    Print("/funelqol greeting - Toggle the login greeting.")
    Print("/funelqol help - Show these commands.")
end

local function HandleCommand(message)
    local command = string.lower(string.match(message or "", "^%s*(.-)%s*$"))

    if command == "status" then
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
        if addon.db and addon.db.showGreeting then
            Print("Loaded v" .. addon.version .. ". Type /funelqol for help.")
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

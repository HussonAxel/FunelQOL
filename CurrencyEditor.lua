local _, addon = ...
local fr = GetLocale() == "frFR"
local active
local windows = setmetatable({}, {__mode = "k"})
function addon.CloseCurrencyEditor() if active then active:Hide() end end
local function Button(parent, label, x, y, width, callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,24); b:SetPoint("TOPLEFT",x,y); b:SetText(label); b:SetScript("OnClick",callback)
    return b
end
function addon.OpenCurrencyEditor(settings, refresh)
    local window = windows[settings]
    if window then active=window; window.update(); window:Show(); return end
    window=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
    active=window; windows[settings]=window
    window:SetSize(560,620); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG"); window:SetClampedToScreen(true)
    window:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
    window:SetBackdropColor(.04,.04,.04,.96)
    local function Label(parent,font,x,y,width)
        local label=parent:CreateFontString(nil,"OVERLAY",font)
        label:SetPoint("TOPLEFT",x,y); label:SetWidth(width); label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        return label
    end
    local title=Label(window,"GameFontNormalLarge",20,-18,480)
    local hint=Label(window,"GameFontHighlightSmall",20,-52,520)
    Button(window,"×",510,-12,30,addon.CloseContentEditor)
    Label(window,"GameFontNormal",20,-84,86):SetText(fr and "Recherche" or "Search")
    local search=CreateFrame("EditBox",nil,window,"InputBoxTemplate")
    search:SetSize(420,24); search:SetPoint("TOPLEFT",110,-78); search:SetAutoFocus(false); search:SetMaxLetters(80)
    search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    local scroll=CreateFrame("ScrollFrame",nil,window,"UIPanelScrollFrameTemplate")
    scroll:SetSize(500,304); scroll:SetPoint("TOPLEFT",20,-114)
    local content=CreateFrame("Frame",nil,scroll); content:SetSize(500,304); scroll:SetScrollChild(content)
    local summary=Label(window,"GameFontNormal",20,-432,510)
    local choices, headings, selectedSlots = {}, {}, {}
    local list=addon.GetContentSelection(settings,addon.GetCurrencyCatalog())
    local function Compact()
        local result, seen={},{}
        for _,id in ipairs(list) do if id~=0 and not seen[id] then result[#result+1]=id; seen[id]=true end end
        for i=1,math.max(8,#list) do list[i]=result[i] or (i<=8 and 0 or nil) end
    end
    Compact()
    local function Position(id) for i,selected in ipairs(list) do if selected==id then return i end end end
    local function Toggle(id)
        local index=Position(id)
        if index then list[index]=0; Compact()
        else
            local empty
            for i=1,8 do if list[i]==0 then empty=i; break end end
            if not empty then hint:SetText(fr and "Les 8 lignes sont occupées. Décoche une monnaie avant d’en ajouter une." or "All 8 rows are occupied. Uncheck a currency before adding one."); return end
            list[empty]=id
        end
        window.update(); refresh()
    end
    for i=1,8 do
        local x,y=20+(i>4 and 260 or 0),-458-((i-1)%4)*30
        local slot={label=Label(window,"GameFontHighlightSmall",x,y-5,164)}
        selectedSlots[i]=slot
        local function Move(offset)
            local target=i+offset
            if target<1 or target>8 or list[i]==0 or list[target]==0 then return end
            list[i],list[target]=list[target],list[i]; window.update(); refresh()
        end
        Button(window,"↑",x+164,y,24,function() Move(-1) end)
        Button(window,"↓",x+190,y,24,function() Move(1) end)
        Button(window,"×",x+216,y,24,function() if list[i]~=0 then Toggle(list[i]) end end)
    end
    Button(window,fr and "Tout retirer" or "Clear all",400,-582,140,function()
        for i=1,#list do list[i]=0 end
        window.update(); refresh()
    end)
    Label(window,"GameFontHighlightSmall",20,-590,365):SetText(fr and "Enregistrement immédiat · ↑ / ↓ pour l’ordre" or "Saved immediately · ↑ / ↓ to reorder")
    window.update=function()
        title:SetText("FunelQOL · "..settings.title)
        hint:SetText(fr and "Coche les monnaies à suivre ; elles s’ajoutent dans l’ordre de sélection." or "Check currencies to track; they are added in selection order.")
        local catalog=addon.GetCurrencyCatalog(list)
        local lookup,groups={},{}
        local query=string.lower(search:GetText() or "")
        for _,entry in ipairs(catalog) do
            lookup[entry.id]=entry
            if query=="" or string.lower(entry.name):find(query,1,true) or string.lower(entry.category):find(query,1,true) then
                groups[entry.category]=groups[entry.category] or {}; table.insert(groups[entry.category],entry)
            end
        end
        local categories={}
        for category in pairs(groups) do categories[#categories+1]=category end
        table.sort(categories,function(a,b)
            local x,y=addon.currencyCategoryOrder[a] or 100,addon.currencyCategoryOrder[b] or 100
            return x==y and a<b or x<y
        end)
        local y,choiceCount,headingCount=0,0,0
        for _,category in ipairs(categories) do
            headingCount=headingCount+1
            local heading=headings[headingCount]
            if not heading then heading=Label(content,"GameFontNormal",0,0,500); headings[headingCount]=heading end
            heading:ClearAllPoints(); heading:SetPoint("TOPLEFT",0,-y); heading:SetText(category); heading:Show(); y=y+26
            table.sort(groups[category],function(a,b) return a.name<b.name end)
            for i,entry in ipairs(groups[category]) do
                choiceCount=choiceCount+1
                local choice=choices[choiceCount]
                if not choice then
                    choice=CreateFrame("Button",nil,content)
                    choice:SetSize(242,26)
                    choice.check=CreateFrame("CheckButton",nil,choice,"UICheckButtonTemplate")
                    choice.check:SetSize(26,26); choice.check:SetPoint("LEFT",0,0); choice.check:EnableMouse(false)
                    choice.icon=choice:CreateTexture(nil,"ARTWORK"); choice.icon:SetSize(18,18); choice.icon:SetPoint("LEFT",26,0)
                    choice.label=choice:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); choice.label:SetPoint("LEFT",48,0); choice.label:SetWidth(192); choice.label:SetJustifyH("LEFT"); choice.label:SetWordWrap(false)
                    choice.label:SetFont(addon.media.menuFont,11,"")
                    choice:SetScript("OnClick",function(self) Toggle(self.entry.id) end)
                    choice:SetScript("OnEnter",function(self)
                        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                        if self.entry.id>0 then GameTooltip:SetCurrencyByID(self.entry.id) else GameTooltip:SetText(self.entry.name,1,.82,0) end
                        GameTooltip:Show()
                    end)
                    choice:SetScript("OnLeave",function() GameTooltip:Hide() end)
                    choices[choiceCount]=choice
                end
                choice.entry=entry; choice.check:SetChecked(Position(entry.id)~=nil)
                choice:ClearAllPoints(); choice:SetPoint("TOPLEFT",((i-1)%2)*250,-y-math.floor((i-1)/2)*28)
                choice.icon:SetTexture(entry.icon); choice.label:SetText(entry.name); choice:Show()
            end
            y=y+math.ceil(#groups[category]/2)*28+12
        end
        for i=choiceCount+1,#choices do choices[i]:Hide() end
        for i=headingCount+1,#headings do headings[i]:Hide() end
        content:SetHeight(math.max(304,y))
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(),math.max(0,y-304)))
        local count=0
        for i,slot in ipairs(selectedSlots) do
            if list[i]~=0 then count=count+1 end
            slot.label:SetText(i..". "..(lookup[list[i]] and lookup[list[i]].name or list[i]==0 and addon.panelText.none or (fr and "Monnaie indisponible" or "Currency unavailable")))
        end
        summary:SetText((fr and "Ordre des lignes suivies · " or "Tracked row order · ")..count.." / 8")
    end
    search:SetScript("OnTextChanged",function(_,userInput) if userInput then scroll:SetVerticalScroll(0); window.update() end end)
    window:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    window:SetScript("OnEvent",function(self) if self:IsShown() then window.update() end end)
    window.update(); window:Show()
end

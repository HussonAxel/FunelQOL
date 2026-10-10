-- Exercise the real Content -> RaidSetContent -> RaidCollection boundary.
GetLocale=function() return "enUS" end
UnitClass=function() return "Warrior","WARRIOR",1 end
GetBuildInfo=function() return "12.1.0","","",120100 end
GetInstanceInfo=function() return "Test Raid","raid",15,"Heroic",nil,nil,nil,2912 end
C_Item={GetItemNameByID=function(id) return "Tier item "..id end,GetItemIconByID=function(id) return id end}
C_TransmogSets={
    GetSetInfo=function(id) return {setID=id,name="Test class set"} end,
    GetSourcesForSlot=function(_,slot)
        if slot==1 then return {{sourceID=101}} elseif slot==3 then return {{sourceID=102}} end
        return {}
    end,
}
C_TransmogCollection={
    GetSourceInfo=function(id) return {itemID=id,visualID=id,isCollected=id==102} end,
    GetAllAppearanceSources=function() return {} end,
}
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
local addon={panelText={},GetRaidSlotActions=function() return {},"unavailable",false end}
for _,file in ipairs({"Content.lua","RaidSetContent.lua","RaidCollection.lua"}) do assert(loadfile(file))("FunelQOL",addon) end
for _,difficulty in ipairs({14,15,16,17}) do
    GetInstanceInfo=function() return "Test Raid","raid",difficulty,"Difficulty",nil,nil,nil,2912 end
    local settings={content="raidcollection"}
    local rows=addon.GetPanelRows(settings)
    local piece
    for _,row in ipairs(rows) do if row.raidCollectionKind=="set" then piece=row end end
    assert(piece and piece.raidCollectionItemID==101,"Missing class piece lost at the real collection/set boundary")
    assert(not settings.selections,"Internal set selection leaks into the collection panel")
end
print("PASS: real raid collection/content/class-set integration across Normal, Heroic, Mythic and Raid Finder without nil selection keys.")

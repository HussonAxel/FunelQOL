local file=assert(io.open("tests/smoke.lua","r"))
local fixture=file:read("*a"); file:close()
assert(load(fixture .. [[
local function Deep(value)
    if type(value)~="table" then return value end
    local result={}; for key,entry in pairs(value) do result[key]=Deep(entry) end; return result
end
local function Character()
    local character={}
    for key,value in pairs(persistedAddon) do character[key]=value end
    assert(loadfile("Panels.lua"))("FunelQOL",character)
    character.InitializePanels()
    return character
end
-- Migrate a configured character, preserving its old saved-variable table.
FunelQOLCharDB=Deep(FunelQOLDB.panels)
FunelQOLCharDB.layouts[LEM.active].panel1.width=333
local legacy=FunelQOLCharDB
FunelQOLDB.panels=nil
local main=Character()
assert(main.panelDB==FunelQOLDB.panels and main.panelDB~=legacy)
assert(math.abs(main.panels[1].width-333)<1)
local count=#main.panels
-- Another character has incompatible personal settings; the account profile wins.
FunelQOLCharDB={panelCount=1,layouts={[LEM.active]={panel1={width=180}}}}
local altLegacy=FunelQOLCharDB
local alt=Character()
assert(alt.panelDB==main.panelDB and #alt.panels==count and math.abs(alt.panels[1].width-333)<1)
assert(alt.characterDB~=main.characterDB and alt.characterDB==altLegacy,"Character progress was shared")
assert(altLegacy.panelCount==1 and altLegacy.layouts[LEM.active].panel1.width==180)
FunelQOLDB.panels.layouts[LEM.active].panel1.width=360
alt.RefreshPanels(); assert(math.abs(alt.panels[1].width-360)<1)
assert(legacy.layouts[LEM.active].panel1.width==333)
print("PASS: shared panel configuration/count/layouts across characters, one-time migration and preserved legacy settings.")
]]))()

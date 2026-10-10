local file=assert(io.open("tests/smoke.lua","r"))
local fixture=file:read("*a"); file:close()
assert(load(fixture .. [=[
while #persistedAddon.panels<4 do persistedAddon.AddPanel() end
local db=FunelQOLDB.panels.layouts[LEM.active]
db.panel2.title="Delete me"; db.panel4.title="Keep me"
db.panel4.width=330; db.panel1.anchorTarget="panel4"
persistedAddon.RefreshPanels()
local survivingSettings=db.panel4
local third= persistedAddon.panels[3]
local button
for _, entry in ipairs(LEM.buttons[persistedAddon.panels[2]]) do
    if entry.text==persistedAddon.panelText.removeTracker then button=entry end
end
assert(button,"Missing selected tracker deletion button")
button.click(); assert(#persistedAddon.panels==4,"Deletion outside Edit Mode")
LEM.callbacks.enter()
combat=true; button.click(); assert(#persistedAddon.panels==4,"Deletion in combat")
combat=false; button.click()
assert(#persistedAddon.panels==3 and FunelQOLDB.panels.panelCount==3)
assert(db.panel2==survivingSettings and not db.panel4 and db.panel1.anchorTarget=="panel2")
assert(persistedAddon.panels[3]==third and db.panel2.title=="Keep me")
assert(persistedAddon.panels[1].point[2]==persistedAddon.panels[2],"Link to surviving tracker lost")
assert(persistedAddon.RemovePanel(1)==1)
assert(persistedAddon.RemovePanel(1)==1)
assert(#persistedAddon.panels==1 and not persistedAddon.RemovePanel(1))
LEM.callbacks.exit()
print("PASS: selected tracker delete button, middle/first deletion, survivor settings/link preservation, combat/edit guards and last tracker protection.")
]=]))()

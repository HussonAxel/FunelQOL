# FunelQOL

A personal quality-of-life addon for World of Warcraft Retail. Version 0.14.0 provides two configurable panels with live currencies, professions, selected talents, quest objectives, map events, daily delve stories and ratings, leveling delve quests, Great Vault, renown, raid appearance sets, and custom text rows. LibEditMode is bundled; no separate library addon is required.

## Installation

1. Put this repository's files in `_retail_/Interface/AddOns/FunelQOL/`. The folder must contain `FunelQOL.toc` directly, without another nested folder.
2. Restart WoW if it was running when the addon folder was created.
3. Enable **FunelQOL** in the character selection screen's **AddOns** list, then log in.
4. Type `/funelqol status` to check that the addon loaded.

When editing existing Lua files, use `/reload` to load changes.

## Commands

| Command | Action |
| --- | --- |
| `/funelqol` or `/funelqol help` | Show available commands. |
| `/funelqol status` | Show the version and login greeting setting. |
| `/funelqol greeting` | Toggle the greeting shown on login and UI reload. |
| `/funelqol edit` | Open Blizzard Edit Mode (outside combat). |
| `/funelqol content <1|2>` | Open the row editor for a panel in the current layout. |
| `/funelqol title <1|2> <text>` | Rename a panel in the current layout, e.g. `/funelqol title 1 Mon menu`. |

The greeting setting is account-wide and stored by WoW in `FunelQOLDB`. WoW writes saved settings on logout or UI reload.

## Panels and Blizzard Edit Mode

After login, **Panel 1** and **Panel 2** appear near the upper right of the screen. French clients show French panel titles and setting labels. Click a panel's header to collapse or expand it. Existing panels keep their **Preview** content until you choose another content type.

Open **Game Menu → Edit Mode** or `/funelqol edit`, then drag a FunelQOL panel to move it. Select the panel to choose its **Content** type and change its visibility, collapsed state, width (180–420), scale (70–150%), background opacity, text size (10–18), row height (22–34), preview row count (1–8), progress bar visibility, and appearance (**Blizzard**, **Ayije**, or **Pixels**). Hidden panels are shown while editing so they remain recoverable. The default Blizzard appearance uses built-in textures; import the local media before choosing Ayije or Pixels. Rename panel headers with `/funelqol title`.

Positions and settings are stored per character and per Blizzard layout name in `FunelQOLCharDB`. Copying, renaming, and deleting layouts also updates the addon settings. Addon adjustments are saved immediately in its own saved-variable data; Blizzard's Cancel button does not roll back FunelQOL adjustments. Logout or `/reload` writes them to disk.

### Configure panel content

1. Run `/reload`, then `/funelqol edit`.
2. Select a FunelQOL panel and choose **Content**: Preview, Currencies, Professions, Selected talents, Tracked quests, or Custom menu.
3. Click **Configure rows** (French: **Configurer les lignes**). You can also reopen this editor with `/funelqol content 1` or `/funelqol content 2`.
4. For currencies, check up to eight entries in the searchable two-column list, grouped by expansion/category with native icons. Other content uses dropdowns. Use **↑ / ↓** to reorder and **×** beside a selected row to remove it. Custom rows have label/value fields.
5. Close the editor and exit Edit Mode. Changes apply immediately; `/reload` saves them to disk.

Each content type keeps its own selection, so switching to Preview does not erase currencies or custom rows. The first use of a live content type selects up to three available entries. An empty selection shows a configuration hint.

Money uses coins sized to the value font, with no texture offsets and an inset from the right border. The full amount stays on one line; on narrow panels, its font shrinks independently to leave room for the label.

- **Currencies:** current wallet quantity, grouped seasonal Champion/Hero/Myth crests, and gold. Configure with icon/name checkboxes grouped by expansion/category; search by name or category. A client-data registry of 222 currencies in visible categories supplements Blizzard's currency list, so supported currencies can be selected before discovery. Selected currencies outside this registry are retained and resolved through the game API. No numeric entry is needed. The selected-order section supports moving/removing rows and Clear all; changes apply immediately. Seasonal total-earned caps are not shown as wallet goals.
- **Professions:** learned professions, including secondary professions, with their reported skill rank and maximum. The expansion skill-line name is used when available.
- **Selected talents:** a selection of talents from the active configuration, with icon, spell tooltip, and rank. Unselected talents and inactive hero-tree talents are hidden; their selections are retained for when they become active again. This is a read-only display, not a talent loadout switcher.
- **Tracked quests:** automatically follows **all watched quests** by default, including campaign quests and tracked world quests in watch order. **Show all tracked quests** overrides the old three-quest limit on existing layouts. Disable it to use **Automatic quest count** (1–8). Change **Show quest objectives** and **Maximum tracker height** (150–800, default 400) in Edit Mode. Use the mouse wheel over the panel to scroll when the content exceeds that height. Quest titles show an overall progress percentage, completed-objective counts, ready-to-turn-in or failed status; objective rows show live counts/progress bars and wrap long text. Completed quests include their hand-in instructions/NPC text, falling back to waypoint text or ready status. Active quests include waypoint instructions, unmet money requirements and quest timers when provided by the game. Optional objective wording is retained. Automatically completed quests offer a completion click outside combat. Hover for the full objectives; click a quest or objective to open quest details outside combat. Choosing, moving, or clearing an entry in **Configure rows** disables automatic tracking and uses your saved manual order (up to eight quests). Enable **Follow tracked quests automatically** to resume automatic tracking. Untracked quests disappear but their manual IDs are retained. Quests must be tracked through Blizzard's quest log; this panel is an additional display. The Blizzard tracker, scenarios, achievements, and quest-item buttons are unchanged.
  The tooltip and separate-row presentation show the API-reported type (Important, Campaign, Daily, Weekly, Recurring, Repeatable, World quest) and level beneath the title. Multiple labels can coexist. Borders are **blue** for daily/weekly/recurring/repeatable quests, **gold** for important quests, and **orange** for campaign quests. Recurrence takes priority over important/campaign border colors, while the text keeps all labels. The default **Group quest presentation** uses one category-colored border around each quest and its objectives, including Pixels/Ayije appearances. Titles occupy the full width in a larger font; ready quests use green titles, objectives use white text with indentation, and completed objectives use green. Ordinary count objectives and quest titles have no filled progress background. Actual progress objectives, timers and money requirements use thin bars. Repeated normal-quest/level metadata is kept in the tooltip; relevant category badges and nonzero progress appear on a smaller muted line. Turn off Group quest presentation in Edit Mode to restore the earlier separate-row presentation.

  Toggle **Show quest details** and **Color borders by quest type** independently in Edit Mode. Full metadata remains in the tooltip with details hidden. Types use Blizzard's quest frequency/important/world flags, campaign ID and campaign classification; unknown data is left unlabeled, and scheduler-reset quests are labeled recurring rather than assumed daily or weekly. The overall percentage is the mean of each objective's completion fraction (binary objectives use 0/100%; progress-bar objectives use their actual percentage). It is an addon summary, not a measure of time remaining or quest-chain completion. Ready-to-turn-in quests use 100% progress.
- **Custom menu:** up to eight static label/value rows (80 characters per field), such as notes or reminders. These rows do not execute scripts or actions.

Currency, money, skill, specialization, and talent events refresh the displayed values. The addon does not alter Blizzard's existing frames or create protected action buttons. Buffs, pets, scenarios, and achievement objectives are not connected yet.

### Sectioned objective tracker

Panels using **Tracked quests** now default to a continuous dark body with a single outer border and a separate compact header, matching the currency tracker shell. It separates **Campaign**, **Quests**, **World Quests**, and **Events**; empty sections disappear. Click a section heading to fold it independently. Fold states are saved per panel and Blizzard layout. Headings do not fold while Edit Mode is active.

Quest titles show an icon and use yellow for active quests or green for ready quests. The journal header or task map provides a blue zone line when available. Objectives remain white/green, with indented counters and thin progress bars; hand-in/waypoint instructions do not get an unfinished-objective dash. Relevant category badges and nonzero progress remain visible with quest details enabled. Category colors appear as a slim accent beside the quest title in this presentation.

**Show map events** uses Blizzard's dedicated `C_AreaPoiInfo.GetEventsForMap` list on the current zone and its parent maps, up to the continent. It shows current, unlocked events with their atlas icon, zone and available description; duplicate pins are removed. Clicking an event opens its map outside combat. It does not list all worldwide events or reproduce event widget progress, scenario criteria, achievements or quest-item action buttons. The Blizzard tracker still supplies those features.

In `/funelqol edit`, select the quest panel to toggle **Sectioned tracker presentation** (French: **Présentation du suivi en sections**) or **Show map events**. Disable the sectioned presentation to recover framed quest groups; disable **Group quest presentation** to recover separate objective rows. Width, font size, opacity, maximum tracker height and Pixels/Ayije/Blizzard borders remain configurable.

## Delves panel

After `/reload`, open `/funelqol edit`, select either panel and choose **Content → Delves**, just as you would select Currencies or Professions. This is independent panel content; no tab is added to the quest tracker. You can display Delves on one panel and quests/currencies on the other. It discovers available entrances on the Midnight continent (map 2537) and its child maps, even when the player is elsewhere.

The list separates **Bountiful**, **Normal**, and unknown-status delves using Blizzard's map atlas (`delves-bountiful` / `delves-regular`), excluding locked entrances. Repeated continent/zone pins are merged by identified delve, with the primary zone pin used for map clicks. This is the current character's visible map status, not an account-wide history of today's completed bountiful rewards.

Each entry displays its zone, detected active story, user-supplied reference time and a colored **S/A/B/C/D** grade beside its title. The bundled table contains all **44 rows across 12 delves** supplied by the user, with grades updated from the latest tier-table image (3 S, 13 A, 8 B, 13 C, 7 D). Previous reference times are retained because the image provides no times. `4.09.11` is normalized to `4:09.11`; route/guide labels and trailing spaces are removed. Times are reference values, not timed runs or predictions for the player's gear/tier. Hover for the full reference list; click to open the map outside combat.

Stories are read from visible text widgets in the map pin's tooltip/icon widget sets. Stable achievement criteria IDs match localized story names for verified entries. Unknown, hidden or conflicting stories display **?**; no grade is guessed from the delve's best variant. Only **Eggsplosive Growth** lacks a verified criterion mapping and matches the supplied English spelling only. Known spelling variants remain accepted, including **An Elementary Anditode**, **Basalisk Blitz** and **Why Did it Have to Be Snakes?**. **An Elementary Antidote** also matches **Academic Antitoxin**, the entrance/achievement name [reported for Collegiate Calamity](https://www.wowhead.com/achievement=61726/collegiate-calamity-stories). **Infiltrate and Ameliorate** matches its criterion listed as **Basilisk Blitz**, a naming discrepancy [acknowledged by Blizzard Customer Support](https://www.wowhead.com/achievement=61727/the-shadow-enclave-stories). These aliases are scoped to each delve, so Shadowguard Point's own Basilisk Blitz retains its separate C grade.

In Edit Mode, use **Bountiful delves only**, **Sort delves** (grade/time or name) and **Maximum delve tracker height**; abundant entries stay first. Delve groups fold independently, with state saved per panel/layout separately from quest sections. Width, text size, scrolling and theme controls apply. Map, relevant widget and achievement updates refresh the data; unrelated widgets do not rescan all maps. No manual row selection is required for Delves.

## Files and development

- `FunelQOL.toc`: addon metadata, supported interface version, saved variable declaration, and Lua file load order.
- `Core.lua`: addon namespace, saved setting initialization, login event handling, and slash commands.
- `PanelPreview.lua`: localized labels and static preview rows.
- `Content.lua`: live data providers and ordered selections.
- `QuestContent.lua`: tracked quest/world quest catalog and live objective rows.
- `TrackerContent.lua`: quest display metadata, section grouping/folding and current map events.
- `DelveRatings.lua`: user-supplied story grades/times and verified localization criteria IDs.
- `DelveContent.lua`: available Midnight delve discovery, bountiful status, story matching, sorting and tooltips.
- `ContentEditor.lua`: native row editor for selections, ordering, and custom text.
- `Panels.lua`: shared panel rendering and per-layout Edit Mode integration.
- `Media.lua`: local artwork catalog.

The addon targets retail interface `120100`, matching the installed 12.1.0 client at creation. After a game update, check `/dump select(4, GetBuildInfo())` in WoW and review API compatibility before updating the TOC's interface number.

New Lua files must be listed in `FunelQOL.toc` in their required load order. Each file can access the same private addon namespace with `local addonName, addon = ...`. Saved settings are available after this addon's `ADDON_LOADED` event; access them through `addon.db` after initialization.

## In-game smoke check

1. Log in: one FunelQOL greeting should appear.
2. Run `/funelqol`, `/funelqol status`, and `/funelqol unknown`: check help, status, and unknown-command feedback.
3. Run `/funelqol greeting`, then `/reload`: the greeting should stay disabled and status should report it as off.
4. Toggle the greeting again and reload: the greeting should return.
5. Check BugSack or enable Lua errors with `/console scriptErrors 1` to catch runtime errors.
6. Open `/funelqol edit`, move both panels, change their width/scale, hide one, then exit Edit Mode. Re-enter: the hidden panel must be selectable again.
7. Switch to another Blizzard layout, then return: the original positions and settings must return. Copy and rename a custom layout, then reload and verify the panels.
8. Toggle a header, rename it with `/funelqol title 1 Mon menu`, then reload: both the title and collapsed state must persist. Adjust text size, row height/count, opacity, and bar visibility.
9. Choose each content type, configure and reorder entries, change a currency/skill value, then reload and switch layouts to verify persistence. Verify currency and talent tooltips. For quests, compare a list longer than eight watched quests (including campaigns) with Blizzard, test scrolling and hand-in text, then track/untrack quests and world quests, complete an objective, test automatic/manual selection and quest detail clicks, verify daily/weekly/important/campaign labels and border colors across styles, then reload and switch layouts.
10. Select Ayije and Pixels appearances after importing media, and verify borders, bar fills, text alignment, and tooltips in-game.

The mocked Lua smoke check covers preview settings, live content and updates, seasonal currency caps, sparse profession slots, talent filtering, quest types, category border colors and hover restoration, grouped quest readability, full-width titles, compact metadata and preserved counters, partial objective progress, all-watch coverage, hand-in and waypoint text, auto-completion, money requirements, live timers, bounded scrolling, quest watch/progress/completion/loading states, wrapping and click guards, row editor selection/order/removal, custom text, reload persistence, layout isolation, hidden-frame recovery, and slash commands:

```powershell
npm exec --yes --package=fengari-node-cli -- fengari tests/smoke.lua
```

It does not run Blizzard's UI or verify visual rendering, dragging, or taint; those require the in-game checks above.

Pixels and Ayije borders use a separate edge-only frame above the fill, centered around the host with mirrored offsets snapped to physical pixels. The Ayije placement matches its native 16-unit edge with an 8-unit exterior offset; this also keeps corners from overlapping on short headers. Panel dimensions, row spacing, and icon geometry are snapped at the panel's effective scale; spacing accounts for each artwork's visible exterior edge. Geometry is recalculated when the UI scale, panel scale, or resolution changes. The regression check exercises 72 combinations of border style, screen resolution, UI scale, and panel scale; final texture rasterization still requires an in-game check.

## Custom media

`Media.lua` exposes locally imported EllesmereUI **Pixels** artwork through `addon.media`: three bar textures, two border styles with horizontal/vertical separators, and five shield textures. All paths point into FunelQOL, so EllesmereUI is not required at runtime after import.

To import or refresh from an installed EllesmereUI and, when present, AyijeUI, run PowerShell from this repository:

```powershell
.\tools\Import-Media.ps1
```

Example in another Lua file loaded after `Media.lua`:

```lua
local addonName, addon = ...
-- On an existing StatusBar:
bar:SetStatusBarTexture(addon.media.textures.pixelsFill)
-- On an existing frame created with BackdropTemplate:
frame:SetBackdrop({ edgeFile = addon.media.borders.pixels.edgeFile, edgeSize = 16 })
```

The imported TGA files retain their original names and bytes. `Media/Ellesmere/manifest.json` records their SHA256 hashes, and `LICENSE-source.txt` preserves the source license. Source: EllesmereUI 9.4; its changelog credits the PapaPixels collaboration for Pixels artwork. The supplied license reserves all rights and does not provide a redistribution grant. Imported media is excluded from Git and the public repository. A fresh clone must import its own local assets before using these paths.

AyijeUI 1.04 artwork is available locally through `addon.media.ayije`: 8 statusbar textures, 2 borders (with their original edge size of 16), 7 general textures, and 11 glyphs. Original filenames and folder structure are preserved under `Media/AyijeUI/`, alongside a SHA256 manifest and the source license. AyijeUI's supplied license reserves all rights and explicitly withholds copying and redistribution permissions; its imported files are excluded from the public repository as well. Fonts, logos, and addon code are not imported.

For example, use `bar:SetStatusBarTexture(addon.media.ayije.statusbars.Ayije_light)` or `frame:SetBackdrop(addon.media.ayije.borders.Ayije_Thin)` on a frame created with `BackdropTemplate`. General textures and glyphs can be assigned with `texture:SetTexture(addon.media.ayije.textures.portraitBorder)` or `texture:SetTexture(addon.media.ayije.glyphs.pixelClose)`.

To import AyijeUI alone, run `.\tools\Import-AyijeMedia.ps1`. The catalog lists the assets from the versions above; review it when updating the source addons. Choose the imported appearance in a panel's Edit Mode settings.

## References

- [World of Warcraft API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [TOC format](https://warcraft.wiki.gg/wiki/TOC_format)
- [Addon loading process](https://warcraft.wiki.gg/wiki/AddOn_loading_process)
- [Creating a slash command](https://warcraft.wiki.gg/wiki/Creating_a_slash_command)
- [LibEditMode documentation](https://github.com/p3lim-wow/LibEditMode/wiki)
- [Third-party notices](THIRD_PARTY.md)

API implementation references: [Blizzard currency documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua), [traits documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SharedTraitsDocumentation.lua), and [Blizzard professions book](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ProfessionsBook/Blizzard_ProfessionsBook.lua).

Quest references: [Blizzard quest API documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua) and [Blizzard quest objective tracker](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua).

Map-event reference: [Blizzard area POI API documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/AreaPoiInfoDocumentation.lua).

Delve references: [Blizzard delve map provider](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedMapDataProviders/DelveEntranceDataProvider.lua), [map legend atlas names](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/MapLegendFrame.lua), [UI widget API documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UIWidgetManagerDocumentation.lua), and the story-achievement game data on Wowhead ([61724](https://www.wowhead.com/achievement=61724), [61725](https://www.wowhead.com/achievement=61725), [61726](https://www.wowhead.com/achievement=61726), [61727](https://www.wowhead.com/achievement=61727), [61728](https://www.wowhead.com/achievement=61728), [61729](https://www.wowhead.com/achievement=61729), [61730](https://www.wowhead.com/achievement=61730), [61731](https://www.wowhead.com/achievement=61731), [61732](https://www.wowhead.com/achievement=61732), [61733](https://www.wowhead.com/achievement=61733), [63436](https://www.wowhead.com/achievement=63436), [63437](https://www.wowhead.com/achievement=63437)).

## Compact data trackers

Currencies, professions, selected talents and custom menus now use the supplied compact reference: a separate centered white header, a collapse arrow on the left, one dark body with thin row separators, uppercase labels and right-aligned values. Icons sit immediately before values; money uses its inline coins without a duplicate icon. Currency label/value colors use Blizzard's currency quality; professions are green, talents violet and custom text white. Currency quality comes from [Blizzard's CurrencyInfo structure](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua).

Default panel titles follow the selected content; personalized titles are retained. Width, font size, row height, scale, opacity and border theme remain configurable. Compact rows omit progress fills. Quest and delve trackers retain their detailed section presentation. The changes apply after `/reload` to existing panels as well as new ones.

The sectioned quest tracker also uses the compact shell: centered white uppercase panel title, left collapse arrow, right-side quest/event icons and neutral section separators. Quest titles keep their readable capitalization and completion/category colors; multiline objectives, zones, badges, timers and progress remain visible. Category accents retain their blue/gold/orange meaning. Quest groups share the body border and have thin separators. The detailed delve presentation and optional legacy quest presentations remain available.

## Great Vault and Midnight renown

After `/reload`, select a panel in `/funelqol edit` and choose **Content → Great Vault** or **Renown · Midnight** (French: **Chambre forte** / **Renoms · Midnight**). Both use the compact tracker surface. **Configure rows** selects/reorders Vault categories or renown factions, saved independently per panel/layout. Initial selections include all available categories/factions, up to the editor's eight selection slots; a Vault category renders all of its reward slots, including the ninth slot across three categories.

The Vault reads live activity thresholds and progress; it never assumes fixed seasonal counts. Each locked slot shows progress toward its threshold. Unlocked slots turn green and show the example reward item level when cached, otherwise **OK**. Hover for full progress, reward item level/link and slot details. An available reward adds a gold **Claim** row. Previous-period rewards are identified in the tooltip when Blizzard reports them. Concession rewards are excluded; the world/PvP category follows Blizzard's conditional display. Missing Vault data produces an unavailable message.

Renown is discovered through the Midnight expansion filter (11), without hardcoded faction names. Older and hidden factions are excluded; locked factions remain visible in gray with their unlock description. Each unlocked faction shows its renown level and percentage toward the next level, or **MAX** in green. Hover for exact reputation values. All current factions are initially selected rather than just three; selection/reorder remains available in the editor.

Weekly reward, reward item, faction reputation, renown level/unlock and login events refresh the panels. Reward item levels are shown only when Blizzard supplies them; no item level is calculated from a fixed table. These trackers read the active character's data. Mocked tests cover all Vault slots, live thresholds, missing item data/APIs, previous-period rewards, category filtering, current-expansion filtering, locked/max renown, saved layouts and compact rendering bounds; in-game appearance still needs validation.

Sources: [Blizzard weekly-reward API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/WeeklyRewardsDocumentation.lua), [Blizzard Vault display logic](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua), [Blizzard major-faction API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/MajorFactionsDocumentation.lua), [Blizzard item-level API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua). The providers live in `ProgressContent.lua`.

Renown rows use each faction's Blizzard emblem (`majorfactions_icons_<textureKit>512`), at 20 UI units with the full atlas visible. Row height and label/value spacing reserve room for the larger logo. Atlas availability is checked before applying it; missing faction art falls back to the reputation icon. The atlas is selected through faction data rather than localized faction names. Reference: [Blizzard Journeys faction icons](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_EncounterJournal/Mainline/Blizzard_Journeys.lua).

Renown emblems now occupy a fixed 20-unit column at the far right. Values share a right-aligned column immediately to its left, measured from the widest visible value; labels share the remaining width. All values use the same font size, reduced together if a narrow panel requires it. Fallback emblems reserve the same space.

## Delve leveling quest tracking

After `/reload`, select **Content → Delve quests** (French: **Quêtes de gouffres**) in `/funelqol edit`. The compact panel automatically lists all ten verified Midnight Delver's Call quests, including those outside the quest log. States are **Not accepted**, **In progress**, **Ready**, **Turned in**, **Failed**, or **Unknown** if status APIs are unavailable. **Hide turned-in quests** is saved independently per panel/layout. Hover shows the localized quest title, quest ID, zone and available objective text. Click an accepted quest to open its details outside combat/Edit Mode. Configure rows explains the automatic list; the eight-slot manual editor does not limit these ten entries.

The existing **Delves** content also displays **XP quest: <status>** below the variant/time metadata and includes the quest details in its tooltip. Story grades, bountiful classification and reference times remain independent of quest completion. No quest is accepted, watched or turned in automatically.

Completion uses the active character's `C_QuestLog.IsQuestFlaggedCompleted`, never account completion. Readiness requires the quest to be in the character's journal and complete; accepting, abandoning, turning in and quest-data updates refresh both panels. **Not accepted** means absent from the journal and not flagged complete; it does not claim that campaign/level prerequisites are satisfied. No fixed XP reward is displayed because it can depend on the character and bonuses.

Verified mapping from [Wowhead's Midnight Delver's Call quest database](https://www.wowhead.com/storyline/delvers-call-midnight-6051): Shadow Enclave 93372; Collegiate Calamity 93384; Darkway 93385; Parhelion Plaza 93386; Atal'Aman 93409; Twilight Crypts 93410; Gulf of Memory 93416; Grudge Pit 93421; Sunkiller Sanctum 93427; Shadowguard Point 93428. The two Coiled Isle delves have no verified quest mapping in this list, so no quest is invented for them. State APIs: [Blizzard quest-log documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua). Providers live in `DelveQuestContent.lua`; mappings are attached to `DelveRatings.lua` definitions.

### Seasonal raid appearance sets

After `/reload`, choose **Content → Raid sets** (French: **Contenu → Sets de raid**) in `/funelqol edit`. The compact panel displays Raid Finder, Normal, Heroic and Mythic by default, with collected appearance slots / total per difficulty. **Configure rows** selects and reorders difficulties independently per panel/layout. Completed variants turn green with a check icon. Hover a difficulty to see the localized set name, season, each available slot and its collected/missing state; cached item names are included when available.

This tracks the account's appearance collection for the active character's class. Learning the same visual through another item (including upgraded or catalyzed gear) counts as collected and is identified in the tooltip. It does not infer collection from bags, equipped gear or tier-bonus activation. Multiple sources for a slot count once; robes and chest armor share one slot. Slots absent from the set are excluded, so the denominator follows the actual set. Missing collection data displays a loading indicator instead of a false completion count.

Midnight Seasons 1 and 2 are supported for all 13 classes. The live `C_MythicPlus.GetCurrentSeason()` determines the season. While unavailable, the 12.0/12.1 client interface supplies the fallback; an unknown positive season ID explicitly shows unavailable rather than presenting old sets as current. Future seasons require new set IDs. Collection changes, login and season-map updates refresh the tracker.

The implementation was informed by the installed [Transmog Upgrade Master](https://www.curseforge.com/wow/addons/transmog-upgrade-master) v1.5.27: class/season/difficulty set IDs and checking other sources sharing an appearance. FunelQOL uses its own provider and renderer and requires no TUM dependency or media for collection tracking. Optional item-action analysis uses the installed TUM API. API references: [Blizzard transmog sets](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua) and [Blizzard appearance collection](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogItemsDocumentation.lua).

Mocked smoke checks cover class/difficulty mapping, season changes, shared appearances, duplicate-source and robe grouping, saved selections, collection events, loading/unsupported states, and compact bounds across the three styles. Live client appearance still needs validation.

**Automatic raid context (0.10.1):** **Follow current raid / Adapter au raid visité** is enabled by default in the panel's Edit Mode settings. While inside a raid, the panel tracks class sets whose client-localized raid label matches the visited instance. It includes their difficulty variants without changing wardrobe or Encounter Journal filters. Midnight's Voidspire, Dreamrift and March on Quel'Danas also use the shared Season 1 tier-set mapping; The Venomous Abyss uses Season 2. The client set-group labels were checked against [TransmogSetGroup data](https://wago.tools/db2/TransmogSetGroup), and Midnight game-map IDs against the installed BigWigs modules.

The automatic header shows the raid name unless you have set a custom title. `»` marks the current difficulty; its row stays visible even when that difficulty is absent from your saved selection. Old 10/25-player variants retain their localized descriptions and only the current size is marked. Leaving the raid (including entering a dungeon) restores the seasonal tracker and the saved difficulty selection. Turning the option off keeps seasonal tracking everywhere. A raid without an identifiable class set shows an explanatory row; it does not display an unrelated seasonal set. Some raid/class combinations have no wardrobe class set or no matching raid label, so automatic discovery cannot cover every raid.

Zone/login, collection and difficulty-change events update context and progression. Raid metadata is cached by instance/class and invalidated on zone/login and collection changes; collection state is read live. Additional smoke checks cover entry/exit, previous-season raids, localized metadata, class/PvP isolation, old raid sizes, cache reuse, selected/current difficulty behavior, opt-out and custom titles. In-game entry/exit and presentation still need validation. Sources: [Blizzard transmog set metadata](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua), [Blizzard wardrobe set labels and variants](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Collections/Shared/Blizzard_Wardrobe_Sets.lua).

### Linked panel anchors (0.11.0)

In `/funelqol edit`, select the panel that should follow another panel and choose **Anchor to / Ancrer à → Panel 1 or Panel 2**. Choose the target's side (**Below / Above / Left / Right**), **Alignment** (start, center, end), **Spacing** and an optional offset along the edge. Example: anchor panel 2 to panel 1, **Below**, **Start**, spacing **8**. The lower panel then follows the upper panel's bottom edge as either panel opens, closes or changes its content height. Merely placing two independent screen-anchored panels near one another does not create a link.

Left/right links support columns, and above/below links support stacks. Alignment start means left for stacks and top for columns; end means right/bottom. Offsets and spacing use UIParent units and are converted for the child panel's scale; final edges are snapped to the physical pixel grid. Linked panels remain relative to their target rather than being individually clamped to the screen. Move the free root panel to move the linked group.

Choose **Screen (free) / Écran (libre)** to release a link without a position jump. A free panel has nine **Screen anchor / Ancre écran** choices; changing this choice preserves its current position and determines which screen point owns future size changes. Dragging or nudging a linked panel in Edit Mode releases its link and saves the new free position. Anchors are independent per character/panel/Blizzard layout and copied with layouts. Self/mutual links are rejected; malformed saved cycles are repaired before being handed to the frame engine.

This uses the side-link, offset, dependency-order, scale-conversion and cycle-guard principles examined in the installed EllesmereUI `EUI_UnlockMode_Anchors.lua` / `EUI_UnlockMode_Positions.lua`, implemented independently for FunelQOL's existing Blizzard Edit Mode interface. EllesmereUI is not required. Tests resolve actual simulated frame rectangles to verify collapse/expand spacing, all 12 side/alignment combinations with different scales, cross-axis offsets, detach and screen-anchor continuity, drag unlinking and copied-layout isolation. Live Edit Mode presentation still needs in-game validation.

### Raid appearance actions and preview (0.12.0)

With Transmog Upgrade Master enabled, raid-set tooltips mark missing pieces according to the owned items that can lead to their appearance: **orange / upgrade icon** for upgrading, **purple / catalyst icon** for catalyzing, **yellow / both icons** for catalyzing and upgrading. Each route lists the actual item hyperlink, equipped/bag location and the current-to-required upgrade level when TUM supplies a seasonal breakpoint. A difficulty row adds the relevant action icons next to its existing collection count. Potential appearances never count as already collected. Already learned or shared appearances retain their collected state and show no action recommendation.

Version 0.12.1 spaces each appearance slot in a wider (420-unit) hover. The target piece's name is the heading, followed by each usable owned item's full hyperlink on its own line; method, upgrade breakpoint and inventory location appear underneath. Repeated method labels and summary icons are omitted from the hover. The width override is cleared on mouse leave, following [Blizzard's tooltip width pattern](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_InspectUI/Mists/InspectTalentFrame.lua). TUM remains the item-analysis source.

The scan covers this character's equipped items and carried bags; bank/warband/other-character inventories are not scanned. Identical item links are deduplicated. Upgrade-only results are matched to the target set's actual visual ID and slot, rather than inferred from an item's upgrade track. Catalyst routes use TUM's explicit class/season/difficulty mapping and result flags; PvP appearances and appearances already learned from another item are excluded. The indicators describe appearance paths, not affordability: catalyst charges, currencies and vendor availability are not checked. Hover names and methods explain the icons.

TUM is an optional dependency, loaded first when enabled. FunelQOL calls `TransmogUpgradeMaster_API.GetAppearanceMissingData` and checks `IsCacheWarmedUp`; the installed v1.5.27 core's class-set/source mappings supply the destination IDs. Its rules/media are not copied into FunelQOL. Without it, the existing collection tracker and preview continue to work, with a tooltip hint explaining how to enable item analysis. API incompatibility yields an incomplete-analysis message. Inventory results are cached and invalidated by bag/equipment/item-cache/collection/login events. Initial TUM cache loading is retried every two seconds only while a raid tracker requests pending analysis.

**Click a difficulty row to preview its complete outfit in Blizzard's dressing room**, including pieces you have not collected. One source per appearance slot is used, with robes grouped as chest armor. Preview clicks are ignored in combat and during Edit Mode. Reference: [Blizzard DressUpTransmogSet](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/DressUpFrames.lua). The action engine is in `RaidAppearanceActions.lua`; the public API contract was read from the installed TUM `api.lua`, with destination mapping verified against its `collectionUi.lua`.

Smoke tests cover all three paths and their object locations/levels, unrelated upgrade visuals, shared/PvP exclusions, collection counts, inventory invalidation, cache warmup, missing/incompatible TUM APIs, native inline icons at narrow widths, complete outfit preview and combat/Edit Mode guards. Actual items and dressing-room rendering still require in-game validation.

Menu headings, section titles and tracker row labels use bundled Noto Sans Bold (SIL Open Font License; see Media/Fonts/OFL.txt). Objective descriptions and numeric values retain their regular font.

Currencies include a selectable grouped Crests row (Champion / Hero / Myth), showing three native currency icons and spendable quantities. Hover lists localized currency names and earned caps when supplied by Blizzard. Midnight seasons 1 and 2 are supported; IDs were verified against [client CurrencyTypes data](https://wago.tools/db2/CurrencyTypes/csv), excluding hidden counters. Add it through Configure rows; existing selections are preserved.

Grouped crest icons use 20-unit artwork independent of the text size, with vertical padding. Narrow panels reduce text first, then icons to a minimum of 16 units and tighten spacing if necessary.

Version 0.12.5 renders grouped crest icons as separate textures centered on their row, with four units of vertical padding per side. Quantities use separate measured font strings. This avoids font-baseline overflow from inline artwork; reusable widgets are hidden when a row changes content. Narrow panels tighten group spacing before reducing artwork size.

Panel collapse controls use a custom two-stroke green chevron in a fixed square frame, facing right when closed and down when open, with a white hover state. The artwork is independent of font metrics and replaces the scroll-button texture and text symbols.

### Transparent backgrounds and compact progress (0.13.0)

Background opacity defaults to 80%. Existing per-layout panel settings migrate once to 80%, then later user opacity adjustments are preserved. Borders, icons and text retain their opacity. Compact rows now show subtle tinted background gauges for renown toward the next level (full at maximum, absent for locked/unknown factions), class raid-set collection, profession skill and each Great Vault activity threshold. Counts and reward item levels remain visible, and the current linear Vault layout is retained. These gauges respect the existing Show bars setting in Edit Mode; balance-only currencies, grouped crests, money, talents and custom text do not acquire artificial progress goals. Unknown raid collection data has no gauge.

Verified against the supplied video reference, with smoke checks covering migration, subsequent opacity edits, renown states, bounds across all styles, toggles, other providers and exclusions. In-game visual validation remains necessary.

Version 0.13.1 removes inner padding from compact progress gauges so their fill covers the complete row. Text and icon padding remains in place.

### Visual currency selection (0.14.0)

The currency editor follows the supplied video: a scrollable two-column list of native currency icons, localized names and checkboxes, grouped by expansion/category, plus search and a selected-row ordering section. Existing choices are retained, duplicate choices are consolidated, selection is limited to eight rows per panel, and settings remain independent per panel/layout. Numeric IDs remain internal stable keys; manual numeric entry is removed. CurrencyCatalog.lua contains visible-category ID facts from [CurrencyTypes](https://wago.tools/db2/CurrencyTypes/csv) and [CurrencyCategory](https://wago.tools/db2/CurrencyCategory/csv), excluding hidden/test/debug categories. Names, quantities and icons come from [Blizzard's currency API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua); registry entries with no current client data are omitted. Native-list and previously selected currencies supplement the registry. Full catalogue scans happen in configuration, while live panel refreshes resolve selected currencies only. Tests cover selection, filtering, capacity, zero balances before discovery, order/removal/clear, saved choices, frame reuse and refresh cost. Final widget rendering requires in-game validation.

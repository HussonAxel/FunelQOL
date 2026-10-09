# FunelQOL

A personal quality-of-life addon for World of Warcraft Retail. Version 0.8.2 provides two configurable panels with live currencies, professions, selected talents, quest objectives, map events, daily delve stories and ratings, and custom text rows. LibEditMode is bundled; no separate library addon is required.

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
4. Choose up to eight entries with the dropdowns. Use **↑ / ↓** to reorder them and **×** beside a row to remove it. Custom rows have a label and a value field instead of a dropdown.
5. Close the editor and exit Edit Mode. Changes apply immediately; `/reload` saves them to disk.

Each content type keeps its own selection, so switching to Preview does not erase currencies or custom rows. The first use of a live content type selects up to three available entries. An empty selection shows a configuration hint.

Money uses coins sized to the value font, with no texture offsets and an inset from the right border. The full amount stays on one line; on narrow panels, its font shrinks independently to leave room for the label.

- **Currencies:** current wallet quantity, optional wallet-cap bar, and gold. Seasonal total-earned caps are not displayed as wallet-cap bars. The dropdown reflects the visible Blizzard currency list: expand categories in the character currency tab and reopen the editor to expose more entries. You can also enter a numeric currency ID at the bottom of the editor. Selected currencies remain readable when their category is collapsed.
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

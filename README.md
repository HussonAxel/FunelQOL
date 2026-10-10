# FunelQOL

A personal quality-of-life addon for World of Warcraft Retail. Version 0.18.12 provides configurable panels (two by default, more on demand) with live currencies, professions, quest objectives, map events, daily delve stories and ratings, leveling delve quests, Great Vault, renown, a weekly tracker, current-zone rares with their collectible rewards, owned teleports, raid appearance sets, and custom text rows. LibEditMode is bundled; no separate library addon is required.

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
| `/funelqol perf start <label>` / `stop` | Capture native CPU metrics and memory before/after a gameplay scenario. |
| `/funelqol perf report` | Show the last recorded performance scenario. |
| `/funelqol perf bench [1-20]` | Measure full panel refresh time and allocations outside combat (default: 5 calls). |
| `/funelqol edit` | Open Blizzard Edit Mode (outside combat). |
| `/funelqol content <number>` | Open the row editor for a panel in the current layout. |
| `/funelqol title <number> <text>` | Rename a panel in the current layout, e.g. `/funelqol title 1 Mon menu`. |
| `/funelqol add` | Create a new panel (Panel 3, Panel 4, …). |
| `/funelqol remove` | Delete the highest-numbered panel and its settings in every layout. At least one panel remains. |
| `/funelqol rotation` | Toggle the Blizzard rotation suggestion button in the current layout. |
| `/funelqol rotation status` | Report recommendation availability, spell ID, texture, keybind and Edit Mode state. |
| `/funelqol raidsets status` | Re-scan equipped waist, wrists and feet; report source, season, upgrade rank, native eligibility, Mythic destination and scanner errors. Saves the latest report in `FunelQOLDB.raidActionsDiagnostic`. |

The greeting setting is account-wide and stored by WoW in `FunelQOLDB`. WoW writes saved settings on logout or UI reload.

Performance commands run only on demand, using `C_AddOnProfiler` without changing `scriptProfile`. The last ten scenarios are saved in `FunelQOLDB.performance`. See [the performance audit and in-game protocol](docs/performance-audit.md) for local before/after results, limitations and reproducible tests (`python tools/Run-Tests.py`, requires lupa).

## Rare map markers

The world map displays known rare locations from the same lazily loaded database as the rare tracker, for the zone being viewed. Pins have no added border and use RefineUI names above their icons, with the locally imported font when RefineUI is disabled. Click a pin to set a tracked waypoint. Friendly rares are excluded; defeated rares are faded and can be hidden. These are known locations, not live spawn detections. Missing kill data remains unknown.

Open the map tracking/filter menu and choose **FunelQOL · Rares** to toggle markers, names and defeated rares, or change icon/name sizes. Settings are shared across characters. Pins use Blizzard's map canvas pools and follow map zoom/panning. Quest/achievement changes are coalesced while the map is open; no events are watched for this feature while the map is closed or markers are disabled. Map markers do not scan or request item rewards. Continents and other maps without coordinates in the database show no added pins.

## Blizzard rotation suggestion

Missing or question-mark spell textures are retried and spell data is requested once per changed recommendation. `SPELL_DATA_LOAD_RESULT` refreshes the current icon immediately. `/funelqol rotation status` helps distinguish missing spell data from an unavailable or protected recommendation.

A standalone action-bar-sized indicator displays `C_AssistedCombat.GetNextCastSpell(false)` with its action-bar keybind. Since 0.18.9 it matches RefineUI action buttons: 1-unit icon inset without a dark background, RefineUI's grey 12-unit border reaching 4 units outside the icon (gold on hover), and the keybind at the top right in ITC Avant Garde Bold with an outline. It uses RefineUI's own template and font when RefineUI is enabled, otherwise the local copies imported by `tools/Import-RefineMedia.ps1` (ITC Avant Garde Bold falls back to Expressway). The recommendation comes entirely from Blizzard; press the displayed key on your existing action bar to cast. This indicator does not cast on click.

Select **FunelQOL · Blizzard rotation / FunelQOL · Rotation Blizzard** in Edit Mode to move it, toggle it or adjust button/keybind size. Its settings are shared across characters per layout, including layout copy/rename/delete, and it supports RefineUI global anchors. It hides when no recommendation is available, but remains visible while editing. `/funelqol rotation` also toggles it.

Keybinds are read from Blizzard's eight action bars, including identifiable macro spells and base/override spell variants, preferring visible bars. A dash means no matching bound action was found. Bindings are cached until action/binding/spec changes; recommendations refresh at most ten times per second while a target exists or the player is in combat, plus relevant events. There is no continuous update without a target/combat or while disabled/unavailable. Secret spell IDs are skipped safely. Third-party action-bar binding support is not included. Automated tests cover recommendation changes, bindings/macros, cache invalidation, idle behavior and layouts; actual client rendering/recommendation availability requires in-game validation.

When you try to cast a spell that is still on cooldown, its icon appears to the right of the rotation button with a cooldown swipe and countdown. It stays visible until the spell returns, shows **Prêt / Ready** for two seconds, then hides. The alert follows the rotation button's position and size, works without a target or recommendation, and is disabled with the rotation button. It displays the most recently attempted unavailable spell; global cooldowns alone do not trigger it. Failed player casts and cooldown errors from identifiable action-bar spells/macros are supported. Midnight duration objects are passed directly to Blizzard's widget without reading protected timestamps. Live-client validation with your keybinds/macros is still required.

## Panels and Blizzard Edit Mode

After login, two panels appear near the upper right of the screen. Create as many extra panels as you need with `/funelqol add`; they appear to the left of the existing ones and can be moved, configured and linked like the first two. The panel count is shared across all characters on the account. French clients show French panel titles and setting labels. Click a panel's header to collapse or expand it. Existing panels keep their **Preview** content until you choose another content type.

Headers and Edit Mode names automatically follow the selected content, including Preview and all quest display modes. Raid trackers retain their contextual raid name, and rares use the current zone name. Old generic `PANEL N` / `PANNEAU N` names remain automatic across language changes and slot renumbering. Titles set with `/funelqol title` are preserved when the content changes.

Right-click a tracker header to choose its content: currencies, professions, quests, Delves, Great Vault, rares and the other available trackers. The current content is checked, and the selection applies immediately to that panel in the active layout. Left-click still collapses or expands the tracker.

Trackers use the `HIGH` frame strata at level 100; their headers, rows and borders inherit that priority over ordinary HUD bars, including the XP bar. Native dialog/menu and tooltip strata remain above them.

Compact row icons use larger square dimensions (up to 20 UI units, with padding inside the row), rounded to even physical pixels and anchored on the pixel grid. Regular 64×64 icons sample the central 56×56 texels; faction atlases keep their native full coordinates. Icon columns remain reserved on rows without icons. Weekly key fragments use an explicitly sized square inline icon rather than inheriting the counter font size.

Appearance is shared by all trackers within each Edit Mode layout: width, scale, text size, row height, theme and background opacity. Changing one of these controls updates every tracker immediately. Existing layouts are aligned once to their first panel's appearance; new trackers inherit it. Content, positions, anchors, visibility, folding and progress-bar toggles remain per tracker. Compact trackers reserve the same icon space and a common minimum value-column width, so rows with and without icons align. Long amounts may use more space to remain readable; content colors and specialized quest/reward layouts are retained.

RefineUI row/section separators and scroll boundaries sample the horizontal edge of `RefineBorder.blp`, with the same thickness and tint as the outer frame. Reward tiles also use that border texture, including rare rewards, with extra grid spacing for the border artwork. Switching themes restores each theme's separator and reward-border rendering.

You can also create trackers directly from **Game Menu → Edit Mode**: select any FunelQOL panel and click **Add tracker** (**Ajouter un tracker** in French). The new panel appears immediately; select it to choose its content and position. No slash command is required.

To remove a tracker, select it in Edit Mode and click **Delete this tracker / Supprimer ce tracker**. This removes that tracker across the shared account layouts. Other trackers retain their configuration; numbered slots are compacted by moving the last tracker into the removed slot. Links to the removed tracker are released, and links to surviving trackers are retained. At least one tracker remains. Deletion is unavailable in combat.

Open **Game Menu → Edit Mode** or `/funelqol edit`, then drag a FunelQOL panel to move it. Select the panel to choose its **Content** type and change its visibility, collapsed state, width (180–420), scale (70–150%), background opacity, text size (10–18), row height (22–34), preview row count (1–8), progress bar visibility, and appearance (**Blizzard**, **Ayije**, or **Pixels**). Hidden panels are shown while editing so they remain recoverable. Panels use the **Pixels** appearance by default (its media ships in `Media/Ellesmere`); existing panels that still had the former Blizzard default switch to Pixels once, and any style you choose afterwards is kept. Blizzard uses built-in textures; import the local media before choosing Ayije. Rename panel headers with `/funelqol title`.

Positions, content selections, appearance and panel count are shared across characters in `FunelQOLDB.panels`, with separate settings per Blizzard layout name. The first character loaded after this update seeds the shared configuration; its legacy `FunelQOLCharDB` settings are preserved. Select the same account-wide Edit Mode layout on each character to use the same panels. Weekly gameplay memory remains per character. Copying, renaming, and deleting layouts also updates the addon settings. Addon adjustments are saved immediately in its own saved-variable data; Blizzard's Cancel button does not roll back FunelQOL adjustments. Logout or `/reload` writes them to disk.

Screen-anchored trackers keep their title at the same position when collapsed, expanded or resized by their content, including center and bottom screen anchors. Dragging or changing the screen anchor establishes a new reference position. Trackers linked to another panel continue to follow that panel's chosen edge.

### Configure panel content

1. Run `/reload`, then `/funelqol edit`.
2. Select a FunelQOL panel and choose **Content**: Preview, Currencies, Professions, Tracked quests, or Custom menu.
3. Click **Configure rows** (French: **Configurer les lignes**). You can also reopen this editor with `/funelqol content <number>`, e.g. `/funelqol content 3`.
4. For currencies, check up to eight entries in the searchable two-column list, grouped by expansion/category with native icons. Other content uses dropdowns. Use **↑ / ↓** to reorder and **×** beside a selected row to remove it. Custom rows have label/value fields.
5. Close the editor and exit Edit Mode. Changes apply immediately; `/reload` saves them to disk.

Each content type keeps its own selection, so switching to Preview does not erase currencies or custom rows. The first use of a live content type selects up to three available entries. An empty selection shows a configuration hint.

Money uses coins sized to the value font, with no texture offsets and an inset from the right border. The full amount stays on one line; on narrow panels, its font shrinks independently to leave room for the label.

- **Currencies:** current wallet quantity, grouped seasonal Champion/Hero/Myth crests, and gold. Configure with icon/name checkboxes grouped by expansion/category; search by name or category. A client-data registry of 222 currencies in visible categories supplements Blizzard's currency list, so supported currencies can be selected before discovery. Selected currencies outside this registry are retained and resolved through the game API. No numeric entry is needed. The selected-order section supports moving/removing rows and Clear all; changes apply immediately. Seasonal total-earned caps are not shown as wallet goals.
- **Professions:** learned professions, including secondary professions, with their reported skill rank and maximum. The expansion skill-line name is used when available.
- **Tracked quests:** automatically follows **all watched quests** by default, including campaign quests and tracked world quests in watch order. **Show all tracked quests** overrides the old three-quest limit on existing layouts. Disable it to use **Automatic quest count** (1–8). Change **Show quest objectives** and **Maximum tracker height** (150–800, default 400) in Edit Mode. Use the mouse wheel over the panel to scroll when the content exceeds that height. Quest titles show an overall progress percentage, completed-objective counts, ready-to-turn-in or failed status; objective rows show live counts/progress bars and wrap long text. Completed quests include their hand-in instructions/NPC text, falling back to waypoint text or ready status. Active quests include waypoint instructions, unmet money requirements and quest timers when provided by the game. Optional objective wording is retained. Automatically completed quests offer a completion click outside combat. Hover for the full objectives; click a quest or objective to open quest details outside combat. Choosing, moving, or clearing an entry in **Configure rows** disables automatic tracking and uses your saved manual order (up to eight quests). Enable **Follow tracked quests automatically** to resume automatic tracking. Untracked quests disappear but their manual IDs are retained. Quests must be tracked through Blizzard's quest log; this panel is an additional display. The Blizzard tracker, scenarios, achievements, and quest-item buttons are unchanged.
  The tooltip and separate-row presentation show the API-reported type (Important, Campaign, Daily, Weekly, Recurring, Repeatable, World quest) and level beneath the title. Multiple labels can coexist. Borders are **blue** for daily/weekly/recurring/repeatable quests, **gold** for important quests, and **orange** for campaign quests. Recurrence takes priority over important/campaign border colors, while the text keeps all labels. The default **Group quest presentation** uses one category-colored border around each quest and its objectives, including Pixels/Ayije appearances. Titles occupy the full width in a larger font; ready quests use green titles, objectives use white text with indentation, and completed objectives use green. Ordinary count objectives and quest titles have no filled progress background. Actual progress objectives, timers and money requirements use thin bars. Repeated normal-quest/level metadata is kept in the tooltip; relevant category badges and nonzero progress appear on a smaller muted line. Turn off Group quest presentation in Edit Mode to restore the earlier separate-row presentation.

  Toggle **Show quest details** and **Color borders by quest type** independently in Edit Mode. Full metadata remains in the tooltip with details hidden. Types use Blizzard's quest frequency/important/world flags, campaign ID and campaign classification; unknown data is left unlabeled, and scheduler-reset quests are labeled recurring rather than assumed daily or weekly. The overall percentage is the mean of each objective's completion fraction (binary objectives use 0/100%; progress-bar objectives use their actual percentage). It is an addon summary, not a measure of time remaining or quest-chain completion. Ready-to-turn-in quests use 100% progress.
- **Custom menu:** up to eight static label/value rows (80 characters per field), such as notes or reminders. These rows do not execute scripts or actions.

Currency, money, skill, and specialization events refresh the displayed values. The addon does not alter Blizzard's existing frames or create protected action buttons. Buffs, pets, scenarios, and achievement objectives are not connected yet.

### Sectioned objective tracker

Panels using **Tracked quests** now default to a continuous dark body with a single outer border and a separate compact header, matching the currency tracker shell. It separates **Campaign**, **Quests**, **World Quests**, and **Events**; empty sections disappear. Click a section heading to fold it independently. Fold states are saved per panel and Blizzard layout. Headings do not fold while Edit Mode is active.

Quest titles show an icon and use yellow for active quests or green for ready quests. The journal header or task map provides a blue zone line when available. Objectives remain white/green, with indented counters and thin progress bars; hand-in/waypoint instructions do not get an unfinished-objective dash. Relevant category badges and nonzero progress remain visible with quest details enabled. Category colors appear as a slim accent beside the quest title in this presentation.

**Show map events** uses Blizzard's dedicated `C_AreaPoiInfo.GetEventsForMap` list on the current zone and its parent maps, up to the continent. It shows current, unlocked events with their atlas icon, zone and available description; duplicate pins are removed. Clicking an event opens its map outside combat. It does not list all worldwide events or reproduce event widget progress, scenario criteria, achievements or quest-item action buttons. The Blizzard tracker still supplies those features.

In `/funelqol edit`, select the quest panel to toggle **Sectioned tracker presentation** (French: **Présentation du suivi en sections**) or **Show map events**. Disable the sectioned presentation to recover framed quest groups; disable **Group quest presentation** to recover separate objective rows. Width, font size, opacity, maximum tracker height and Pixels/Ayije/Blizzard borders remain configurable.

## Delves panel

After `/reload`, open `/funelqol edit`, select any panel and choose **Content → Delves**, just as you would select Currencies or Professions. This is independent panel content; no tab is added to the quest tracker. You can display Delves on one panel and quests/currencies on another. It discovers available entrances on the Midnight continent (map 2537) and its child maps, even when the player is elsewhere.

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
- `RowActions.lua`: right-click actions shared by tracked rows (waypoints, quest tracking, professions, currencies, Great Vault).
- `TeleportContent.lua`: owned teleport items, toys and known teleport spells, grouped by category as icon grids with cooldowns (data from the generated, Git-ignored `TeleportData.lua`).
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
9. Choose each content type, configure and reorder entries, change a currency/skill value, then reload and switch layouts to verify persistence. Verify currency tooltips. For quests, compare a list longer than eight watched quests (including campaigns) with Blizzard, test scrolling and hand-in text, then track/untrack quests and world quests, complete an objective, test automatic/manual selection and quest detail clicks, verify daily/weekly/important/campaign labels and border colors across styles, then reload and switch layouts.
10. Select Ayije and Pixels appearances after importing media, and verify borders, bar fills, text alignment, and tooltips in-game.

The mocked Lua smoke check covers preview settings, live content and updates, seasonal currency caps, sparse profession slots, quest types, category border colors and hover restoration, grouped quest readability, full-width titles, compact metadata and preserved counters, partial objective progress, all-watch coverage, hand-in and waypoint text, auto-completion, money requirements, live timers, bounded scrolling, quest watch/progress/completion/loading states, wrapping and click guards, row editor selection/order/removal, custom text, reload persistence, layout isolation, hidden-frame recovery, and slash commands:

```powershell
npm exec --yes --package=fengari-node-cli -- fengari tests/smoke.lua
```

It does not run Blizzard's UI or verify visual rendering, dragging, or taint; those require the in-game checks above.

Pixels and Ayije borders use a separate edge-only frame above the fill, centered around the host with mirrored offsets snapped to physical pixels. The Ayije placement matches its native 16-unit edge with an 8-unit exterior offset; this also keeps corners from overlapping on short headers. Panel dimensions, row spacing, and icon geometry are snapped at the panel's effective scale; spacing accounts for each artwork's visible exterior edge. Geometry is recalculated when the UI scale, panel scale, or resolution changes. The regression check exercises 72 combinations of border style, screen resolution, UI scale, and panel scale; final texture rasterization still requires an in-game check.

## Custom media

**RefineUI** is also available in each tracker's **Edit Mode → Appearance** dropdown. It uses RefineUI's 12-unit border, dark-tinted SmoothV2 background, gold hover accents and ITC Avant Garde Demi font. Pixels uses pixels-bg for the dark-tinted background. Since 0.18.12 every style fills progress bars with the d1 texture in `Media/Bars`, which is also RefineUI's default bar texture; `tools/Sync-BarTexture.ps1` copies it into RefineUI's `Media/Textures`. Backgrounds default to full opacity; progress colours are displayed at full strength, above the background and below labels/icons. Opacity and text size remain configurable per tracker. The local copies in `Media/RefineUI` work with RefineUI disabled; refresh them with `tools/Import-RefineMedia.ps1` (also called by the main importer when RefineUI is installed). Switching back restores the other style's font and background. Editors retain Expressway.

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

Currencies, professions and custom menus now use the supplied compact reference: a separate centered white header, a collapse arrow on the left, one dark body with thin row separators, uppercase labels and right-aligned values. Icons sit immediately before values; money uses its inline coins without a duplicate icon. Currency label/value colors use Blizzard's currency quality; professions are green and custom text white. Currency quality comes from [Blizzard's CurrencyInfo structure](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua).

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

FunelQOL uses its own provider, renderer and native item-action analysis. Transmog Upgrade Master is not required for collection tracking, upgrade/catalyst recommendations or previews. API references: [Blizzard transmog sets](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua) and [Blizzard appearance collection](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogItemsDocumentation.lua).

Mocked smoke checks cover class/difficulty mapping, season changes, shared appearances, duplicate-source and robe grouping, saved selections, collection events, loading/unsupported states, and compact bounds across the three styles. Live client appearance still needs validation.

**Automatic raid context (0.10.1):** **Follow current raid / Adapter au raid visité** is enabled by default in the panel's Edit Mode settings. While inside a raid, the panel tracks class sets whose client-localized raid label matches the visited instance. It includes their difficulty variants without changing wardrobe or Encounter Journal filters. Midnight's Voidspire, Dreamrift and March on Quel'Danas also use the shared Season 1 tier-set mapping; The Venomous Abyss uses Season 2. The client set-group labels were checked against [TransmogSetGroup data](https://wago.tools/db2/TransmogSetGroup), and Midnight game-map IDs against the installed BigWigs modules.

The automatic header shows the raid name unless you have set a custom title. `»` marks the current difficulty; its row stays visible even when that difficulty is absent from your saved selection. Old 10/25-player variants retain their localized descriptions and only the current size is marked. Leaving the raid (including entering a dungeon) restores the seasonal tracker and the saved difficulty selection. Turning the option off keeps seasonal tracking everywhere. A raid without an identifiable class set shows an explanatory row; it does not display an unrelated seasonal set. Some raid/class combinations have no wardrobe class set or no matching raid label, so automatic discovery cannot cover every raid.

Zone/login, collection and difficulty-change events update context and progression. Raid metadata is cached by instance/class and invalidated on zone/login and collection changes; collection state is read live. Additional smoke checks cover entry/exit, previous-season raids, localized metadata, class/PvP isolation, old raid sizes, cache reuse, selected/current difficulty behavior, opt-out and custom titles. In-game entry/exit and presentation still need validation. Sources: [Blizzard transmog set metadata](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua), [Blizzard wardrobe set labels and variants](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Collections/Shared/Blizzard_Wardrobe_Sets.lua).

### Linked panel anchors (0.11.0)

With RefineUI installed, trackers also expose **Ancrage global / Anchor to** and its side, alignment, spacing and offset controls. These link a tracker to any discovered Blizzard or RefineUI Edit Mode element. Global links are stored by RefineUI across characters and per layout; selecting one releases the tracker's panel-only link. Dragging releases the global link, and removed trackers disappear from global target lists.

Tracker redraws preserve active global links and refresh them synchronously, so opening or closing a tracker does not briefly restore its previous screen position. Free trackers retain FunelQOL's own screen-position handling.

In `/funelqol edit`, select the panel that should follow another panel and choose **Anchor to / Ancrer à → any other panel** (Panel 1, Panel 2, Panel 3, …). Choose the target's side (**Below / Above / Left / Right**), **Alignment** (start, center, end), **Spacing** and an optional offset along the edge. Example: anchor panel 2 to panel 1, **Below**, **Start**, spacing **8**. The lower panel then follows the upper panel's bottom edge as either panel opens, closes or changes its content height. Merely placing two independent screen-anchored panels near one another does not create a link.

Left/right links support columns, and above/below links support stacks. Alignment start means left for stacks and top for columns; end means right/bottom. Offsets and spacing use UIParent units and are converted for the child panel's scale; final edges are snapped to the physical pixel grid. Linked panels remain relative to their target rather than being individually clamped to the screen. Move the free root panel to move the linked group.

Choose **Screen (free) / Écran (libre)** to release a link without a position jump. A free panel has nine **Screen anchor / Ancre écran** choices; changing this choice preserves its current position and determines which screen point owns future size changes. Dragging or nudging a linked panel in Edit Mode releases its link and saves the new free position. Anchors are independent per panel/Blizzard layout across characters and copied with layouts. Self/mutual links are rejected; malformed saved cycles are repaired before being handed to the frame engine.

This uses the side-link, offset, dependency-order, scale-conversion and cycle-guard principles examined in the installed EllesmereUI `EUI_UnlockMode_Anchors.lua` / `EUI_UnlockMode_Positions.lua`, implemented independently for FunelQOL's existing Blizzard Edit Mode interface. EllesmereUI is not required. Tests resolve actual simulated frame rectangles to verify collapse/expand spacing, all 12 side/alignment combinations with different scales, cross-axis offsets, detach and screen-anchor continuity, drag unlinking and copied-layout isolation. Live Edit Mode presentation still needs in-game validation.

### Raid appearance actions and preview (0.12.0)

Raid-set tooltips mark missing pieces according to the owned items that can lead to their appearance: **orange / upgrade icon** for upgrading, **purple / catalyst icon** for catalyzing, **yellow / both icons** for catalyzing and upgrading. Each route lists the actual item hyperlink, equipped/bag location and current-to-required upgrade level. A difficulty row adds the relevant action icons next to its existing collection count. Potential appearances never count as already collected. Already learned or shared appearances retain their collected state and show no action recommendation.

Each appearance slot uses a wider (420-unit) hover. The target piece's name is the heading, followed by each usable owned item's full hyperlink on its own line; method, upgrade breakpoint and inventory location appear underneath. Repeated method labels and summary icons are omitted from the hover. The width override is cleared on mouse leave, following [Blizzard's tooltip width pattern](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_InspectUI/Mists/InspectTalentFrame.lua).

The scan covers this character's equipped armor and carried bags; bank/warband/other-character inventories and tier tokens are not analyzed. Identical item links are deduplicated. Upgrade-only results require a matching item among the destination appearance's native sources and the correct slot/track. Native APIs provide upgrade levels and upgrade/catalyst eligibility; destination sets are inferred from FunelQOL's class/season/difficulty rules, not returned directly by the catalyst API. Analysis supports Midnight seasons 1 and 2, with an appearance breakpoint at rank 6. Season identification uses the item's seasonal bonus or actual tier-set appearance membership. Unknown seasons/tracks are omitted conservatively. Conquest PvP gear and appearances already learned through another source are excluded. The indicators describe appearance paths, not affordability: catalyst charges, currencies and vendor availability are not checked.

The action engine calls Blizzard's `C_Item.GetItemUpgradeInfo`, `C_ItemUpgrade.CanUpgradeItem`, `C_Item.IsItemConvertibleAndValidForPlayer` and appearance-collection APIs. No third-party addon API or media is used. Missing native APIs yield an unavailable-analysis message; an item-analysis error is reported as partial. Inventory results are cached and invalidated by bag/equipment/item-cache/collection/login events. Uncached items are requested once and their load event refreshes the tracker. Pending analysis is retried every two seconds only while an active raid tracker needs it; ready results have no polling. API references: [Blizzard item APIs](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua) and [Blizzard upgrade eligibility](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemUpgradeDocumentation.lua).

**Click a difficulty row to preview its complete outfit in Blizzard's dressing room**, including pieces you have not collected. One source per appearance slot is used, with robes grouped as chest armor. Preview clicks are ignored in combat and during Edit Mode. Reference: [Blizzard DressUpTransmogSet](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/DressUpFrames.lua). The independent action engine is in `RaidAppearanceActions.lua`.

Mocked tests cover all three paths, object locations/levels, unrelated upgrade visuals, shared/PvP exclusions, unreachable ranks, native eligibility rejection, collection counts, inventory invalidation, item load events, absent native APIs, operation with Transmog Upgrade Master disabled, native inline icons at narrow widths, complete outfit preview and combat/Edit Mode guards. Actual items and dressing-room rendering still require in-game validation.

Since 0.18.6, every addon text (panels, titles, values, editors) uses Expressway through `addon.SetFont`. `tools/Import-Media.ps1` copies the font from EllesmereUI (or NorthernSkyRaidTools) to `Media/Fonts/Expressway.ttf`; Expressway is a commercial Typodermic font, kept for personal use and excluded from the public repository. If it is missing, text falls back to Blizzard's font. The bundled Noto Sans Bold is no longer used. Since 0.18.7, Expressway is preloaded through font objects when the addon loads, and text set before a font change is laid out again, so static titles and labels no longer render blank. Since 0.18.8, text uses the slightly heavier Expressway Extra Bold (EllesmereUI's `Expressway Bold.ttf`, imported as `Media/Fonts/Expressway-Bold.ttf`), falling back to the regular Expressway file, then Blizzard's font.

Currencies include a selectable grouped Crests row (Champion / Hero / Myth), showing three native currency icons and spendable quantities. Hover lists localized currency names and earned caps when supplied by Blizzard. Midnight seasons 1 and 2 are supported; IDs were verified against [client CurrencyTypes data](https://wago.tools/db2/CurrencyTypes/csv), excluding hidden counters. Add it through Configure rows; existing selections are preserved.

Grouped crest icons use 20-unit artwork independent of the text size, with vertical padding. Narrow panels reduce text first, then icons to a minimum of 16 units and tighten spacing if necessary.

Version 0.12.5 renders grouped crest icons as separate textures centered on their row, with four units of vertical padding per side. Quantities use separate measured font strings. This avoids font-baseline overflow from inline artwork; reusable widgets are hidden when a row changes content. Narrow panels tighten group spacing before reducing artwork size.

Panel collapse controls use a custom two-stroke green chevron in a fixed square frame, facing right when closed and down when open, with a white hover state. The artwork is independent of font metrics and replaces the scroll-button texture and text symbols.

### Textured backgrounds and compact progress

Background opacity defaults to 100%. Existing per-layout panel settings migrate once to 100%, then later user opacity adjustments are preserved. Pixels and RefineUI reuse their existing textures rather than a flat colour. Progress textures use full opacity and undimmed provider colours, with labels/icons above them. Compact rows show gauges for renown toward the next level (full at maximum, absent for locked/unknown factions), class raid-set collection, profession skill and each Great Vault activity threshold. Counts and reward item levels remain visible. These gauges respect the existing Show bars setting in Edit Mode; balance-only currencies, grouped crests, money and custom text do not acquire artificial progress goals. Unknown raid collection data has no gauge.

Verified against the supplied video reference, with smoke checks covering migration, subsequent opacity edits, renown states, bounds across all styles, toggles, other providers and exclusions. In-game visual validation remains necessary.

Version 0.13.1 removes inner padding from compact progress gauges so their fill covers the complete row. Text and icon padding remains in place.

### Visual currency selection (0.14.0)

The currency editor follows the supplied video: a scrollable two-column list of native currency icons, localized names and checkboxes, grouped by expansion/category, plus search and a selected-row ordering section. Existing choices are retained, duplicate choices are consolidated, selection is limited to eight rows per panel, and settings remain independent per panel/layout. Numeric IDs remain internal stable keys; manual numeric entry is removed. CurrencyCatalog.lua contains visible-category ID facts from [CurrencyTypes](https://wago.tools/db2/CurrencyTypes/csv) and [CurrencyCategory](https://wago.tools/db2/CurrencyCategory/csv), excluding hidden/test/debug categories. Names, quantities and icons come from [Blizzard's currency API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua); registry entries with no current client data are omitted. Native-list and previously selected currencies supplement the registry. Full catalogue scans happen in configuration, while live panel refreshes resolve selected currencies only. Tests cover selection, filtering, capacity, zero balances before discovery, order/removal/clear, saved choices, frame reuse and refresh cost. Final widget rendering requires in-game validation.

Version 0.14.1 removes the remaining four-unit lateral row inset from compact trackers. Gauges now span the panel width; labels and icons retain their own padding. Row dividers are opaque one-physical-pixel lines rendered above the progress fill, keeping boundaries visible even on completed rows.

With the Pixels theme, row and compact quest-section dividers now reuse the border's `pixels-sep.tga` companion artwork, including its light/shadow relief. The strip is cropped to its visible band and aligned to the pixel grid; other themes retain their simple dividers. Existing textures are reused without adding frames or polling.

Version 0.14.3 adds right-click on a renown row to open that faction's standard Blizzard renown summary. Blizzard_MajorFactions is loaded if necessary through the native loader or C_AddOns.LoadAddOn, then [ToggleMajorFactionRenown](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_MajorFactions/Blizzard_MajorFactionsLandingTemplates.lua) selects the faction. Repeated right-click leaves an already displayed summary open. Clicks are ignored in combat/Edit Mode, and right-click does not trigger unrelated row actions. Hover text advertises the shortcut. Smoke tests cover faction routing, load-on-demand, loader failure and click guards; actual Blizzard window rendering remains to be checked in game.

Version 0.14.4 fixes renown right-click on Retail 12.1: the native View Renown button now opens the Adventure Guide Journeys tab, not MajorFactionRenownFrame. FunelQOL follows [Blizzard ReputationDetailViewRenownButtonMixin](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ReputationFrame.lua), loading Blizzard_EncounterJournal, selecting JourneysTab and calling EncounterJournalJourneysFrame:ResetView(nil, factionID). The old window remains a compatibility fallback. A regression reproduces the missing legacy window and checks the exact modern faction/tab routing, repeated clicks, loading and guards. Final window rendering still needs in-game confirmation.

Version 0.15.0 adds the "Weekly" content type: the Prey weekly quest (94446, x/3), hunts per difficulty, crest progress (weekly or seasonal cap), the Tier 11 Gilded Stash (widget 7591 inside delves, plus loot detection from stash objects 584507/506498, deduplicated per GUID), Dundun's weekly Abundance (gossip option 140123, detected via a `C_GossipInfo.SelectOption` hook or by the option still being offered), weekly Restored Coffer Keys from caches (flags 91175–91178), and keys/shards owned (3028/3310). Facts the game exposes only in passing are kept per character in `FunelQOLCharDB.weekly` until the weekly reset. IDs come from MidnightRoutine, Plumber and LittleWigs. In-game confirmation is still needed.

Version 0.16.0 adds the "Rares" content type. It lists the rares of the current zone (micro maps walk up to their parent zone; rares friendly to your faction are hidden). Rows start collapsed and show the collected / total count of collectible rewards (mounts, pets, toys and appearances), with a badge for each missing mount, pet or toy kind. Left-click a row to unfold a grid of bordered reward icons; collected rewards are greyed out, checked and green-bordered, and missing rewards come first. Hover an icon for its item tooltip. Hover the row for its coordinates, kill status (quest flag, or achievement criteria when no quest exists), the warband bonus and the collection count. Shift-click (or a plain click on a rare without collectibles) opens the map; right-click places and tracks a Blizzard waypoint (and a TomTom waypoint if TomTom happens to be loaded). The panel title shows the zone name, and long lists scroll within the maximum tracker height.

Rare positions and loot tables come from RareScanner. No addon needs to be installed: `tools/Import-Rares.ps1` downloads the latest retail RareScanner release from its GitHub mirror (or reads `-ZipPath`), parses `NpcInfoTables.lua` and `NpcLootTables.lua`, and writes `RareData.lua`. RareScanner reserves all rights, so this generated file is for personal use only and is excluded from Git. A fresh clone must run the script once (and again to refresh the data). Without the file, the panel simply reports no known rares. Collectibles are classified in game from the item ID (`C_MountJournal.GetMountFromItem`, `C_PetJournal.GetPetInfoByItemID`, `C_ToyBox.GetToyInfo`, `C_TransmogCollection.GetItemInfo`); uncached items are requested and classified on the next refresh. Housing decor is not tracked yet.

```powershell
.\tools\Import-Rares.ps1
```

Version 0.17.0 adds right-click actions to tracked rows, each announced in the row tooltip: delves and map events place and track a waypoint on their entrance or event position (from `C_AreaPoiInfo` positions; rows without a position keep the left-click map only); quests and active delve quests toggle Blizzard super-tracking; profession rows open the profession window; knowledge currencies (named "Connaissances en ..." / "... Knowledge") open their profession on the Specializations tab; other currencies open the character Currency tab; Great Vault rows open the Great Vault. Renown and rares keep their existing right-click. Profession and vault windows are not opened in combat. Waypoints share the rare tracker helper (Blizzard waypoint, plus TomTom only if it happens to be loaded). In-game confirmation is still needed.

Version 0.18.0 adds a "Téléportations" / "Teleports" content type. Teleport IDs come from the TeleportMenu addon (by Justwait), which has no licence: `tools/Import-Teleports.ps1` reads the installed `TeleportMenu` folder (or `-SourcePath`, else downloads the GitHub sources), parses its item, wormhole, hearthstone, `tpTable` and seasonal tables, and writes `TeleportData.lua`. This generated file is for personal use only and is excluded from Git; TeleportMenu is never needed at runtime.

```powershell
.\tools\Import-Teleports.ps1
```

All owned teleports form a single untitled icon grid, in this order: hearth, current-season dungeons, class and race, items and toys, engineering, hearthstone toys, then Hero's Path spells (a spell listed twice appears once). Only owned items (`C_Item.GetItemCount`), usable collected toys (`PlayerHasToy`, `C_ToyBox.IsToyUsable`) and known spells (`C_SpellBook.IsSpellKnown`, flyout slots) are shown; faction, class and race restrictions are applied, and quest-gated hearthstones (Garrison, Dalaran) need their quest. Each icon is framed by the panel's selected border style, drawn with its central 56 texels on exactly 56 or 28 physical pixels for sharpness, shows a native cooldown swipe and the item, toy or spell tooltip. The panel scrolls with the quest height setting. Left-clicking an icon uses it out of combat: a single `SecureActionButtonTemplate` button (type `spell`, `toy` or `item`) is placed over the hovered icon and detached on `PLAYER_REGEN_DISABLED`, so panels never anchor a protected frame in combat. In combat, icon clicks do nothing and the tooltip says the teleport is unavailable. Player housing teleports are not tracked. In-game confirmation is still needed.

Version 0.18.4 enlarges teleport icons slightly and redraws the Great Vault like the teleport grid: one row per category (raids, dungeons, delves and world, or rated PvP when there is no world row) with its unlocked slot count and gauge, then one wide tile per slot framed by the panel border style; the slots of a category share the full row width. Each tile shows an icon on the left and its text over a progress fill: an unlocked slot shows its example reward icon and item level in green, fully filled (from `C_WeeklyRewards.GetExampleRewardItemHyperlinks`, item tooltip on hover); a locked slot shows a desaturated box and its progress (for example `3/4`, filled to 75%). Concession and bonus thresholds are no longer listed as categories. Right-clicking a row or a tile still opens the Great Vault. In-game confirmation is still needed.

## Alt leveling XP quests

The **Delve quests** tracker also includes Abundance (Abundant Offerings), ten delves or world quests (Hope in the Darkest Corners), Saltheril's Soiree (Fortify the Runestones), and Legends of the Haranir. One row per activity follows the character's active variant, objective counters, ready-to-turn-in state and completion. Hover for objectives, pickup hints and the route's recommendation to save these turn-ins for the final leveling phase. Existing Delver's Calls and the Hide turned-in quests setting remain available.

Haranir tracking distinguishes introductory and repeat master quests; old relic unlocks do not count as a completed weekly. FollowTheArrow is a reference, not a required dependency. Quest facts and sources are documented in [docs/alt-leveling-quests.md](docs/alt-leveling-quests.md).

## Quest XP totals

Quest and Delve quests panels show **Ready quest XP** and **Quest log XP** for all accepted, visible quests in the journal, including unwatched quests. Failed quests are excluded. Hover for counts, XP remaining to the next level and the effective included bonus percentage when the client also supplies base XP. Individual tracked quest tooltips show their XP reward.

The calculation sums Blizzard's current total reward directly; it does not multiply Warband, War Mode or temporary buffs again. Rewards refresh after level, aura, equipment and War Mode changes. Unloaded rewards produce an explicitly partial subtotal. Values describe the current level and modifiers, rather than projecting several level-ups whose scaled rewards may change. Rested XP is not added; the summary is hidden at the XP cap and marks disabled XP gain. See [docs/quest-xp-calculation.md](docs/quest-xp-calculation.md) for the API sources and in-game validation limits.

## Raid collection tracker

Choose **Raid collection** as a panel's Content in Blizzard Edit Mode. Enter a raid to load its collection for the current difficulty; the last visited raid remains available after leaving. **Configure rows** filters class set pieces, mounts, pets, toys and other appearances, and optionally includes collected rewards. Boss headings fold on click. The maximum height uses the quest tracker height setting. Hover a reward for its native item tooltip; click a class set piece to preview the set. FunelQOL's native upgrade/catalyst analysis is also shown on supported class piece tooltips.

Class sets use the existing account appearance tracker. Other rewards come from Blizzard's encounter journal and are grouped by boss, with full item links preserving difficulty variants. Collection status includes equivalent unlocked appearances. Set pieces remain separate where tier tokens cannot be reliably mapped to bosses. Availability exceptions, achievement rewards and drops absent from the journal are not included in this first version. Pending loot/item data is identified explicitly; the addon waits until an open journal closes before scanning, and restores the journal's previous selection and filters. API references: [docs/raid-collection-data.md](docs/raid-collection-data.md).

Raid collection also includes an **Achievements** section using Blizzard achievement DB2 map associations. It shows unfinished ordinary raid achievements, criterion progress and rewards; left-click opens the native achievement panel. The category and completed entries can be toggled in the collection editor. Statistics, guild achievements, feats of strength, Legacy categories and season/event-restricted records are excluded conservatively; this is not a universal availability check. Shared achievements without a specific instance association may be absent. Data can be regenerated with `tools/Import-RaidAchievements.ps1`.

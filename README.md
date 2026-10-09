# FunelQOL

A personal quality-of-life addon for World of Warcraft Retail. Version 0.3.0 provides two configurable panels with live currencies, professions, selected talents, and custom text rows. LibEditMode is bundled; no separate library addon is required.

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
2. Select a FunelQOL panel and choose **Content**: Preview, Currencies, Professions, Selected talents, or Custom menu.
3. Click **Configure rows** (French: **Configurer les lignes**). You can also reopen this editor with `/funelqol content 1` or `/funelqol content 2`.
4. Choose up to eight entries with the dropdowns. Use **↑ / ↓** to reorder them and **×** beside a row to remove it. Custom rows have a label and a value field instead of a dropdown.
5. Close the editor and exit Edit Mode. Changes apply immediately; `/reload` saves them to disk.

Each content type keeps its own selection, so switching to Preview does not erase currencies or custom rows. The first use of a live content type selects up to three available entries. An empty selection shows a configuration hint.

- **Currencies:** current wallet quantity, optional wallet-cap bar, and gold. Seasonal total-earned caps are not displayed as wallet-cap bars. The dropdown reflects the visible Blizzard currency list: expand categories in the character currency tab and reopen the editor to expose more entries. You can also enter a numeric currency ID at the bottom of the editor. Selected currencies remain readable when their category is collapsed.
- **Professions:** learned professions, including secondary professions, with their reported skill rank and maximum. The expansion skill-line name is used when available.
- **Selected talents:** a selection of talents from the active configuration, with icon, spell tooltip, and rank. Unselected talents and inactive hero-tree talents are hidden; their selections are retained for when they become active again. This is a read-only display, not a talent loadout switcher.
- **Custom menu:** up to eight static label/value rows (80 characters per field), such as notes or reminders. These rows do not execute scripts or actions.

Currency, money, skill, specialization, and talent events refresh the displayed values. The addon does not alter Blizzard's existing frames or create protected action buttons. Buffs, pets, and objectives are not connected yet.

## Files and development

- `FunelQOL.toc`: addon metadata, supported interface version, saved variable declaration, and Lua file load order.
- `Core.lua`: addon namespace, saved setting initialization, login event handling, and slash commands.
- `PanelPreview.lua`: localized labels and static preview rows.
- `Content.lua`: live data providers and ordered selections.
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
9. Choose each content type, configure and reorder entries, change a currency/skill value, then reload and switch layouts to verify persistence. Verify currency and talent tooltips.
10. Select Ayije and Pixels appearances after importing media, and verify borders, bar fills, text alignment, and tooltips in-game.

The mocked Lua smoke check covers preview settings, live content and updates, seasonal currency caps, sparse profession slots, talent filtering, row editor selection/order/removal, custom text, reload persistence, layout isolation, hidden-frame recovery, and slash commands:

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

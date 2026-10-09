# FunelQOL

A small personal quality-of-life addon for World of Warcraft Retail. Version 0.1.0 provides a foundation for future features, with no external libraries required.

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

The greeting setting is account-wide and stored by WoW in `FunelQOLDB`. WoW writes saved settings on logout or UI reload.

## Files and development

- `FunelQOL.toc`: addon metadata, supported interface version, saved variable declaration, and Lua file load order.
- `Core.lua`: addon namespace, saved setting initialization, login event handling, and slash commands.

The addon targets retail interface `120100`, matching the installed 12.1.0 client at creation. After a game update, check `/dump select(4, GetBuildInfo())` in WoW and review API compatibility before updating the TOC's interface number.

New Lua files must be listed in `FunelQOL.toc` in their required load order. Each file can access the same private addon namespace with `local addonName, addon = ...`. Saved settings are available after this addon's `ADDON_LOADED` event; access them through `addon.db` after initialization.

## In-game smoke check

1. Log in: one FunelQOL greeting should appear.
2. Run `/funelqol`, `/funelqol status`, and `/funelqol unknown`: check help, status, and unknown-command feedback.
3. Run `/funelqol greeting`, then `/reload`: the greeting should stay disabled and status should report it as off.
4. Toggle the greeting again and reload: the greeting should return.
5. Check BugSack or enable Lua errors with `/console scriptErrors 1` to catch runtime errors.

## References

- [World of Warcraft API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API)
- [TOC format](https://warcraft.wiki.gg/wiki/TOC_format)
- [Addon loading process](https://warcraft.wiki.gg/wiki/AddOn_loading_process)
- [Creating a slash command](https://warcraft.wiki.gg/wiki/Creating_a_slash_command)

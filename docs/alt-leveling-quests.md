# FollowTheArrow alt route: high-XP quest tracking

Research date: 2026-10-10. Installed source: FollowTheArrow 0.8.1, route `MIDNIGHT_ALT` (80–90). No FollowTheArrow code or media is copied into FunelQOL. The following quest identifiers are game facts; route advice is summarized.

## Requested quests

| Activity | Quest | Quest IDs | Location / objective |
| --- | --- | --- | --- |
| Abundance | Abundant Offerings | 89507 | Obtain 20,000 Abundance; FTA runs the Voidstorm scenario at map 2405, 38.91 / 53.21. Other Abundance sites also work. |
| Ten delves | Hope in the Darkest Corners | 95468 | Complete **10 delves or world quests**, not exclusively delves. Pickup and turn-in: Silvermoon, map 2393, 49.10 / 64.64. |
| Saltheril's Soiree | Fortify the Runestones | 90573 (Magisters), 90574 (Blood Knights), 90575 (Farstriders), 90576 (Shades of the Row) | One variant according to supported faction; defend a runestone / participate in the final boss. Soiree area: Eversong, map 2395, approximately 42.65 / 46.31. |

Exact 89507 and 95468 are explicit in FollowTheArrow. Soiree is a manual route instruction with no IDs, so its four IDs are corroborated separately against installed Plumber and MidnightRoutine. Use a **single activity row with mutually exclusive variants**, rather than four simultaneous unaccepted quests.

Sources (all relative to the AddOns directory):

- `FollowTheArrow/Data/Modules/Alt8090Delves.lua:59` and `:314` — 95468 and 89507 pickup definitions.
- `FollowTheArrow/Data/Modules/Alt8090Eversong.lua:110` — Soiree route segment, unlocking instructions, faction choice and runestone objective.
- `FollowTheArrow/Data/Modules/Alt8090CraftingEnd.lua:35`, `:53`, `:147` — final Soiree, ten-delves and Abundance turn-ins.
- `Plumber/Modules/ExpansionLandingPage/Retail/MID_Activity.lua:511` — four runestone quest variants; `:525` — Abundance weekly.
- `MidnightRoutine/Modules/WeeklyTasks.lua:1415` — corroborating four runestone variants.

## Fourth route recommendation: Legends of the Haranir

FTA includes this weekly in the same leveling route, recommending Aln'hara's Bloom when selectable. Its implementation is manual and intentionally does not resolve the selected relic. Distinguish the **master quest** from individual relic objectives; permanent first-time relic completion does not prove the repeatable weekly was turned in this week.

Installed MidnightRoutine defines these paths:

| Path | Master quest | Relic quest variants |
| --- | --- | --- |
| First-time | Lost Legends, 89268 | Wey'nan's Ward 88993; The Cauldron of Echoes 88994; Aln'hara's Bloom 88995; The Echoless Flame 88996; Russula's Outreach 88997; Root of the World 88998; Sky's Hope 88999; The Listener 90733; In the Name of the Goddess 90734 |
| Repeat | 92713 | Wey'nan's Ward 92716; The Cauldron of Echoes 92719; Aln'hara's Bloom 92720; The Echoless Flame 92721; Russula's Outreach 92722; Root of the World 92724; Sky's Hope 92725 |

The current repeat master title should be loaded from the game API rather than invented. Source: `MidnightRoutine/Modules/WeeklyTasks.lua:146–170`; first-time master corroboration: `Plumber/Modules/ExpansionLandingPage/Retail/MID_Activity.lua:533`. FTA route instructions: `FollowTheArrow/Data/Modules/Alt8090Delves.lua:70` (Entering Harandar) and `Alt8090CraftingEnd.lua:146` (final reminder).

## Behavior and scope

- Keep existing ten Delver's Call rows, and add an identifiable group of leveling weeklies in the same content tracker.
- Use the character's quest log for accepted/in progress/ready, and character completion flags for turned in. Not accepted is not the same as available; account unlock prerequisites may prevent pickup.
- Track weekly completion with a reset-aware observation if necessary. Never label an activity completed from an old first-time unlock or a completed relic alone.
- FTA recommends completing the large quests early but saving their turn-ins for its final section, since rewards scale with character level. Show a compact hint rather than blocking user interaction.
- The route describes approximately 100k XP for these weeklies after 12.0.7 changes. This is author guidance, not a fixed reward verified for every character, level and bonus. Do not hard-code that amount as the player's actual XP reward.
- Abundance requires its account unlock from the purple-triangle chain in Amani'Zar. Soiree also requires its account introduction and weekly faction choice. Haranir relic selection depends on prior account unlocks.
- FTA discusses Void Assaults and Invasion Points but explicitly leaves them out of this route. They are not priority additions for this request.

Context source: `FollowTheArrow/Data/Modules/Temporary1207.lua:48–89`. Its weeklies explanation identifies Abundance, Soiree, Legends and Hope; its route comparison excludes Void Assaults and Invasion Points.

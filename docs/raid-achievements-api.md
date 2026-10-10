# Raid achievements: data association and Retail APIs

Verified against client build `12.1.0.69933`, October 2026. `RaidAchievementData.lua` is generated factual data, independent of RetroRuns or other addon code.

## Reliable raid association

The native [Encounter Journal API](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/EncounterJournalDocumentation.lua) provides `C_EncounterJournal.GetInstanceForGameMap(mapID)` but no achievement list for an instance. Name or description substring matching would be locale dependent and miss unnamed boss challenges.

Blizzard's [Achievement DB2 export](https://wago.tools/db2/Achievement/csv?build=12.1.0.69933), transported by Wago, includes `Instance_ID`. The [DB2 schema](https://raw.githubusercontent.com/wowdev/WoWDBDefs/master/definitions/Achievement.dbd) declares it as a `Map::ID` relation. Grouping positive `Instance_ID` values yields 3,738 records across 251 game maps. This also contains dungeons, guild records, statistics and discontinued entries: the raid context and runtime filters select relevant rows. The source build is pinned and refreshes are reproducible with `tools/Import-RaidAchievements.ps1`.

Use the eighth return of `GetInstanceInfo()` (game map/instance ID), not a UI map ID or EJ journal ID. Runtime names, descriptions, icons and ownership come from the client in its own language. Records with `Instance_ID` zero or -1 cannot be automatically associated this way; cross-raid meta-achievements without a map association are outside this first catalog. No locale heuristics are used.

## Live state, progress and navigation

Native [Achievement UI](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_AchievementUI/Mainline/Blizzard_AchievementUI.lua) reads:

```lua
id, name, points, completed, month, day, year, description,
flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(id)
```

Use `completed` for account collection behavior. `wasEarnedByMe` is separate character completion and should not override account collection filtering. `C_AchievementInfo.IsValidAchievement(id)` can reject absent or invalid client entries. Its namespace also supplies `IsGuildAchievement`, but no general `IsObtainable` function in the [generated documentation](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/AchievementInfoDocumentation.lua).

The [native criteria utility](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_FrameXMLUtil/AchievementUtil.lua) reads:

```lua
criteriaString, criteriaType, completed, quantity, reqQuantity,
charName, flags, assetID, quantityString = GetAchievementCriteriaInfo(id, index)
```

`GetAchievementNumCriteria(id)` supplies the count. Criteria type 8 is another achievement; its `assetID` can be resolved with `GetAchievementInfo` for a precise objective. Other asset types must not be treated as achievement IDs. Count completed criteria for compact progress, retaining per-criterion quantity/required quantity in tooltips. DB2 `Minimum_criteria` must be respected where only a subset of criteria is required. If a progress-bar achievement has one numeric criterion, its quantity and required quantity are more informative than a one-criterion count.

`ShowAchievementFrameForAchievement(id)` is the native [bootstrap helper](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_AchievementUI/Blizzard_AchievementUI_Bootstrap.lua). It loads the Blizzard module, shows the frame and selects the achievement. Prefer this over recreating the loading/navigation flow. Refresh on `ACHIEVEMENT_EARNED`, `CRITERIA_UPDATE` and player entering world.

## Availability filters and their limits

Native [Constants.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_FrameXMLBase/Constants.lua) defines progress bar `128`, guild `16384`, account `131072`. Counter/statistic bit `1`, internal hidden bit `2` and hide-incomplete bit `2048` are documented by the original [TrinityCore DB schema implementation](https://raw.githubusercontent.com/TrinityCore/TrinityCore/master/src/server/game/DataStores/DBCEnums.h); these are corroborating schema meanings, not a Blizzard promise about obtainability. Exclude statistics, hidden internal records and guild records from a personal raid collection.

**Bit 2048 is not an unobtainable flag.** It means hidden when incomplete. Ahead of the Curve and some currently obtainable Feats of Strength can share it. There is no reliable single retired-achievement bit exposed by the APIs inspected.

Blizzard [Achievement_Category DB2](https://wago.tools/db2/Achievement_Category/csv?build=12.1.0.69933) contains:

| Category | Meaning | Parent |
| --- | --- | --- |
| 81 | Feats of Strength | -1 |
| 15093 | Guild Feats of Strength | 15076 |
| 15234 | Legacy | -1 |
| 15271 | Raids (Feats of Strength child) | 81 |
| 15468 | Dragonflight Raid | 168 |

The native `AchievementUtil.IsCategoryFeatOfStrength` recursively examines parents from `GetCategoryInfo(category)`. A conservative first version excludes Legacy and Feats of Strength subtrees. This removes expired Ahead of the Curve, Cutting Edge and Hall of Fame achievements, but **also omits currently obtainable feats**. It must not be described as an exhaustive availability detector. Some discontinued ordinary achievements may remain outside these categories and require explicit audited availability rules.

Modern DB2 also has `HiddenBeforeDisplaySeason` and `LegacyAfterTimeEvent`. Schema comments describe a seasonal visibility threshold and a time-event retirement trigger. A nonzero value is an ID, not a boolean that the achievement has expired. Without resolving the display season/time event, exclusion is conservative and may hide a future or active achievement. In this export, no positive-map rows had a nonzero hidden-season value. Runtime category changes remain preferable to blindly assuming static category values are current forever.

## Amirdrassil verification

Game map `2549`, EJ instance `1207`: the DB2 mapping directly contains these ordinary achievement IDs:

- Challenges: `19089`, `19193`, `19319`, `19320`, `19321`, `19322`, `19390`, `19393`, `19394`.
- Full clear: `19331`, heroic `19333`, mythic `19334`.
- Mythic boss kills: `19335` through `19343`.
- Raid wings: `19344` through `19347`.
- Glory of the Dream Raider: `19349`, including its mount reward text and nine challenge criteria.

Expired Ahead of the Curve `19350` and Cutting Edge `19351` both have category `15271`, flags `6144` and legacy-event zero, demonstrating why a legacy-event check alone is insufficient. Guild runs `19387`–`19389`, guild Hall of Fame `19392`, and the counter statistics must be excluded. Difficulty requirements remain in the native description/criteria: a normal-raid context can still show a missing Mythic achievement without claiming it can be completed on Normal.

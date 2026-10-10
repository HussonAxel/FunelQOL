# Quest XP calculation

Research date: 2026-10-10. Primary UI sources checked at WoW Retail
12.1.0 (69933), Gethe source mirror commit
`09b9db7948abc9b9648dedaab51eb0cf3ee67b31`.

## Use the client reward total

Read `totalXP, baseXP = GetQuestLogRewardXP(questID)` for each accepted quest.
Blizzard's own reward-tooltip helper names these returns `totalXp` and
`baseXp`; its world-quest tooltip shows the base and a separate War Mode badge.
[Primary source: QuestUtils.lua](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/QuestUtils.lua#L763).

The ordinary native quest-rewards panel displays the first return directly,
without an additional XP multiplier. This is the safest available value for
FunelQOL to sum. Do not add a second Warband, War Mode or temporary-aura
multiplier: the addon should use the client's current calculated reward, rather
than recreate stacking rules. An optional aggregate bonus can be derived from
`(sum(totalXP) / sum(baseXP) - 1) * 100`, only when all relevant base values are
available. This describes the effective difference reported by the client; it
does not identify individual buff contributions.
[Primary source: QuestInfo.lua](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestInfo.lua).

The Lua sources do not expose the engine's formula or individually guarantee
every temporary buff. Matching native current reward totals is the evidence
supported implementation; exhaustive buff behavior still needs in-game checks.

## War Mode is quest-specific

`QuestCanHaveWarModeBonus` describes eligibility. `QuestHasWarModeBonus`
additionally checks that an eligible logged quest was accepted and completed in
War Mode. Merely reading the player's current toggle does not establish a
specific quest's bonus. Use these APIs only for contextual labels, not to
multiply the reported total.
[Primary API documentation](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

## Loading, scope and refresh

Blizzard's world-quest map checks `HaveQuestRewardData(questID)` and requests
`C_TaskQuest.RequestPreloadRewardData(questID)` when unavailable. Unknown data
must be marked as pending, rather than silently counted as zero.
[Primary source: WorldQuestDataProvider.lua](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_SharedMapDataProviders/WorldQuestDataProvider.lua).

The ordinary quest-loading API is `C_QuestLog.RequestLoadQuestByID`;
`QUEST_DATA_LOAD_RESULT` reports quest ID and success. The native
`QUEST_TURNED_IN` event also supplies `xpReward`, useful for comparing previews
with real rewards during validation.
[Primary API documentation](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

Recommended presentation: total for all accepted quests and a separate subtotal
for completed, unclaimed quests. Count each quest ID once across panels and
exclude failed quests from claimable XP. Refresh native rewards on quest changes,
player aura changes, level changes and War Mode changes. Treat missing APIs or
missing reward data explicitly.

The displayed total is a snapshot at the current level and active bonuses.
Buff expiration, changing War Mode, reaching a level cap or level-dependent
reward scaling before a later hand-in can change the eventual total. A comparison
with `UnitXPMax("player") - UnitXP("player")` can show whether the ready subtotal
covers the next level; it is not a reliable multi-level hand-in simulation.

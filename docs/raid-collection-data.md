# Raid collection data (Retail 12.1)

The first version reads client Encounter Journal loot and collection state. It does not assert that a listed reward remains obtainable; removed rewards, achievements, quest rewards and special eligibility require a later exception database.

## Encounter Journal

- `C_EncounterJournal.GetInstanceForGameMap(mapID)` accepts the game instance map ID (eighth return of `GetInstanceInfo`), not a UI map ID.
- Select the journal instance with `EJ_SelectInstance`, set its supported difficulty, then enumerate `EJ_GetNumLoot()` and `C_EncounterJournal.GetLootInfoByIndex(index)`. Loot tables include `itemID`, `encounterID`, `link`, `name`, `icon` and slot metadata. Preserve the returned item link because it carries difficulty/appearance modifiers.
- Group items by `encounterID`; items with several bosses have `EJ_GetNumEncountersForLootByIndex(index)` entries, accessible through the second `GetLootInfoByIndex` argument.
- Loot may arrive asynchronously. The event is spelled `EJ_LOOT_DATA_RECIEVED` in the generated client documentation. Missing names/links or nil loot entries are loading states, not an empty collection.
- Save and restore difficulty, class/spec loot filter and slot filter. Native UI uses `EJ_GetLootFilter` / `EJ_SetLootFilter` and `C_EncounterJournal.GetSlotFilter` / `SetSlotFilter`; `ResetSlotFilter` clears the slot restriction. `Enum.ItemSlotFilterType.NoFilter` is 15.
- Avoid scanning while the journal is visible. Native UI tracks the selected instance and boss in `EncounterJournal.instanceID` and `EncounterJournal.encounterID`; those can be restored without changing UI fields during the scan. No selected-encounter getter was verified in the current generated/native sources. An optional compatibility getter must be guarded, never assumed to exist. Restore all global state on errors as well as success.

Sources: [generated Encounter Journal API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/EncounterJournalDocumentation.lua), [native Encounter Journal implementation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.lua).

## Collection state

- Mount items: `C_MountJournal.GetMountFromItem(itemID)` resolves mount ID; `GetMountInfoByID` return 11 is `isCollected`.
- Toys: native collection UI calls `C_ToyBox.GetToyInfo(itemID)` and `PlayerHasToy(itemID)`.
- Appearance: `C_TransmogCollection.GetItemInfo(loot.link)` returns appearance ID and modified appearance/source ID. `GetAppearanceInfoBySource(sourceID).appearanceIsCollected` reports appearance ownership; `GetSourceInfo(sourceID).isCollected` reports the specific source. Shared appearances count as collected without requiring that exact item drop.
- Never resolve difficulty-specific appearances solely from base item ID. A base item can resolve the wrong raid variant.

Sources: [Mount Journal API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/MountJournalDocumentation.lua), [native Toy Box](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Collections/Mainline/Blizzard_ToyBox.lua), [transmog item API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogItemsDocumentation.lua).

## Class sets

`C_TransmogSets.GetAllSets()` exposes localized raid labels, class masks and variants. `GetSourcesForSlot(setID, slot)` returns source-info tables, allowing set membership comparisons against the journal item's source/appearance. Existing FunelQOL raid-set mappings remain useful where a seasonal set spans several raids.

The set API does not expose a general token-to-class-piece redemption mapping. A token without an appearance must not be classified as a collected armor piece from its name or slot alone. Display class-set missing pieces separately when no reliable journal boss association exists.

Source: [transmog sets API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TransmogSetsDocumentation.lua).

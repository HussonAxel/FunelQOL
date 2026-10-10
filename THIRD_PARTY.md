# Third-party code and local artwork

## LibEditMode

Unmodified embedded runtime from [p3lim-wow/LibEditMode](https://github.com/p3lim-wow/LibEditMode), commit `550a52e7a0a56649d962c3fa2ceccaf50c3c77ed` (library revision 18). Loaded in namespaced mode. Its [license](Libs/LibEditMode/LICENSE.txt) permits aggregation and distribution as part of a World of Warcraft addon. All embedded files retain their original bytes.

## Local artwork

EllesmereUI and AyijeUI artwork is imported from the user's installed addons, retains its source licenses and SHA256 manifests, and is excluded from this public repository. The Expressway font (Typodermic, commercial) is copied the same way from EllesmereUI or NorthernSkyRaidTools to `Media/Fonts/Expressway.ttf`, for personal use only, and is not published. See the README's custom media section.

## Local RefineUI media

RefineUI media is copied locally by `tools/Import-RefineMedia.ps1`: `RefineBorder.blp`, `SmoothV2.tga`, `ITCAvantGardeStd-Demi.ttf` and `ITCAvantGardeStd-Bold.ttf`. The import retains RefineUI's source license and SHA256 manifest. These local assets, including the commercial font, are excluded from the public repository.

## Local rare data

`RareData.lua` is generated locally by `tools/Import-Rares.ps1` from the [RareScanner](https://www.curseforge.com/wow/addons/rarescanner) data tables (NPC positions and loot). RareScanner is "All Rights Reserved": the generated file is for personal use only and is excluded from this public repository.

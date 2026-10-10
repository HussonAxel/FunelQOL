param(
    [string]$Build = '12.1.0.69933',
    [string]$CsvPath,
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\RaidAchievementData.lua')
)

$ErrorActionPreference = 'Stop'
if ($Build -notmatch '^\d+\.\d+\.\d+\.\d+$') { throw 'Build must be a complete WoW client build.' }
$source = "https://wago.tools/db2/Achievement/csv?build=$Build"
if ($CsvPath) {
    $records = Import-Csv -LiteralPath $CsvPath
} else {
    $records = (Invoke-WebRequest -Uri $source).Content | ConvertFrom-Csv
}
foreach ($required in @('ID', 'Instance_ID', 'Flags', 'Category', 'Minimum_criteria', 'HiddenBeforeDisplaySeason', 'LegacyAfterTimeEvent')) {
    if ($records.Count -eq 0 -or $required -notin $records[0].PSObject.Properties.Name) { throw "Missing CSV column: $required" }
}
$mapped = @($records | Where-Object { [int]$_.Instance_ID -gt 0 -and [int]$_.ID -gt 0 })
$groups = $mapped | Group-Object Instance_ID | Sort-Object { [int]$_.Name }
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('-- Generated from Blizzard Achievement DB2 records; do not edit by hand.')
$lines.Add("-- Client build: $Build")
$lines.Add("-- Source: $source")
$lines.Add('-- Instance_ID references the game Map ID, not an Encounter Journal ID or UI map ID.')
$lines.Add('-- Includes dungeon/raid records, statistics, guild and retired entries; filter at runtime.')
$lines.Add('local _, addon = ...')
$lines.Add('addon.raidAchievementData = {')
foreach ($group in $groups) {
    $lines.Add(('    [{0}] = {{' -f $group.Name))
    foreach ($record in ($group.Group | Sort-Object { [int]$_.ID })) {
        $lines.Add(('        {{id={0},flags={1},category={2},hiddenSeason={3},legacyEvent={4},minimum={5}}},' -f
            [int]$record.ID, [long]$record.Flags, [int]$record.Category,
            [int]$record.HiddenBeforeDisplaySeason, [int]$record.LegacyAfterTimeEvent, [int]$record.Minimum_criteria))
    }
    $lines.Add('    },')
}
$lines.Add('}')
[System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($OutputPath), ($lines -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
Write-Output ("Generated {0} achievement records across {1} game maps: {2}" -f $mapped.Count, @($groups).Count, $OutputPath)

# Import rare NPC positions and loot from the RareScanner release archive.
# RareScanner is "All Rights Reserved": the generated file is for personal use only.
# The addon itself is never installed; only two data tables are read from the zip.
[CmdletBinding()]
param(
    # Optional local RareScanner zip. Otherwise the latest retail release is downloaded.
    [string]$ZipPath
)

$ErrorActionPreference = 'Stop'
$addonPath = Split-Path -Parent $PSScriptRoot
$destination = Join-Path $addonPath 'RareData.lua'
$workPath = Join-Path ([System.IO.Path]::GetTempPath()) ('FunelQOL-Rares-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workPath | Out-Null

try {
    if (-not $ZipPath) {
        $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/curseforge-mirror/rarescanner/releases?per_page=10' -Headers @{ 'User-Agent' = 'FunelQOL' }
        $asset = $null
        foreach ($release in $releases) {
            $asset = $release.assets | Where-Object { $_.name -match '^RareScanner_\d+\.\d+\.\d+\.\d+\.zip$' } | Select-Object -First 1
            if ($asset) { break }
        }
        if (-not $asset) { throw 'No retail RareScanner release found.' }
        $ZipPath = Join-Path $workPath $asset.name
        Write-Host "Downloading $($asset.name)"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $ZipPath -Headers @{ 'User-Agent' = 'FunelQOL' }
    }
    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) { throw "Missing RareScanner archive: $ZipPath" }
    $sourceName = [System.IO.Path]::GetFileNameWithoutExtension($ZipPath) -replace '_', ' '

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ZipPath))
    try {
        $tables = @{}
        foreach ($name in 'NpcInfoTables.lua', 'NpcLootTables.lua') {
            $entry = $zip.Entries | Where-Object { $_.FullName -eq "RareScanner/Tables/$name" } | Select-Object -First 1
            if (-not $entry) { throw "Missing RareScanner table: $name" }
            $reader = New-Object System.IO.StreamReader($entry.Open())
            try { $tables[$name] = $reader.ReadToEnd() -split "`r?`n" } finally { $reader.Dispose() }
        }
    } finally { $zip.Dispose() }

    function Get-Numbers([string]$text, [string]$field) {
        $match = [regex]::Match($text, "\b$field = \{([^}]*)\}")
        if (-not $match.Success) { return @() }
        return @([regex]::Matches($match.Groups[1].Value, '\d+') | ForEach-Object { [int]$_.Value })
    }

    # Entries span several lines when a rare appears in more than one zone.
    # Plain hashtables: an [ordered] dictionary treats integer keys as positions.
    $npcs = @{}
    $zones = @{}
    $buffer = $null
    foreach ($line in $tables['NpcInfoTables.lua']) {
        if ($null -eq $buffer) {
            if ($line -notmatch '^\s*\[\d+\] = \{') { continue }
            $buffer = New-Object System.Collections.Generic.List[string]
        }
        $buffer.Add($line)
        if ($line -notmatch '\};\s*--(.*)$') { continue }
        $name = ($Matches[1] -replace '\s*<.*$', '').Trim()
        $text = $buffer -join "`n"
        $buffer = $null
        if ($text -notmatch '^\s*\[(\d+)\] = \{') { continue }
        $npcID = [int]$Matches[1]
        $positions = @()
        if ($text -match '\bzoneID = (\d+)') {
            $zoneID = [int]$Matches[1]
            $x = [regex]::Match($text, '\bx = (\d+)')
            $y = [regex]::Match($text, '\by = (\d+)')
            if ($zoneID -gt 0 -and $x.Success -and $y.Success) {
                $positions += , @($zoneID, [int]$x.Groups[1].Value, [int]$y.Groups[1].Value)
            }
        } else {
            foreach ($zone in [regex]::Matches($text, '\[(\d+)\] = \{[^\n]*?\bx = (\d+), y = (\d+)')) {
                $positions += , @([int]$zone.Groups[1].Value, [int]$zone.Groups[2].Value, [int]$zone.Groups[3].Value)
            }
        }
        if ($positions.Count -eq 0) { continue }
        $friendly = ([regex]::Matches(([regex]::Match($text, '\bfriendly = \{([^}]*)\}').Groups[1].Value), '"(\w)"') | ForEach-Object { $_.Groups[1].Value }) -join ''
        $npcs[$npcID] = @{
            name = $name
            quests = Get-Numbers $text 'questID'
            warband = Get-Numbers $text 'warbandQuestID'
            achievements = Get-Numbers $text 'achievementID'
            friendly = $friendly
            daily = $text -match '\bquestReset = true'
            loot = @()
        }
        foreach ($position in $positions) {
            if (-not $zones.ContainsKey($position[0])) { $zones[$position[0]] = @{} }
            $zones[$position[0]][$npcID] = @($position[1], $position[2])
        }
    }
    if ($npcs.Count -lt 1000) { throw "Unexpected RareScanner format: only $($npcs.Count) rares parsed." }

    foreach ($line in $tables['NpcLootTables.lua']) {
        if ($line -notmatch '^\s*\[(\d+)\] = \{([^}]*)\}') { continue }
        $npcID = [int]$Matches[1]
        if ($npcs.ContainsKey($npcID)) {
            $npcs[$npcID].loot = @([regex]::Matches($Matches[2], '\d+') | ForEach-Object { [int]$_.Value } | Select-Object -Unique)
        }
    }

    function Format-List($values) { return '{' + ($values -join ',') + '}' }
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine('local _, addon = ...')
    [void]$builder.AppendLine('')
    [void]$builder.AppendLine("-- Generated by tools/Import-Rares.ps1 from $sourceName. Do not edit.")
    [void]$builder.AppendLine('-- RareScanner data is All Rights Reserved: personal use only, do not redistribute.')
    [void]$builder.AppendLine('-- zones[mapID][npcID] = { x, y } with coordinates in 1/100 percent.')
    [void]$builder.AppendLine('-- n: name, q: kill quests, w: warband quests, a: achievements, f: friendly to A/H, r: daily reset, l: loot.')
    [void]$builder.AppendLine('addon.LoadRareData = function()')
    [void]$builder.AppendLine("local data = { source = `"$sourceName`" }")
    [void]$builder.AppendLine('local zones = {')
    foreach ($zoneID in ($zones.Keys | Sort-Object)) {
        $entries = foreach ($npcID in ($zones[$zoneID].Keys | Sort-Object)) { "[$npcID]={$($zones[$zoneID][$npcID] -join ',')}" }
        [void]$builder.AppendLine("    [$zoneID] = {" + ($entries -join ',') + '},')
    }
    [void]$builder.AppendLine('}')
    [void]$builder.AppendLine('local npcs = {')
    foreach ($npcID in ($npcs.Keys | Sort-Object)) {
        $npc = $npcs[$npcID]
        $fields = @('n="' + ($npc.name -replace '\\', '\\' -replace '"', '\"') + '"')
        if ($npc.quests.Count) { $fields += 'q=' + (Format-List $npc.quests) }
        if ($npc.warband.Count) { $fields += 'w=' + (Format-List $npc.warband) }
        if ($npc.achievements.Count) { $fields += 'a=' + (Format-List $npc.achievements) }
        if ($npc.friendly) { $fields += 'f="' + $npc.friendly + '"' }
        if ($npc.daily) { $fields += 'r=true' }
        if ($npc.loot.Count) { $fields += 'l=' + (Format-List $npc.loot) }
        [void]$builder.AppendLine("    [$npcID] = {" + ($fields -join ',') + '},')
    }
    [void]$builder.AppendLine('}')
    [void]$builder.AppendLine('data.zones = zones')
    [void]$builder.AppendLine('data.npcs = npcs')
    [void]$builder.AppendLine('return data')
    [void]$builder.AppendLine('end')
    [System.IO.File]::WriteAllText($destination, $builder.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Imported $($npcs.Count) rares across $($zones.Count) maps into $destination"
} finally {
    Remove-Item -LiteralPath $workPath -Recurse -Force -ErrorAction SilentlyContinue
}

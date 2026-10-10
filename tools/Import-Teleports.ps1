# Import teleport item, toy and spell IDs from the TeleportMenu addon sources.
# TeleportMenu has no licence (All Rights Reserved): the generated file is for personal use only.
# FunelQOL never loads TeleportMenu; only its data tables are read once, here.
[CmdletBinding()]
param(
    # Optional TeleportMenu folder. Defaults to the installed addon, else the GitHub sources are downloaded.
    [string]$SourcePath
)

$ErrorActionPreference = 'Stop'
$addonPath = Split-Path -Parent $PSScriptRoot
$destination = Join-Path $addonPath 'TeleportData.lua'
$workPath = Join-Path ([System.IO.Path]::GetTempPath()) ('FunelQOL-Teleports-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workPath | Out-Null

try {
    if (-not $SourcePath) {
        $installed = Join-Path (Split-Path -Parent $addonPath) 'TeleportMenu'
        if (Test-Path -LiteralPath (Join-Path $installed 'TeleportMenu.lua')) {
            $SourcePath = $installed
        } else {
            $zipPath = Join-Path $workPath 'TeleportMenu.zip'
            Write-Host 'Downloading TeleportMenu sources'
            Invoke-WebRequest -Uri 'https://github.com/Justw8/TeleportMenu/archive/refs/heads/main.zip' -OutFile $zipPath -Headers @{ 'User-Agent' = 'FunelQOL' }
            Expand-Archive -LiteralPath $zipPath -DestinationPath $workPath
            $SourcePath = (Get-ChildItem -LiteralPath $workPath -Directory | Select-Object -First 1).FullName
        }
    }
    foreach ($file in 'TeleportMenu.lua', 'Data\Items.lua', 'Data\Wormholes.lua', 'Data\Hearthstones.lua') {
        if (-not (Test-Path -LiteralPath (Join-Path $SourcePath $file) -PathType Leaf)) { throw "Missing TeleportMenu file: $file" }
    }
    function Read-Lines([string]$file) { return [System.IO.File]::ReadAllLines((Join-Path $SourcePath $file)) }
    $version = 'TeleportMenu'
    $toc = Join-Path $SourcePath 'TeleportMenu.toc'
    if ((Test-Path -LiteralPath $toc) -and ((Get-Content -LiteralPath $toc -Raw) -match '## Version:\s*(\S+)')) { $version = "TeleportMenu $($Matches[1])" }

    # Lines of the table opened by $start, up to its closing brace at the same indentation.
    function Get-Block([string[]]$lines, [string]$start) {
        $inside = $false
        $indent = ''
        $block = New-Object System.Collections.Generic.List[string]
        foreach ($line in $lines) {
            if (-not $inside) {
                if ($line -match "^(\s*)$([regex]::Escape($start))\s*\{\s*$") { $inside = $true; $indent = $Matches[1] }
                continue
            }
            if ($line -match "^$indent\}") { return $block.ToArray() }
            # Commented-out entries are disabled upstream.
            if ($line -notmatch '^\s*--') { $block.Add($line) }
        }
        throw "Unexpected TeleportMenu format: table '$start' not found."
    }
    function Get-Keys([string[]]$block) {
        return @($block | ForEach-Object { if ($_ -match '^\s*\[(\d+)\]\s*=') { [int]$Matches[1] } } | Select-Object -Unique)
    }

    $items = Get-Keys (Get-Block (Read-Lines 'Data\Items.lua') 'tpm.ItemTeleports =')
    $wormholes = Get-Keys (Get-Block (Read-Lines 'Data\Wormholes.lua') 'tpm.Wormholes =')
    $hearthstones = Get-Keys (Get-Block (Read-Lines 'Data\Hearthstones.lua') 'tpm.Hearthstones =')
    $requirements = @{}
    foreach ($line in (Get-Block (Read-Lines 'Data\Items.lua') 'local itemRequirements =')) {
        if ($line -match '^\s*\[(\d+)\]\s*=\s*\{\s*(faction|class|race)\s*=\s*"(\w+)"') { $requirements[[int]$Matches[1]] = "{$($Matches[2])=`"$($Matches[3])`"}" }
    }
    if ($items.Count -lt 50 -or $wormholes.Count -lt 5 -or $hearthstones.Count -lt 10) {
        throw "Unexpected TeleportMenu format: $($items.Count) items, $($wormholes.Count) wormholes, $($hearthstones.Count) hearthstones."
    }

    # tpTable order: hearth entries, then class flyouts and spells, then Hero's Path flyouts.
    $main = Read-Lines 'TeleportMenu.lua'
    $homes = New-Object System.Collections.Generic.List[string]
    $class = New-Object System.Collections.Generic.List[string]
    $paths = New-Object System.Collections.Generic.List[int]
    $classSection = $false
    foreach ($line in (Get-Block $main 'local tpTable =')) {
        if ($line -notmatch '\bid = (\d+)' ) { continue }
        $id = [int]$Matches[1]
        $type = if ($line -match '\btype = "(\w+)"') { $Matches[1] } else { '' }
        if ($type -eq 'flyout') {
            if ($line -match 'subtype = "path"') { $paths.Add($id) } else { $class.Add("{flyout=$id}"); $classSection = $true }
            continue
        }
        $entry = switch ($type) { 'item' { "item=$id" } 'toy' { "toy=$id" } 'spell' { "spell=$id" } default { $null } }
        if (-not $entry) { continue }
        if ($line -match '\bquest = \{([\d,\s]+)\}') { $entry += ',quests={' + (($Matches[1] -split '[,\s]+' | Where-Object { $_ }) -join ',') + '}' }
        if ($classSection) { $class.Add("{$entry}") } else { $homes.Add("{$entry}") }
    }
    if ($homes.Count -lt 2 -or $class.Count -lt 4 -or $paths.Count -lt 5) { throw 'Unexpected TeleportMenu format: tpTable not recognised.' }

    # Every season is merged: a dungeon keeps the same teleport spell whenever it returns.
    $seasonal = @{}
    $factional = @{}
    $factions = @{}
    foreach ($line in (Get-Block $main 'local factionTeleports =')) {
        if ($line -match '^\s*(Alliance|Horde)\s*=\s*\{(.*)\}') {
            $faction = $Matches[1]
            foreach ($pair in [regex]::Matches($Matches[2], '(\w+)\s*=\s*(\d+)')) { $factions["$faction.$($pair.Groups[1].Value)"] = [int]$pair.Groups[2].Value }
        }
    }
    foreach ($line in (Get-Block $main 'local seasonalTeleports =')) {
        if ($line -match '^\s*\[(\d+)\]\s*=\s*(\d+)') { $seasonal[[int]$Matches[1]] = [int]$Matches[2] }
        elseif ($line -match '^\s*\[(\d+)\]\s*=\s*(\w+)\s*,') {
            $name = $Matches[2]
            if ($factions.ContainsKey("Alliance.$name")) { $factional[[int]$Matches[1]] = "{Alliance=$($factions["Alliance.$name"]),Horde=$($factions["Horde.$name"])}" }
        }
    }
    if ($seasonal.Count -lt 4) { throw 'Unexpected TeleportMenu format: seasonal teleports not recognised.' }

    function Format-List($values) { return '{' + ($values -join ',') + '}' }
    function Format-Map($map) { return '{' + (($map.Keys | Sort-Object | ForEach-Object { "[$_]=$($map[$_])" }) -join ',') + '}' }
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine('local _, addon = ...')
    [void]$builder.AppendLine('')
    [void]$builder.AppendLine("-- Generated by tools/Import-Teleports.ps1 from $version (Justwait). Do not edit.")
    [void]$builder.AppendLine('-- TeleportMenu data is All Rights Reserved: personal use only, do not redistribute.')
    [void]$builder.AppendLine('-- homes/class: hearth and class entries in display order. seasonal: challenge mapID -> spellID.')
    [void]$builder.AppendLine('addon.teleportData = {')
    [void]$builder.AppendLine("    source = `"$version`",")
    [void]$builder.AppendLine('    homes = {' + ($homes -join ',') + '},')
    [void]$builder.AppendLine('    class = {' + ($class -join ',') + '},')
    [void]$builder.AppendLine('    paths = ' + (Format-List $paths) + ',')
    [void]$builder.AppendLine('    items = ' + (Format-List ($items | Sort-Object)) + ',')
    [void]$builder.AppendLine('    requirements = ' + (Format-Map $requirements) + ',')
    [void]$builder.AppendLine('    wormholes = ' + (Format-List ($wormholes | Sort-Object)) + ',')
    [void]$builder.AppendLine('    hearthstones = ' + (Format-List ($hearthstones | Sort-Object)) + ',')
    [void]$builder.AppendLine('    seasonal = ' + (Format-Map $seasonal) + ',')
    [void]$builder.AppendLine('    seasonalFaction = ' + (Format-Map $factional) + ',')
    [void]$builder.AppendLine('}')
    [System.IO.File]::WriteAllText($destination, $builder.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Imported $($items.Count) items, $($hearthstones.Count) hearthstones, $($wormholes.Count) wormholes, $($paths.Count) Hero's Path groups and $($seasonal.Count) seasonal dungeons into $destination"
} finally {
    Remove-Item -LiteralPath $workPath -Recurse -Force -ErrorAction SilentlyContinue
}

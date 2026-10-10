# Import EllesmereUI Pixels and, when installed, AyijeUI artwork for local use.
[CmdletBinding()]
param(
    [string]$AddOnsPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Stop'
$addonPath = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $AddOnsPath 'EllesmereUI'
$destinationPath = Join-Path $addonPath 'Media\Ellesmere'
$files = @(
    'textures\pixels-fill.tga',
    'textures\pixels-dark.tga',
    'textures\pixels-bg.tga',
    'borders\pixels.tga',
    'borders\pixels-sep.tga',
    'borders\pixels-vsep.tga',
    'borders\pixels-textured.tga',
    'borders\pixels-textured-sep.tga',
    'borders\pixels-textured-vsep.tga',
    'textures\shields\pixels-shield.tga',
    'textures\shields\pixels-shield-edge.tga',
    'textures\shields\pixels-shield-fill.tga',
    'textures\shields\pixels-glowline.tga',
    'textures\shields\pixels-overshield-line.tga'
)

# Check every source before importing anything.
foreach ($relativePath in $files) {
    $source = Join-Path $sourcePath ('media\' + $relativePath)
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Missing EllesmereUI asset: $source"
    }
}
$licensePath = Join-Path $sourcePath 'license.txt'
if (-not (Test-Path -LiteralPath $licensePath -PathType Leaf)) {
    throw "Missing source license: $licensePath"
}

$manifest = foreach ($relativePath in $files) {
    $source = Join-Path $sourcePath ('media\' + $relativePath)
    $destination = Join-Path $destinationPath $relativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination
    $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $sourceHash) {
        throw "Copy verification failed: $relativePath"
    }
    [PSCustomObject]@{ File = $relativePath; SHA256 = $sourceHash }
}
Copy-Item -LiteralPath $licensePath -Destination (Join-Path $destinationPath 'LICENSE-source.txt')
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $destinationPath 'manifest.json') -Encoding UTF8
Write-Output "Imported and verified $($files.Count) EllesmereUI Pixels assets."

# Expressway (Typodermic, commercial) is the addon font: copied for personal use only.
$fontSources = @(
    (Join-Path $sourcePath 'media\fonts\Expressway.TTF'),
    (Join-Path $AddOnsPath 'NorthernSkyRaidTools\Media\Fonts\Expressway.TTF')
)
$fontSource = $fontSources | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $fontSource) { throw "Missing Expressway font: $($fontSources -join ', ')" }
$fontDestination = Join-Path $addonPath 'Media\Fonts\Expressway.ttf'
Copy-Item -LiteralPath $fontSource -Destination $fontDestination
if ((Get-FileHash -LiteralPath $fontDestination -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $fontSource -Algorithm SHA256).Hash) {
    throw 'Copy verification failed: Expressway.ttf'
}
Write-Output "Imported and verified Expressway from $fontSource."

# "Expressway Bold" is the Extra Bold weight (800), one step above Expressway.TTF (700).
$boldSource = Join-Path $sourcePath 'media\fonts\Expressway Bold.ttf'
if (Test-Path -LiteralPath $boldSource -PathType Leaf) {
    $boldDestination = Join-Path $addonPath 'Media\Fonts\Expressway-Bold.ttf'
    Copy-Item -LiteralPath $boldSource -Destination $boldDestination
    if ((Get-FileHash -LiteralPath $boldDestination -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $boldSource -Algorithm SHA256).Hash) {
        throw 'Copy verification failed: Expressway-Bold.ttf'
    }
    Write-Output 'Imported and verified Expressway Extra Bold.'
}

if (Test-Path -LiteralPath (Join-Path $AddOnsPath 'AyijeUI') -PathType Container) {
    & (Join-Path $PSScriptRoot 'Import-AyijeMedia.ps1') -AddOnsPath $AddOnsPath
}
if (Test-Path -LiteralPath (Join-Path $AddOnsPath 'RefineUI') -PathType Container) {
    & (Join-Path $PSScriptRoot 'Import-RefineMedia.ps1') -AddOnsPath $AddOnsPath
}

# Import the installed EllesmereUI Pixels assets for local use.
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

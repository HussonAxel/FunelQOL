# Import artwork from the installed AyijeUI for local use.
[CmdletBinding()]
param(
    [string]$AddOnsPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Stop'
$addonPath = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $AddOnsPath 'AyijeUI'
$destinationPath = Join-Path $addonPath 'Media\AyijeUI'
$licensePath = Join-Path $sourcePath 'License.txt'

if (-not (Test-Path -LiteralPath $licensePath -PathType Leaf)) {
    throw "Missing AyijeUI source license: $licensePath"
}
$sourceMediaPath = (Resolve-Path -LiteralPath (Join-Path $sourcePath 'Media')).Path
$files = @(foreach ($directory in @('Statusbar', 'Borders', 'Textures')) {
    Get-ChildItem -LiteralPath (Join-Path $sourceMediaPath $directory) -Recurse -File |
        Where-Object { $_.Extension -in @('.tga', '.blp', '.png') }
})
if ($files.Count -eq 0) {
    throw "No AyijeUI artwork found in $sourceMediaPath"
}

$manifest = foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($sourceMediaPath.Length + 1)
    $destination = Join-Path $destinationPath $relativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination
    $sourceHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $sourceHash) {
        throw "Copy verification failed: $relativePath"
    }
    [PSCustomObject]@{ File = $relativePath; SHA256 = $sourceHash }
}
Copy-Item -LiteralPath $licensePath -Destination (Join-Path $destinationPath 'LICENSE-source.txt')
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $destinationPath 'manifest.json') -Encoding UTF8
Write-Output "Imported and verified $($files.Count) AyijeUI assets."

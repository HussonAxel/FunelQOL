[CmdletBinding()]
param([string]$AddOnsPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $AddOnsPath 'RefineUI'
$destinationPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'Media\RefineUI'
$files = @('Textures\RefineBorder.blp', 'Textures\SmoothV2.tga', 'Fonts\ITCAvantGardeStd-Demi.ttf', 'Fonts\ITCAvantGardeStd-Bold.ttf')
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $sourcePath ('Media\' + $file)) -PathType Leaf)) { throw "Missing RefineUI asset: $file" }
}
$licensePath = Join-Path $sourcePath 'LICENSE.txt'
if (-not (Test-Path -LiteralPath $licensePath -PathType Leaf)) { throw 'Missing RefineUI source license.' }
$manifest = foreach ($file in $files) {
    $source = Join-Path $sourcePath ('Media\' + $file)
    $destination = Join-Path $destinationPath $file
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination
    $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $hash) { throw "Copy verification failed: $file" }
    [PSCustomObject]@{ File = $file; SHA256 = $hash }
}
Copy-Item -LiteralPath $licensePath -Destination (Join-Path $destinationPath 'LICENSE-source.txt')
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $destinationPath 'manifest.json') -Encoding UTF8
Write-Output "Imported and verified $($files.Count) RefineUI assets."

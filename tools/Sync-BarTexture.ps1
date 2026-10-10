[CmdletBinding()]
param([string]$AddOnsPath)
$ErrorActionPreference = 'Stop'
if (-not $AddOnsPath) { $AddOnsPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
# FunelQOL's Media\Bars\d1.tga is the reference bar texture; RefineUI keeps its own copy.
$source = Join-Path (Split-Path -Parent $PSScriptRoot) 'Media\Bars\d1.tga'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'Missing bar texture: Media\Bars\d1.tga' }
$refinePath = Join-Path $AddOnsPath 'RefineUI\Media\Textures'
if (-not (Test-Path -LiteralPath $refinePath -PathType Container)) { Write-Output 'RefineUI not installed: nothing to sync.'; return }
$destination = Join-Path $refinePath 'd1.tga'
Copy-Item -LiteralPath $source -Destination $destination
if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash) { throw 'Copy verification failed.' }
Write-Output 'Synced and verified d1.tga into RefineUI.'

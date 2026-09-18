[CmdletBinding()]
param(
    [string]$GameBin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module -Force -Name (Join-Path $PSScriptRoot 'CossacksClassic.psm1')

$bin = Get-CossacksBinPath -Override $GameBin
$backup = Get-BackupRoot -GameBin $bin

foreach ($name in @('mode.dat', 'ddraw.dll', 'dciman32.dll', 'DDrawCompat.ini', 'DDrawCompat-dmcr.ini')) {
    Restore-BackupFile -BackupRoot $backup -Destination (Join-Path $bin $name) | Out-Null
}

$launcher = Join-Path $bin 'Cossacks Classic 4x3.bat'
if (Test-Path -LiteralPath $launcher) {
    Remove-Item -LiteralPath $launcher -Force
}
foreach ($name in @('CossacksClassic-Launch.ps1', 'DisplayTarget.ps1')) {
    $extra = Join-Path $bin $name
    if (Test-Path -LiteralPath $extra) {
        Remove-Item -LiteralPath $extra -Force
    }
}

Remove-CossacksCompatibilityFlags -GameBin $bin
Remove-CossacksGpuPreference -GameBin $bin
Write-Host "Removed classic DirectDraw preset from $bin"

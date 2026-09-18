# Self-contained: copied into the game bin folder. Do not require the git repo at launch.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$bin = $PSScriptRoot
. (Join-Path $bin 'DisplayTarget.ps1')

if (-not (Test-Path -LiteralPath (Join-Path $bin 'csbtw.exe'))) {
    throw 'csbtw.exe not found. Start the game from Steam once, then retry.'
}

$monitor = Get-LargestMonitor
foreach ($ini in @('DDrawCompat.ini', 'DDrawCompat-dmcr.ini')) {
    $path = Join-Path $bin $ini
    if (Test-Path -LiteralPath $path) {
        Set-IniDisplayResolution -Path $path -Width $monitor.Width -Height $monitor.Height
    }
}

Move-CursorToMonitor -Monitor $monitor
Write-Host ("Cossacks framebuffer stays 4:3 (mode.dat). Presenting {0}x{1} on {2}." -f $monitor.Width, $monitor.Height, $monitor.DeviceString)

$csbtw = Join-Path $bin 'csbtw.exe'
Start-Process -FilePath $csbtw -WorkingDirectory $bin

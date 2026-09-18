# Self-contained: copied into the game bin folder. Do not require the git repo at launch.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$bin = $PSScriptRoot
. (Join-Path $bin 'DisplayTarget.ps1')

if (-not (Test-Path -LiteralPath (Join-Path $bin 'csbtw.exe'))) {
    throw 'csbtw.exe not found. Start the game from Steam once, then retry.'
}

$inis = @(
    (Join-Path $bin 'DDrawCompat.ini'),
    (Join-Path $bin 'DDrawCompat-dmcr.ini')
)
$monitor = Initialize-CossacksPresentTarget -IniPath $inis
Write-Host ("Cossacks framebuffer stays 4:3 (mode.dat). Presenting native {0}x{1} on {2}." -f $monitor.NativeWidth, $monitor.NativeHeight, $monitor.DeviceString)
Write-Host ("SupportedResolutions: {0}" -f (Get-SupportedResolutionValue))

$csbtw = Join-Path $bin 'csbtw.exe'
Start-Process -FilePath $csbtw -WorkingDirectory $bin

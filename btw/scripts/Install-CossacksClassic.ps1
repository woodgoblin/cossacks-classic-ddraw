<#
.SYNOPSIS
    Install the classic 4:3 DirectDraw preset into a legal Cossacks: Back to War copy.

.PARAMETER GameBin
    Path to the game's bin folder (contains dmcr.exe). Autodetected when omitted.

.PARAMETER InternalResolution
    Framebuffer the game itself uses. 1024x768 is the Steam menu design size.

.PARAMETER Preset
    classic: 4:3 pillarbox with point sampling (default).
    integer: integer scale, more black bars, true pixels.
    menu-gdi-off: classic with GdiInterops=none if GDI mixing freezes the menu.

.PARAMETER SkipDownload
    Reuse a previously downloaded DDrawCompat zip in .cache.

.PARAMETER SkipDirectPlay
    Do not try to enable the Windows DirectPlay optional feature.
#>
[CmdletBinding()]
param(
    [string]$GameBin,
    [ValidateSet('1024x768', '800x600')]
    [string]$InternalResolution = '1024x768',
    [ValidateSet('classic', 'integer', 'menu-gdi-off')]
    [string]$Preset = 'classic',
    [switch]$SkipDownload,
    [switch]$SkipDirectPlay
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module -Force -Name (Join-Path $PSScriptRoot 'CossacksClassic.psm1')

$bin = Get-CossacksBinPath -Override $GameBin
$backup = Get-BackupRoot -GameBin $bin
$width, $height = $InternalResolution -split 'x'

Write-Host "Game bin: $bin"
Write-Host "Preset: $Preset @ $InternalResolution"

foreach ($name in @('mode.dat', 'ddraw.dll', 'dciman32.dll', 'DDrawCompat.ini')) {
    Backup-ExistingFile -Path (Join-Path $bin $name) -BackupRoot $backup | Out-Null
}

$presetPath = Get-PresetPath -Preset $Preset
Copy-Item -LiteralPath $presetPath -Destination (Join-Path $bin 'DDrawCompat.ini') -Force
Copy-Item -LiteralPath $presetPath -Destination (Join-Path $bin 'DDrawCompat-dmcr.ini') -Force
$monitor = Get-LargestMonitor
foreach ($ini in @('DDrawCompat.ini', 'DDrawCompat-dmcr.ini')) {
    Set-IniDisplayResolution -Path (Join-Path $bin $ini) -Width $monitor.Width -Height $monitor.Height
}
Write-Host ("Largest monitor: {0}x{1} ({2})" -f $monitor.Width, $monitor.Height, $monitor.DeviceString)

if (-not $SkipDownload) {
    $release = Install-DDrawCompatBinary -GameBin $bin
    Write-Host "DDrawCompat $($release.Tag) installed as dciman32.dll (Cossacks Method 1; no local ddraw.dll)"
}
elseif (-not (Test-Path -LiteralPath (Join-Path $bin 'dciman32.dll'))) {
    throw 'dciman32.dll is missing. Run without -SkipDownload.'
}

Write-ModeDatResolution -Path (Join-Path $bin 'mode.dat') -Width ([int]$width) -Height ([int]$height) -Refresh 60
Set-CossacksCompatibilityFlags -GameBin $bin
Remove-CossacksGpuPreference -GameBin $bin
$launcher = Write-Launcher -GameBin $bin

if (-not $SkipDirectPlay) {
    try {
        $dp = Enable-DirectPlayFeature
        Write-Host "DirectPlay: $dp"
    }
    catch {
        Write-Warning "DirectPlay was not enabled (admin rights needed): $($_.Exception.Message)"
        Write-Warning 'Turn it on yourself: Optional features -> More Windows features -> Legacy Components -> DirectPlay'
    }
}

Write-Host ""
Write-Host "Installed."
Write-Host "Launcher: $launcher"
Get-SteamOverlayInstructions | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "In-game: keep 1024x768 (or 800x600). That is the framebuffer; it is pillarboxed 4:3 on the largest monitor."
Write-Host "Shift+F11 opens the DDrawCompat overlay."
Write-Host "If you want true integer pixels, rerun with -Preset integer"

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gameRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $gameRoot
Import-Module -Force -Name (Join-Path $PSScriptRoot 'CossacksClassic.psm1')

$failed = 0
function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        Write-Host "PASS $Name"
    }
    else {
        Write-Host "FAIL $Name"
        $script:failed++
    }
}

# Arrange / Act / Assert: rewriting a Steam mode.dat keeps trailing fields
$original = '1360 768 85 0 0 0 61 6 1 2'
$result = Set-ModeDatResolution -Content $original -Width 1024 -Height 768 -Refresh 60
Assert-True ($result -eq '1024 768 60 0 0 0 61 6 1 2') 'mode.dat 1024x768 rewrite keeps extra fields'

# Arrange / Act / Assert: 800x600 profile
$result800 = Set-ModeDatResolution -Content $original -Width 800 -Height 600 -Refresh 60
Assert-True ($result800 -eq '800 600 60 0 0 0 61 6 1 2') 'mode.dat 800x600 rewrite'

# Arrange / Act / Assert: empty file still produces a valid line
$empty = Set-ModeDatResolution -Content '' -Width 1024 -Height 768 -Refresh 60
Assert-True ($empty.StartsWith('1024 768 60')) 'empty mode.dat gets a default line'

# Arrange / Act / Assert: presets exist
foreach ($preset in @('classic', 'integer', 'menu-gdi-off')) {
    $path = Get-PresetPath -Preset $preset
    Assert-True (Test-Path -LiteralPath $path) "preset $preset exists"
}

$classic = Get-Content -LiteralPath (Get-PresetPath -Preset classic) -Raw
Assert-True ($classic -match 'DisplayAspectRatio = 4:3') 'classic preset forces 4:3'
Assert-True ($classic -match 'FullscreenMode = borderless') 'classic preset is borderless so csemu can present GDI'
Assert-True ($classic -match 'AltTabFix = keepvidmem\(1\)') 'classic preset keeps vidmem across Alt+Tab'
Assert-True ($classic -match 'CompatFixes = nowindowborders') 'classic preset does not pin the Windows primary'
Assert-True ($classic -notmatch 'singlemonitor') 'classic preset is not locked to the primary monitor'
Assert-True ($classic -match 'GdiInterops = all') 'classic preset composites GDI onto the DirectDraw primary'
Assert-True ($classic -match 'FpsLimiter = msgloop\(60\)') 'classic preset caps the menu loop'
Assert-True ($classic -match 'BltFilter = point') 'classic preset keeps point blits'
Assert-True ($classic -notmatch 'DisplayFilter = bilinear') 'classic preset does not bilinear-filter'
Assert-True ($classic -match 'SupportedRefreshRates = native') 'classic preset keeps native refresh rates'
Assert-True ($classic -match 'SupportedResolutions = native, 640x480, 800x600, 1024x768') 'classic preset keeps native modes for csemu init'
$manifest = Get-DpiManifestText
Assert-True ($manifest -match 'PerMonitorV2') 'DPI manifest requests per-monitor awareness before csemu reads GetSystemMetrics'

try {
    $detectedBin = Get-CossacksBinPath
    Assert-True (Test-CossacksBin $detectedBin) 'detected Steam bin looks like Back to War'
}
catch {
    Write-Host 'SKIP detected Steam bin (no local install)'
}

Assert-True ((Get-GameRoot) -eq $gameRoot) 'module reports the btw game root'
Assert-True ((Get-RepoRoot) -eq $repoRoot) 'module reports the repository root'

# Arrange / Act / Assert: largest-monitor helper returns a real desktop mode
$monitor = Get-LargestMonitor
Assert-True (-not (Test-PanelDesktopMode -Width 3620 -Height 2036 -Bits 32 -Refresh 60)) 'oversized custom timings are not treated as panel native'
Assert-True (Test-PanelDesktopMode -Width 2560 -Height 1440 -Bits 32 -Refresh 60) '2560x1440 is a real panel mode'
Assert-True (Test-PanelDesktopMode -Width 3840 -Height 2160 -Bits 32 -Refresh 60) '3840x2160 is a real panel mode'
Assert-True ($monitor.NativeWidth -ge $monitor.Width) 'largest monitor reports a native mode at least as large as the current mode'
Assert-True ($monitor.NativeHeight -ge $monitor.Height) 'largest monitor native height is usable'
$realDisplays = @(Get-AttachedDisplays | Where-Object { -not $_.Virtual })
if ($realDisplays.Count -eq 0) { $realDisplays = @(Get-AttachedDisplays) }
$maxNative = ($realDisplays | Measure-Object NativePixels -Maximum).Maximum
Assert-True ($monitor.NativePixels -eq $maxNative) 'largest monitor is the attached panel with the most native pixels'

# Arrange / Act / Assert: DisplayResolution rewrite keeps other keys
$iniTmp = Join-Path $env:TEMP 'cossacks-classic-ddraw-test.ini'
Set-Content -LiteralPath $iniTmp -Value "DisplayResolution = desktop`r`nDisplayAspectRatio = 4:3`r`nSupportedResolutions = native`r`n" -NoNewline
Set-IniDisplayResolution -Path $iniTmp -Width 1920 -Height 1080
$rewritten = Get-Content -LiteralPath $iniTmp -Raw
Assert-True ($rewritten -match 'DisplayResolution = 1920x1080') 'DisplayResolution is patched to the target monitor'
Assert-True ($rewritten -match 'DisplayAspectRatio = 4:3') 'DisplayResolution patch leaves 4:3 in place'

# Arrange / Act / Assert: SupportedResolutions includes DPI-virtualized desktop size
Set-IniSupportedResolutions -Path $iniTmp -Value 'native, 640x480, 800x600, 1024x768, 2560x1440'
$supported = Get-Content -LiteralPath $iniTmp -Raw
Assert-True ($supported -match 'SupportedResolutions = native, 640x480, 800x600, 1024x768, 2560x1440') 'SupportedResolutions rewrite keeps listed modes'
Assert-True ($supported -match 'DisplayAspectRatio = 4:3') 'SupportedResolutions patch leaves 4:3 in place'
Remove-Item -LiteralPath $iniTmp -Force

$virtual = Get-DpiVirtualizedDesktopSize
Assert-True ($virtual.Width -ge 640 -and $virtual.Height -ge 480) 'DPI-unaware desktop size is a real mode'
$listed = Get-SupportedResolutionValue
Assert-True ($listed -match 'native') 'supported list keeps native'
Assert-True ($listed -match '1024x768') 'supported list keeps 1024x768'
Assert-True ($listed -match [regex]::Escape(('{0}x{1}' -f $virtual.Width, $virtual.Height))) 'supported list includes DPI-unaware GetSystemMetrics size'
Assert-True ($listed -match [regex]::Escape(('{0}x{1}' -f $monitor.NativeWidth, $monitor.NativeHeight))) 'supported list includes largest native monitor'
$present = Get-MonitorPresentSize -Monitor $monitor
Assert-True ($present.Width -ge 640 -and $present.Height -ge 480) 'DPI-virtualized present size is usable'
Assert-True ($present.PhysicalWidth -eq $monitor.Width) 'DPI-virtualized size still knows the physical panel'

$iniPresent = Join-Path $env:TEMP 'cossacks-classic-ddraw-present.ini'
Set-Content -LiteralPath $iniPresent -Value "DisplayResolution = desktop`r`nDisplayAspectRatio = 4:3`r`nSupportedResolutions = native`r`n" -NoNewline
Update-CossacksPresentIni -Path $iniPresent
$presentIni = Get-Content -LiteralPath $iniPresent -Raw
Assert-True ($presentIni -match [regex]::Escape(('DisplayResolution = {0}x{1}' -f $monitor.NativeWidth, $monitor.NativeHeight))) 'present target is the native physical mode, not a DPI-virtualized 16:9 mode'
Assert-True ($presentIni -match 'DisplayAspectRatio = 4:3') 'native present patch leaves 4:3 in place'
Remove-Item -LiteralPath $iniPresent -Force

if ($failed -gt 0) {
    Write-Error "$failed assertion(s) failed"
    exit 1
}
Write-Host 'All assertions passed.'

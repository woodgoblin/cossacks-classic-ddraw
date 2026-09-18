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
Assert-True ($classic -match 'FullscreenMode = borderless') 'classic preset is borderless so GDI and the flip chain can both present'
Assert-True ($classic -match 'AltTabFix = keepvidmem\(1\)') 'classic preset keeps vidmem across Alt+Tab'
Assert-True ($classic -match 'CompatFixes = nowindowborders') 'classic preset does not pin the Windows primary'
Assert-True ($classic -notmatch 'singlemonitor') 'classic preset is not locked to the primary monitor'
Assert-True ($classic -match 'GdiInterops = all') 'classic preset composites GDI onto the DirectDraw primary'
Assert-True ($classic -match 'FpsLimiter = msgloop\(60\)') 'classic preset caps the menu loop'
Assert-True ($classic -match 'BltFilter = point') 'classic preset keeps point blits'
Assert-True ($classic -notmatch 'DisplayFilter = bilinear') 'classic preset does not bilinear-filter'
Assert-True ($classic -match 'SupportedResolutions = native, 640x480, 800x600, 1024x768') 'classic preset keeps native modes for csemu init'

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
Assert-True ($monitor.Width -ge 640 -and $monitor.Height -ge 480) 'largest monitor reports a desktop mode'

# Arrange / Act / Assert: DisplayResolution rewrite keeps other keys
$iniTmp = Join-Path $env:TEMP 'cossacks-classic-ddraw-test.ini'
Set-Content -LiteralPath $iniTmp -Value "DisplayResolution = desktop`r`nDisplayAspectRatio = 4:3`r`n" -NoNewline
Set-IniDisplayResolution -Path $iniTmp -Width 1920 -Height 1080
$rewritten = Get-Content -LiteralPath $iniTmp -Raw
Assert-True ($rewritten -match 'DisplayResolution = 1920x1080') 'DisplayResolution is patched to the target monitor'
Assert-True ($rewritten -match 'DisplayAspectRatio = 4:3') 'DisplayResolution patch leaves 4:3 in place'
Remove-Item -LiteralPath $iniTmp -Force

if ($failed -gt 0) {
    Write-Error "$failed assertion(s) failed"
    exit 1
}
Write-Host 'All assertions passed.'

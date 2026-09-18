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
Assert-True ($classic -match 'FullscreenMode = borderless') 'classic preset is borderless for Alt+Tab'
Assert-True ($classic -match 'FpsLimiter = msgloop\(60\)') 'classic preset caps the menu loop'
Assert-True ($classic -match 'BltFilter = point') 'classic preset keeps point blits'
Assert-True ($classic -notmatch 'DisplayFilter = bilinear') 'classic preset does not bilinear-filter'
Assert-True ($classic -match 'SupportedResolutions = 800x600, 1024x768') 'classic preset hides widescreen modes'

$binCandidate = 'W:\SteamLibrary\steamapps\common\Cossacks Back to War\bin'
if (Test-Path -LiteralPath $binCandidate) {
    Assert-True (Test-CossacksBin $binCandidate) 'local Steam bin looks like Back to War'
}

Assert-True ((Get-GameRoot) -eq $gameRoot) 'module reports the btw game root'
Assert-True ((Get-RepoRoot) -eq $repoRoot) 'module reports the repository root'

if ($failed -gt 0) {
    Write-Error "$failed assertion(s) failed"
    exit 1
}
Write-Host 'All assertions passed.'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    Split-Path -Parent $PSScriptRoot
}

function Get-SteamPath {
    $exe = Get-ItemPropertyValue -Path 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue
    if ($exe) {
        return [IO.Path]::GetFullPath(($exe -replace '/', '\'))
    }
    foreach ($candidate in @(
            "${env:ProgramFiles(x86)}\Steam",
            "$env:ProgramFiles\Steam"
        )) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'steam.exe')) {
            return $candidate
        }
    }
    return $null
}

function Test-CossacksBin {
    param([Parameter(Mandatory = $true)][string]$Path)
    $dmcr = Join-Path $Path 'dmcr.exe'
    $csemu = Join-Path $Path 'csemu.dll'
    return (Test-Path -LiteralPath $dmcr) -and (Test-Path -LiteralPath $csemu)
}

function Get-CossacksBinPath {
    param([string]$Override)

    if ($Override) {
        $full = [IO.Path]::GetFullPath($Override)
        if (-not (Test-CossacksBin $full)) {
            throw "Not a Cossacks: Back to War bin folder: $full"
        }
        return $full
    }

    $known = @(
        'W:\SteamLibrary\steamapps\common\Cossacks Back to War\bin',
        'C:\Program Files (x86)\Steam\steamapps\common\Cossacks Back to War\bin'
    )
    foreach ($path in $known) {
        if (Test-CossacksBin $path) { return $path }
    }

    $steam = Get-SteamPath
    if ($steam) {
        $libraryFolders = Join-Path $steam 'steamapps\libraryfolders.vdf'
        $roots = New-Object System.Collections.Generic.List[string]
        [void]$roots.Add($steam)
        if (Test-Path -LiteralPath $libraryFolders) {
            $text = Get-Content -LiteralPath $libraryFolders -Raw
            [regex]::Matches($text, '"path"\s+"([^"]+)"') | ForEach-Object {
                $root = $_.Groups[1].Value -replace '\\\\', '\'
                if (-not $roots.Contains($root)) { [void]$roots.Add($root) }
            }
        }
        foreach ($root in $roots) {
            $bin = Join-Path $root 'steamapps\common\Cossacks Back to War\bin'
            if (Test-CossacksBin $bin) { return $bin }
        }
    }

    throw 'Could not find Cossacks: Back to War. Pass -GameBin to the installer.'
}

function Get-BackupRoot {
    param([Parameter(Mandatory = $true)][string]$GameBin)
    Join-Path $GameBin 'classic-ddraw-backup'
}

function Backup-ExistingFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    if (-not (Test-Path -LiteralPath $BackupRoot)) {
        New-Item -ItemType Directory -Path $BackupRoot | Out-Null
    }
    $name = Split-Path -Leaf $Path
    $dest = Join-Path $BackupRoot $name
    if (-not (Test-Path -LiteralPath $dest)) {
        Copy-Item -LiteralPath $Path -Destination $dest
    }
    return $dest
}

function Restore-BackupFile {
    param(
        [Parameter(Mandatory = $true)][string]$BackupRoot,
        [Parameter(Mandatory = $true)][string]$Destination
    )
    $name = Split-Path -Leaf $Destination
    $src = Join-Path $BackupRoot $name
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination $Destination -Force
        return $true
    }
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Force
    }
    return $false
}

function Set-ModeDatResolution {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content,
        [Parameter(Mandatory = $true)][int]$Width,
        [Parameter(Mandatory = $true)][int]$Height,
        [int]$Refresh = 60
    )
    if ($Width -le 0 -or $Height -le 0) {
        throw "Invalid resolution ${Width}x${Height}"
    }
    $parts = @($Content.Trim() -split '\s+')
    if ($parts.Count -lt 2) {
        $parts = @("$Width", "$Height", "$Refresh", '0', '0', '0', '61', '6', '1', '2')
    }
    else {
        $parts[0] = "$Width"
        $parts[1] = "$Height"
        if ($parts.Count -ge 3 -and $parts[2] -match '^\d+$') {
            $parts[2] = "$Refresh"
        }
    }
    return ($parts -join ' ')
}

function Write-ModeDatResolution {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Width,
        [Parameter(Mandatory = $true)][int]$Height,
        [int]$Refresh = 60
    )
    $existing = ''
    if (Test-Path -LiteralPath $Path) {
        $existing = Get-Content -LiteralPath $Path -Raw
    }
    $next = Set-ModeDatResolution -Content $existing -Width $Width -Height $Height -Refresh $Refresh
    [IO.File]::WriteAllText($Path, $next)
}

function Get-PresetPath {
    param(
        [ValidateSet('classic', 'integer', 'menu-gdi-off')]
        [string]$Preset = 'classic'
    )
    $map = @{
        'classic'      = 'DDrawCompat.ini'
        'integer'      = 'DDrawCompat.integer.ini'
        'menu-gdi-off' = 'DDrawCompat.menu-gdi-off.ini'
    }
    Join-Path (Join-Path (Get-RepoRoot) 'presets') $map[$Preset]
}

function Get-DDrawCompatRelease {
    param([string]$Tag = 'v0.7.1')
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/narzoul/DDrawCompat/releases?per_page=10' -Headers @{
        'User-Agent' = 'cossacks-btw-classic-ddraw'
    }
    $release = $releases | Where-Object { $_.tag_name -eq $Tag } | Select-Object -First 1
    if (-not $release) {
        $release = $releases | Select-Object -First 1
    }
    $asset = $release.assets | Where-Object { $_.name -like 'DDrawCompat-v*.zip' -and $_.name -notlike '*debug*' } | Select-Object -First 1
    if (-not $asset) {
        throw 'Could not find a DDrawCompat zip asset.'
    }
    return [pscustomobject]@{
        Tag         = $release.tag_name
        Name        = $asset.name
        DownloadUrl = $asset.browser_download_url
    }
}

function Install-DDrawCompatBinary {
    param(
        [Parameter(Mandatory = $true)][string]$GameBin,
        [string]$Tag = 'v0.7.1',
        [string]$CacheDir
    )
    if (-not $CacheDir) {
        $CacheDir = Join-Path (Get-RepoRoot) '.cache'
    }
    if (-not (Test-Path -LiteralPath $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir | Out-Null
    }

    $release = Get-DDrawCompatRelease -Tag $Tag
    $zipPath = Join-Path $CacheDir $release.Name
    if (-not (Test-Path -LiteralPath $zipPath)) {
        Invoke-WebRequest -Uri $release.DownloadUrl -OutFile $zipPath -UseBasicParsing
    }

    $extract = Join-Path $CacheDir ('extract-' + $release.Tag)
    if (Test-Path -LiteralPath $extract) {
        Remove-Item -LiteralPath $extract -Recurse -Force
    }
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force

    $dll = Get-ChildItem -LiteralPath $extract -Filter 'ddraw.dll' -Recurse | Select-Object -First 1
    if (-not $dll) {
        throw 'ddraw.dll was not in the DDrawCompat zip.'
    }

    Copy-Item -LiteralPath $dll.FullName -Destination (Join-Path $GameBin 'ddraw.dll') -Force
    Copy-Item -LiteralPath $dll.FullName -Destination (Join-Path $GameBin 'dciman32.dll') -Force
    return $release
}

function Set-CossacksCompatibilityFlags {
    param([Parameter(Mandatory = $true)][string]$GameBin)

    $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    if (-not (Test-Path -LiteralPath $key)) {
        New-Item -Path $key -Force | Out-Null
    }
    foreach ($name in @('dmcr.exe', 'csbtw.exe')) {
        $exe = Join-Path $GameBin $name
        if (Test-Path -LiteralPath $exe) {
            New-ItemProperty -Path $key -Name $exe -Value '~ HIGHDPIAWARE' -PropertyType String -Force | Out-Null
        }
    }
}

function Remove-CossacksCompatibilityFlags {
    param([Parameter(Mandatory = $true)][string]$GameBin)
    $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    if (-not (Test-Path -LiteralPath $key)) { return }
    foreach ($name in @('dmcr.exe', 'csbtw.exe')) {
        $exe = Join-Path $GameBin $name
        Remove-ItemProperty -Path $key -Name $exe -ErrorAction SilentlyContinue
    }
}

function Get-SteamOverlayInstructions {
    return @(
        'In Steam: right-click Cossacks: Back to War -> Properties',
        'uncheck "Enable the Steam Overlay while in-game".',
        'Launch with "Cossacks Classic 4x3.bat" instead of the Steam Play button.'
    )
}

function Write-Launcher {
    param(
        [Parameter(Mandatory = $true)][string]$GameBin
    )
    $bat = @"
@echo off
setlocal
cd /d "$GameBin"
if exist dmcr.exe (
  start "" /wait dmcr.exe
) else (
  echo dmcr.exe not found in $GameBin
  exit /b 1
)
"@
    $path = Join-Path $GameBin 'Cossacks Classic 4x3.bat'
    [IO.File]::WriteAllText($path, $bat)
    return $path
}

function Enable-DirectPlayFeature {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName DirectPlay -ErrorAction Stop
    if ($feature.State -eq 'Enabled') {
        return 'already-enabled'
    }
    Enable-WindowsOptionalFeature -Online -FeatureName DirectPlay -All -NoRestart | Out-Null
    return 'enabled'
}

Export-ModuleMember -Function @(
    'Get-RepoRoot',
    'Get-SteamPath',
    'Test-CossacksBin',
    'Get-CossacksBinPath',
    'Get-BackupRoot',
    'Backup-ExistingFile',
    'Restore-BackupFile',
    'Set-ModeDatResolution',
    'Write-ModeDatResolution',
    'Get-PresetPath',
    'Get-DDrawCompatRelease',
    'Install-DDrawCompatBinary',
    'Set-CossacksCompatibilityFlags',
    'Remove-CossacksCompatibilityFlags',
    'Get-SteamOverlayInstructions',
    'Write-Launcher',
    'Enable-DirectPlayFeature'
)

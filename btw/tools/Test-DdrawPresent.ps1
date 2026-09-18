# Replays Steam csemu's DirectDraw init against DDrawCompat and records
# whether the flip chain exists and whether present actually lights pixels.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$tools = $PSScriptRoot
$gameRoot = Split-Path -Parent $tools
$repoRoot = Split-Path -Parent $gameRoot
Import-Module -Force -Name (Join-Path $gameRoot 'scripts\CossacksClassic.psm1')

$csc = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc)) {
    throw '32-bit csc.exe is required to compile the DirectDraw probe.'
}

$src = Join-Path $tools 'DdrawProbe\DdrawProbe.cs'
$work = Join-Path (Join-Path $repoRoot '.cache') 'ddraw-probe'
if (-not (Test-Path -LiteralPath $work)) {
    New-Item -ItemType Directory -Path $work | Out-Null
}
$exe = Join-Path $work 'DdrawProbe.exe'
& $csc /nologo /platform:x86 /target:exe /out:$exe /r:System.Drawing.dll /r:System.Windows.Forms.dll $src
if ($LASTEXITCODE -ne 0) {
    throw 'DdrawProbe compile failed.'
}

$bin = Get-CossacksBinPath
$dciman = Join-Path $bin 'dciman32.dll'
if (-not (Test-Path -LiteralPath $dciman)) {
    throw "dciman32.dll missing in $bin"
}
Copy-Item -LiteralPath $dciman -Destination (Join-Path $work 'dciman32.dll') -Force

$preset = Get-Content -LiteralPath (Get-PresetPath -Preset classic) -Raw
$monitor = Get-LargestMonitor

function New-ProbeIni {
    param([string]$FullscreenMode)
    $text = $preset
    $text = [regex]::Replace($text, '(?m)^FullscreenMode\s*=.*$', "FullscreenMode = $FullscreenMode")
    $text = [regex]::Replace($text, '(?m)^LogLevel\s*=.*$', 'LogLevel = info')
    return $text
}

function Invoke-Probe {
    param(
        [string]$Name,
        [string]$FullscreenMode
    )
    $ini = New-ProbeIni -FullscreenMode $FullscreenMode
    $iniPath = Join-Path $work 'DDrawCompat.ini'
    [IO.File]::WriteAllText($iniPath, $ini)
    Set-IniDisplayResolution -Path $iniPath -Width $monitor.Width -Height $monitor.Height
    Copy-Item -LiteralPath $iniPath -Destination (Join-Path $work 'DDrawCompat-DdrawProbe.ini') -Force

    $jsonPath = Join-Path $work ("probe-$Name.json")
    $logPath = Join-Path $work 'DDrawCompat-DdrawProbe.log'
    if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }

    $p = Start-Process -FilePath $exe -WorkingDirectory $work -PassThru -Wait -ArgumentList @(
        '--hold-ms', '1200',
        '--out', $jsonPath,
        '--sample-x', [string]($monitor.X + [int]($monitor.Width / 2)),
        '--sample-y', [string]($monitor.Y + [int]($monitor.Height / 2))
    )
    $json = '{}'
    if (Test-Path -LiteralPath $jsonPath) {
        $json = Get-Content -LiteralPath $jsonPath -Raw
    }
    [pscustomobject]@{
        Name     = $Name
        Mode     = $FullscreenMode
        ExitCode = $p.ExitCode
        Json     = $json.Trim()
        LogPath  = $logPath
    }
}

Write-Host "Probe exe: $exe"
Write-Host ("Target monitor: {0}x{1} {2}" -f $monitor.Width, $monitor.Height, $monitor.DeviceString)
$exclusive = Invoke-Probe -Name 'exclusive' -FullscreenMode 'exclusive'
Start-Sleep -Milliseconds 400
$borderless = Invoke-Probe -Name 'borderless' -FullscreenMode 'borderless'

Write-Host '==== exclusive (csemu path) ===='
Write-Host $exclusive.Json
Write-Host '==== borderless ===='
Write-Host $borderless.Json

$failed = 0
foreach ($run in @($exclusive, $borderless)) {
    if ($run.Json -notmatch '"getAttachedSurface":"0x00000000"') {
        Write-Host "FAIL $($run.Name) GetAttachedSurface"
        $failed++
    }
    else {
        Write-Host "PASS $($run.Name) GetAttachedSurface"
    }
    if ($run.Json -notmatch '"primaryAvg":"FF00FF"') {
        Write-Host "FAIL $($run.Name) primary did not keep the magenta fill after Flip"
        $failed++
    }
    else {
        Write-Host "PASS $($run.Name) primary contains magenta after Flip"
    }
}
if ($failed -gt 0) {
    Write-Error "$failed DirectDraw present assertion(s) failed"
    exit 1
}
Write-Host 'All present assertions passed.'

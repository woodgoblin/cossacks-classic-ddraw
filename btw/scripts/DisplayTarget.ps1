Set-StrictMode -Version Latest

if (-not ('CossacksDisplayNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct CossacksPoint {
    public int X;
    public int Y;
    public CossacksPoint(int x, int y) { X = x; Y = y; }
}

public static class CossacksDisplayNative {
    public const int DISPLAY_DEVICE_ATTACHED_TO_DESKTOP = 0x00000001;
    public const int DISPLAY_DEVICE_PRIMARY_DEVICE = 0x00000004;
    public const int DISPLAY_DEVICE_MIRRORING_DRIVER = 0x00000008;
    public const int ENUM_CURRENT_SETTINGS = -1;
    public const int DM_POSITION = 0x00000020;
    public const int DM_PELSWIDTH = 0x00080000;
    public const int DM_PELSHEIGHT = 0x00100000;
    public const int DM_BITSPERPEL = 0x00040000;
    public const int DM_DISPLAYFREQUENCY = 0x00400000;
    public const uint CDS_UPDATEREGISTRY = 0x00000001;
    public const uint CDS_SET_PRIMARY = 0x00000010;
    public const uint CDS_NORESET = 0x10000000;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DISPLAY_DEVICE {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceKey;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "EnumDisplayDevicesW")]
    public static extern bool EnumDisplayDevices(IntPtr lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "EnumDisplayDevicesW")]
    public static extern bool EnumDisplayDevicesOnAdapter(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern bool EnumDisplaySettings(string lpszDeviceName, int iModeNum, ref DEVMODE lpDevMode);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE lpDevMode, IntPtr hwnd, uint dwflags, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "ChangeDisplaySettingsEx")]
    public static extern int ApplyDisplaySettings(IntPtr lpszDeviceName, IntPtr lpDevMode, IntPtr hwnd, uint dwflags, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr dpiContext);

    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);

    [DllImport("user32.dll")]
    public static extern IntPtr MonitorFromPoint(CossacksPoint pt, uint dwFlags);

    [DllImport("shcore.dll")]
    public static extern int GetDpiForMonitor(IntPtr hmonitor, int dpiType, out uint dpiX, out uint dpiY);

    public const int SM_CXSCREEN = 0;
    public const int SM_CYSCREEN = 1;
    public const uint MONITOR_DEFAULTTONEAREST = 2;
    public const int MDT_EFFECTIVE_DPI = 0;
    public static readonly IntPtr DpiUnaware = new IntPtr(-1);
    public static readonly IntPtr DpiPerMonitorV2 = new IntPtr(-4);

    public static DISPLAY_DEVICE NewDevice() {
        DISPLAY_DEVICE d = new DISPLAY_DEVICE();
        d.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
        return d;
    }

    public static DEVMODE NewMode() {
        DEVMODE m = new DEVMODE();
        m.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
        return m;
    }
}
'@
}

function Test-VirtualMonitorName {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    return $Text -match 'Meta|Oculus|Quest|Virtual|VBS|Remote\s*Desktop|Parsec|Sunshine|SteamVR|Miracast|Wireless Display|NVIDIA Virtual'
}

function Get-AttachedDisplays {
    [void][CossacksDisplayNative]::SetThreadDpiAwarenessContext([CossacksDisplayNative]::DpiPerMonitorV2)
    $attached = [CossacksDisplayNative]::DISPLAY_DEVICE_ATTACHED_TO_DESKTOP
    $primaryFlag = [CossacksDisplayNative]::DISPLAY_DEVICE_PRIMARY_DEVICE
    $mirrorFlag = [CossacksDisplayNative]::DISPLAY_DEVICE_MIRRORING_DRIVER

    for ($i = 0; $i -lt 32; $i++) {
        $adapter = [CossacksDisplayNative]::NewDevice()
        if (-not [CossacksDisplayNative]::EnumDisplayDevices([IntPtr]::Zero, [uint32]$i, [ref]$adapter, 0)) { break }
        if (($adapter.StateFlags -band $attached) -eq 0) { continue }
        if (($adapter.StateFlags -band $mirrorFlag) -ne 0) { continue }

        $mode = [CossacksDisplayNative]::NewMode()
        if (-not [CossacksDisplayNative]::EnumDisplaySettings($adapter.DeviceName, [CossacksDisplayNative]::ENUM_CURRENT_SETTINGS, [ref]$mode)) {
            continue
        }
        if ($mode.dmPelsWidth -lt 640 -or $mode.dmPelsHeight -lt 480) { continue }

        $monitor = [CossacksDisplayNative]::NewDevice()
        $monitorName = $adapter.DeviceString
        $monitorId = $adapter.DeviceID
        if ([CossacksDisplayNative]::EnumDisplayDevicesOnAdapter($adapter.DeviceName, 0, [ref]$monitor, 0)) {
            if ($monitor.DeviceString) { $monitorName = $monitor.DeviceString }
            if ($monitor.DeviceID) { $monitorId = $monitor.DeviceID }
        }

        $virtual = (Test-VirtualMonitorName $adapter.DeviceString) -or
            (Test-VirtualMonitorName $monitorName) -or
            (Test-VirtualMonitorName $monitorId)
        $native = Get-AdapterNativeMode -DeviceName $adapter.DeviceName
        [pscustomobject]@{
            DeviceName     = $adapter.DeviceName
            DeviceString   = $monitorName
            Width          = [int]$mode.dmPelsWidth
            Height         = [int]$mode.dmPelsHeight
            NativeWidth    = [int]$native.Width
            NativeHeight   = [int]$native.Height
            NativeRefresh  = [int]$native.Refresh
            NativeBits     = [int]$native.Bits
            X              = [int]$mode.dmPositionX
            Y              = [int]$mode.dmPositionY
            Pixels         = [int]$mode.dmPelsWidth * [int]$mode.dmPelsHeight
            NativePixels   = [int]$native.Width * [int]$native.Height
            Primary        = (($adapter.StateFlags -band $primaryFlag) -ne 0)
            Virtual        = [bool]$virtual
        }
    }
}

function Test-PanelDesktopMode {
    param(
        [int]$Width,
        [int]$Height,
        [int]$Bits,
        [int]$Refresh
    )
    if ($Width -lt 640 -or $Height -lt 480) { return $false }
    if ($Bits -gt 0 -and $Bits -lt 32) { return $false }
    if ($Refresh -gt 0 -and ($Refresh -lt 50 -or $Refresh -gt 240)) { return $false }
    if (($Width % 8) -ne 0 -or ($Height % 8) -ne 0) { return $false }
    return $true
}

function Get-AdapterNativeMode {
    param([Parameter(Mandatory = $true)][string]$DeviceName)
    $best = $null
    for ($n = 0; $n -lt 1024; $n++) {
        $mode = [CossacksDisplayNative]::NewMode()
        if (-not [CossacksDisplayNative]::EnumDisplaySettings($DeviceName, $n, [ref]$mode)) { break }
        if (-not (Test-PanelDesktopMode -Width $mode.dmPelsWidth -Height $mode.dmPelsHeight -Bits $mode.dmBitsPerPel -Refresh $mode.dmDisplayFrequency)) {
            continue
        }
        $candidate = [pscustomobject]@{
            Width   = [int]$mode.dmPelsWidth
            Height  = [int]$mode.dmPelsHeight
            Refresh = [int]$mode.dmDisplayFrequency
            Bits    = [int]$mode.dmBitsPerPel
            Pixels  = [int]$mode.dmPelsWidth * [int]$mode.dmPelsHeight
            DevMode = $mode
        }
        if (-not $best) {
            $best = $candidate
            continue
        }
        if ($candidate.Pixels -gt $best.Pixels) { $best = $candidate; continue }
        if ($candidate.Pixels -eq $best.Pixels -and $candidate.Bits -gt $best.Bits) { $best = $candidate; continue }
        if ($candidate.Pixels -eq $best.Pixels -and $candidate.Bits -eq $best.Bits -and $candidate.Refresh -gt $best.Refresh) {
            $best = $candidate
        }
    }
    if (-not $best) {
        throw "No native mode for $DeviceName"
    }
    return $best
}

function Get-LargestMonitor {
    $all = @(Get-AttachedDisplays)
    if ($all.Count -eq 0) {
        throw 'No attached displays.'
    }
    $real = @($all | Where-Object { -not $_.Virtual })
    if ($real.Count -eq 0) { $real = $all }
    $real | Sort-Object NativePixels, Width, Height -Descending | Select-Object -First 1
}

function Restore-MonitorNativeMode {
    param([Parameter(Mandatory = $true)]$Monitor)
    if ($Monitor.Width -eq $Monitor.NativeWidth -and $Monitor.Height -eq $Monitor.NativeHeight) {
        return
    }
    $native = Get-AdapterNativeMode -DeviceName $Monitor.DeviceName
    $mode = $null
    for ($n = 0; $n -lt 1024; $n++) {
        $candidate = [CossacksDisplayNative]::NewMode()
        if (-not [CossacksDisplayNative]::EnumDisplaySettings($Monitor.DeviceName, $n, [ref]$candidate)) { break }
        if ($candidate.dmPelsWidth -ne $native.Width) { continue }
        if ($candidate.dmPelsHeight -ne $native.Height) { continue }
        if ($candidate.dmBitsPerPel -ne $native.Bits) { continue }
        if ($candidate.dmDisplayFrequency -ne $native.Refresh) { continue }
        $mode = $candidate
        break
    }
    if ($null -eq $mode) {
        Write-Warning ("Could not restore {0}: native {1}x{2} was not in the mode list." -f $Monitor.DeviceString, $native.Width, $native.Height)
        return
    }
    $mode.dmFields = [CossacksDisplayNative]::DM_PELSWIDTH -bor
        [CossacksDisplayNative]::DM_PELSHEIGHT -bor
        [CossacksDisplayNative]::DM_BITSPERPEL -bor
        [CossacksDisplayNative]::DM_DISPLAYFREQUENCY
    $result = [CossacksDisplayNative]::ChangeDisplaySettingsEx(
        $Monitor.DeviceName,
        [ref]$mode,
        [IntPtr]::Zero,
        [CossacksDisplayNative]::CDS_UPDATEREGISTRY,
        [IntPtr]::Zero
    )
    if ($result -ne 0) {
        Write-Warning ("Could not restore {0} to {1}x{2}: CDS {3}" -f $Monitor.DeviceString, $native.Width, $native.Height, $result)
        return
    }
    Write-Host ("Restored {0} from {1}x{2} to native {3}x{4}." -f $Monitor.DeviceString, $Monitor.Width, $Monitor.Height, $native.Width, $native.Height)
}

function Set-PrimaryMonitor {
    param([Parameter(Mandatory = $true)]$Monitor)
    if ($Monitor.Primary) { return }
    $all = @(Get-AttachedDisplays | Where-Object { -not $_.Virtual })
    if ($all.Count -eq 0) { $all = @(Get-AttachedDisplays) }
    $dx = -$Monitor.X
    $dy = -$Monitor.Y
    foreach ($display in $all) {
        $mode = [CossacksDisplayNative]::NewMode()
        if (-not [CossacksDisplayNative]::EnumDisplaySettings($display.DeviceName, [CossacksDisplayNative]::ENUM_CURRENT_SETTINGS, [ref]$mode)) {
            continue
        }
        $mode.dmPositionX = $display.X + $dx
        $mode.dmPositionY = $display.Y + $dy
        $mode.dmFields = [CossacksDisplayNative]::DM_POSITION
        $flags = [CossacksDisplayNative]::CDS_UPDATEREGISTRY -bor [CossacksDisplayNative]::CDS_NORESET
        if ($display.DeviceName -eq $Monitor.DeviceName) {
            $flags = $flags -bor [CossacksDisplayNative]::CDS_SET_PRIMARY
        }
        $result = [CossacksDisplayNative]::ChangeDisplaySettingsEx(
            $display.DeviceName,
            [ref]$mode,
            [IntPtr]::Zero,
            $flags,
            [IntPtr]::Zero
        )
        if ($result -ne 0) {
            Write-Warning ("Could not retarget primary onto {0}: CDS {1}" -f $display.DeviceString, $result)
            return
        }
    }
    [void][CossacksDisplayNative]::ApplyDisplaySettings(
        [IntPtr]::Zero,
        [IntPtr]::Zero,
        [IntPtr]::Zero,
        0,
        [IntPtr]::Zero
    )
}

function Initialize-CossacksPresentTarget {
    param([string[]]$IniPath = @())
    $monitor = Get-LargestMonitor
    Restore-MonitorNativeMode -Monitor $monitor
    $monitor = Get-LargestMonitor
    foreach ($path in @($IniPath)) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            Update-CossacksPresentIni -Path $path
        }
    }
    Move-CursorToMonitor -Monitor $monitor
    return $monitor
}

function Get-MonitorPresentSize {
    param([Parameter(Mandatory = $true)]$Monitor)
    $x = $Monitor.X + [int]($Monitor.Width / 2)
    $y = $Monitor.Y + [int]($Monitor.Height / 2)
    $pt = New-Object CossacksPoint -ArgumentList $x, $y
    $hmon = [CossacksDisplayNative]::MonitorFromPoint($pt, [CossacksDisplayNative]::MONITOR_DEFAULTTONEAREST)
    [uint32]$dpiX = 96
    [uint32]$dpiY = 96
    if ($hmon -ne [IntPtr]::Zero) {
        [void][CossacksDisplayNative]::GetDpiForMonitor($hmon, [CossacksDisplayNative]::MDT_EFFECTIVE_DPI, [ref]$dpiX, [ref]$dpiY)
    }
    if ($dpiX -lt 96) { $dpiX = 96 }
    if ($dpiY -lt 96) { $dpiY = 96 }
    $width = [int][math]::Round($Monitor.Width * 96.0 / $dpiX)
    $height = [int][math]::Round($Monitor.Height * 96.0 / $dpiY)
    if ($width -lt 640) { $width = [int]$Monitor.Width }
    if ($height -lt 480) { $height = [int]$Monitor.Height }
    [pscustomobject]@{
        Width          = $width
        Height         = $height
        PhysicalWidth  = [int]$Monitor.Width
        PhysicalHeight = [int]$Monitor.Height
        Dpi            = [int]$dpiX
        DeviceString   = $Monitor.DeviceString
    }
}

function Get-DpiVirtualizedDesktopSize {
    $prev = [CossacksDisplayNative]::SetThreadDpiAwarenessContext([CossacksDisplayNative]::DpiUnaware)
    try {
        [pscustomobject]@{
            Width  = [CossacksDisplayNative]::GetSystemMetrics([CossacksDisplayNative]::SM_CXSCREEN)
            Height = [CossacksDisplayNative]::GetSystemMetrics([CossacksDisplayNative]::SM_CYSCREEN)
        }
    }
    finally {
        if ($prev -ne [IntPtr]::Zero) {
            [void][CossacksDisplayNative]::SetThreadDpiAwarenessContext($prev)
        }
    }
}

function Get-SupportedResolutionValue {
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $parts = New-Object 'System.Collections.Generic.List[string]'
    foreach ($item in @('native', '640x480', '800x600', '1024x768')) {
        if ($seen.Add($item)) { $parts.Add($item) }
    }
    $virtual = Get-DpiVirtualizedDesktopSize
    foreach ($mode in @($virtual) + @(Get-AttachedDisplays)) {
        $candidates = @(@{ Width = $mode.Width; Height = $mode.Height })
        if ($mode.PSObject.Properties['NativeWidth']) {
            $candidates += @{ Width = $mode.NativeWidth; Height = $mode.NativeHeight }
        }
        foreach ($candidate in $candidates) {
            if (-not (Test-PanelDesktopMode -Width $candidate.Width -Height $candidate.Height -Bits 32 -Refresh 60)) {
                continue
            }
            $key = '{0}x{1}' -f $candidate.Width, $candidate.Height
            if ($seen.Add($key)) { $parts.Add($key) }
        }
    }
    return ($parts -join ', ')
}

function Set-IniKey {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $line = "$Key = $Value"
    $text = ''
    if (Test-Path -LiteralPath $Path) {
        $text = Get-Content -LiteralPath $Path -Raw
    }
    $pattern = '(?m)^' + [regex]::Escape($Key) + '\s*=.*$'
    if ($text -match $pattern) {
        $text = [regex]::Replace($text, $pattern, $line)
    }
    else {
        if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) { $text += "`r`n" }
        $text += $line + "`r`n"
    }
    [IO.File]::WriteAllText($Path, $text)
}

function Set-IniDisplayResolution {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Width,
        [Parameter(Mandatory = $true)][int]$Height
    )
    if ($Width -lt 640 -or $Height -lt 480) {
        throw "DisplayResolution ${Width}x${Height} is not a usable desktop mode."
    }
    Set-IniKey -Path $Path -Key 'DisplayResolution' -Value "${Width}x${Height}"
}

function Set-IniSupportedResolutions {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Value
    )
    Set-IniKey -Path $Path -Key 'SupportedResolutions' -Value $Value
}

function Update-CossacksPresentIni {
    param([Parameter(Mandatory = $true)][string]$Path)
    $monitor = Get-LargestMonitor
    Set-IniDisplayResolution -Path $Path -Width $monitor.NativeWidth -Height $monitor.NativeHeight
    Set-IniSupportedResolutions -Path $Path -Value (Get-SupportedResolutionValue)
}

function Move-CursorToMonitor {
    param([Parameter(Mandatory = $true)]$Monitor)
    $x = [int]($Monitor.X + ($Monitor.Width / 2))
    $y = [int]($Monitor.Y + ($Monitor.Height / 2))
    [void][CossacksDisplayNative]::SetCursorPos($x, $y)
}

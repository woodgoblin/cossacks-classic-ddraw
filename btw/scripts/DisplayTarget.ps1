Set-StrictMode -Version Latest

if (-not ('CossacksDisplayNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class CossacksDisplayNative {
    public const int DISPLAY_DEVICE_ATTACHED_TO_DESKTOP = 0x00000001;
    public const int DISPLAY_DEVICE_PRIMARY_DEVICE = 0x00000004;
    public const int DISPLAY_DEVICE_MIRRORING_DRIVER = 0x00000008;
    public const int ENUM_CURRENT_SETTINGS = -1;

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

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr dpiContext);

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
        [pscustomobject]@{
            DeviceName   = $adapter.DeviceName
            DeviceString = $monitorName
            Width        = [int]$mode.dmPelsWidth
            Height       = [int]$mode.dmPelsHeight
            X            = [int]$mode.dmPositionX
            Y            = [int]$mode.dmPositionY
            Pixels       = [int]$mode.dmPelsWidth * [int]$mode.dmPelsHeight
            Primary      = (($adapter.StateFlags -band $primaryFlag) -ne 0)
            Virtual      = [bool]$virtual
        }
    }
}

function Get-LargestMonitor {
    $all = @(Get-AttachedDisplays)
    if ($all.Count -eq 0) {
        throw 'No attached displays.'
    }
    $real = @($all | Where-Object { -not $_.Virtual })
    if ($real.Count -eq 0) { $real = $all }
    $real | Sort-Object Pixels, Width, Height -Descending | Select-Object -First 1
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
    $line = "DisplayResolution = ${Width}x${Height}"
    $text = ''
    if (Test-Path -LiteralPath $Path) {
        $text = Get-Content -LiteralPath $Path -Raw
    }
    if ($text -match '(?m)^DisplayResolution\s*=') {
        $text = [regex]::Replace($text, '(?m)^DisplayResolution\s*=.*$', $line)
    }
    else {
        if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) { $text += "`r`n" }
        $text += $line + "`r`n"
    }
    [IO.File]::WriteAllText($Path, $text)
}

function Move-CursorToMonitor {
    param([Parameter(Mandatory = $true)]$Monitor)
    $x = [int]($Monitor.X + ($Monitor.Width / 2))
    $y = [int]($Monitor.Y + ($Monitor.Height / 2))
    [void][CossacksDisplayNative]::SetCursorPos($x, $y)
}

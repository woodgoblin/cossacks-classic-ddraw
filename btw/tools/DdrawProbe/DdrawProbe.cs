using System;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

internal static class Native
{
    public const int DDSCL_FULLSCREEN = 0x00000001;
    public const int DDSCL_EXCLUSIVE = 0x00000010;
    public const int DDSD_CAPS = 0x00000001;
    public const int DDSD_BACKBUFFERCOUNT = 0x00000020;
    public const int DDSCAPS_BACKBUFFER = 0x00000004;
    public const int DDSCAPS_COMPLEX = 0x00000008;
    public const int DDSCAPS_FLIP = 0x00000010;
    public const int DDSCAPS_PRIMARYSURFACE = 0x00000200;
    public const int DDBLT_COLORFILL = 0x00000400;
    public const int DDBLT_WAIT = 0x01000000;
    public const int DDFLIP_WAIT = 0x00000001;
    public const int DDLOCK_READONLY = 0x00000010;
    public const int DDLOCK_WAIT = 0x00000001;
    public const int SRCCOPY = 0x00CC0020;

    [DllImport("ddraw.dll")]
    public static extern int DirectDrawCreate(IntPtr guid, out IDirectDraw dd, IntPtr unk);

    [DllImport("user32.dll")]
    public static extern IntPtr GetDC(IntPtr hwnd);

    [DllImport("user32.dll")]
    public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);

    [DllImport("gdi32.dll")]
    public static extern uint GetPixel(IntPtr hdc, int x, int y);

    [DllImport("gdi32.dll")]
    public static extern IntPtr CreateCompatibleDC(IntPtr hdc);

    [DllImport("gdi32.dll")]
    public static extern IntPtr CreateCompatibleBitmap(IntPtr hdc, int w, int h);

    [DllImport("gdi32.dll")]
    public static extern IntPtr SelectObject(IntPtr hdc, IntPtr obj);

    [DllImport("gdi32.dll")]
    public static extern bool BitBlt(IntPtr dst, int x, int y, int w, int h, IntPtr src, int sx, int sy, int rop);

    [DllImport("gdi32.dll")]
    public static extern bool DeleteObject(IntPtr obj);

    [DllImport("user32.dll")]
    public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr dpiContext);
}

[StructLayout(LayoutKind.Sequential)]
internal struct DDCOLORKEY
{
    public int Low;
    public int High;
}

[StructLayout(LayoutKind.Sequential)]
internal struct DDPIXELFORMAT
{
    public int dwSize;
    public int dwFlags;
    public int dwFourCC;
    public int dwRGBBitCount;
    public int dwRBitMask;
    public int dwGBitMask;
    public int dwBBitMask;
    public int dwRGBAlphaBitMask;
}

[StructLayout(LayoutKind.Sequential)]
internal struct DDSCAPS
{
    public int dwCaps;
}

[StructLayout(LayoutKind.Sequential)]
internal struct DDSURFACEDESC
{
    public int dwSize;
    public int dwFlags;
    public int dwHeight;
    public int dwWidth;
    public int lPitch;
    public int dwBackBufferCount;
    public int dwMipMapCount;
    public int dwAlphaBitDepth;
    public int dwReserved;
    public IntPtr lpSurface;
    public DDCOLORKEY ckDestOverlay;
    public DDCOLORKEY ckDestBlt;
    public DDCOLORKEY ckSrcOverlay;
    public DDCOLORKEY ckSrcBlt;
    public DDPIXELFORMAT ddpfPixelFormat;
    public DDSCAPS ddsCaps;
}

[StructLayout(LayoutKind.Sequential)]
internal struct DDBLTFX
{
    public int dwSize;
    public int dwDDFX;
    public int dwROP;
    public int dwDDROP;
    public int dwRotationAngle;
    public int dwZBufferOpCode;
    public int dwZBufferLow;
    public int dwZBufferHigh;
    public int dwZBufferBaseDest;
    public int dwZDestConstBitDepth;
    public int dwZDestConst;
    public int dwZSrcConstBitDepth;
    public int dwZSrcConst;
    public int dwAlphaEdgeBlendBitDepth;
    public int dwAlphaEdgeBlend;
    public int dwReserved;
    public int dwAlphaDestConstBitDepth;
    public int dwAlphaDestConst;
    public int dwAlphaSrcConstBitDepth;
    public int dwAlphaSrcConst;
    public int dwFillColor;
    public int ckDestLow;
    public int ckDestHigh;
    public int ckSrcLow;
    public int ckSrcHigh;
}

[ComImport, Guid("6C14DB80-A733-11CE-A521-0020AF0BE560"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IDirectDraw
{
    [PreserveSig] int Compact();
    [PreserveSig] int CreateClipper(int flags, out IntPtr clipper, IntPtr unk);
    [PreserveSig] int CreatePalette(int flags, IntPtr entries, out IntPtr palette, IntPtr unk);
    [PreserveSig] int CreateSurface(ref DDSURFACEDESC desc, out IDirectDrawSurface surface, IntPtr unk);
    [PreserveSig] int DuplicateSurface(IDirectDrawSurface src, out IDirectDrawSurface dest);
    [PreserveSig] int EnumDisplayModes(int flags, IntPtr desc, IntPtr context, IntPtr callback);
    [PreserveSig] int EnumSurfaces(int flags, IntPtr desc, IntPtr context, IntPtr callback);
    [PreserveSig] int FlipToGDISurface();
    [PreserveSig] int GetCaps(IntPtr driverCaps, IntPtr helCaps);
    [PreserveSig] int GetDisplayMode(ref DDSURFACEDESC desc);
    [PreserveSig] int GetFourCCCodes(IntPtr count, IntPtr codes);
    [PreserveSig] int GetGDISurface(out IDirectDrawSurface surface);
    [PreserveSig] int GetMonitorFrequency(out int freq);
    [PreserveSig] int GetScanLine(out int line);
    [PreserveSig] int GetVerticalBlankStatus(out int status);
    [PreserveSig] int Initialize(IntPtr guid);
    [PreserveSig] int RestoreDisplayMode();
    [PreserveSig] int SetCooperativeLevel(IntPtr hwnd, int flags);
    [PreserveSig] int SetDisplayMode(int width, int height, int bpp);
    [PreserveSig] int WaitForVerticalBlank(int flags, IntPtr eventHandle);
}

[ComImport, Guid("6C14DB81-A733-11CE-A521-0020AF0BE560"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IDirectDrawSurface
{
    [PreserveSig] int AddAttachedSurface(IDirectDrawSurface surface);
    [PreserveSig] int AddOverlayDirtyRect(IntPtr rect);
    [PreserveSig] int Blt(IntPtr destRect, IDirectDrawSurface src, IntPtr srcRect, int flags, ref DDBLTFX fx);
    [PreserveSig] int BltBatch(IntPtr batch, int count, int flags);
    [PreserveSig] int BltFast(int x, int y, IDirectDrawSurface src, IntPtr srcRect, int flags);
    [PreserveSig] int DeleteAttachedSurface(int flags, IDirectDrawSurface surface);
    [PreserveSig] int EnumAttachedSurfaces(IntPtr context, IntPtr callback);
    [PreserveSig] int EnumOverlayZOrders(int flags, IntPtr context, IntPtr callback);
    [PreserveSig] int Flip(IDirectDrawSurface target, int flags);
    [PreserveSig] int GetAttachedSurface(ref DDSCAPS caps, out IDirectDrawSurface attached);
    [PreserveSig] int GetBltStatus(int flags);
    [PreserveSig] int GetCaps(out DDSCAPS caps);
    [PreserveSig] int GetClipper(out IntPtr clipper);
    [PreserveSig] int GetColorKey(int flags, IntPtr key);
    [PreserveSig] int GetDC(out IntPtr hdc);
    [PreserveSig] int GetFlipStatus(int flags);
    [PreserveSig] int GetOverlayPosition(out int x, out int y);
    [PreserveSig] int GetPalette(out IntPtr palette);
    [PreserveSig] int GetPixelFormat(ref DDPIXELFORMAT format);
    [PreserveSig] int GetSurfaceDesc(ref DDSURFACEDESC desc);
    [PreserveSig] int Initialize(IDirectDraw dd, ref DDSURFACEDESC desc);
    [PreserveSig] int IsLost();
    [PreserveSig] int Lock(IntPtr rect, ref DDSURFACEDESC desc, int flags, IntPtr eventHandle);
    [PreserveSig] int ReleaseDC(IntPtr hdc);
    [PreserveSig] int Restore();
    [PreserveSig] int SetClipper(IntPtr clipper);
    [PreserveSig] int SetColorKey(int flags, IntPtr key);
    [PreserveSig] int SetOverlayPosition(int x, int y);
    [PreserveSig] int SetPalette(IntPtr palette);
    [PreserveSig] int Unlock(IntPtr surfaceData);
    [PreserveSig] int UpdateOverlay(IntPtr srcRect, IDirectDrawSurface dest, IntPtr destRect, int flags, IntPtr fx);
    [PreserveSig] int UpdateOverlayDisplay(int flags);
    [PreserveSig] int UpdateOverlayZOrder(int flags, IDirectDrawSurface surface);
}

internal static class Program
{
    const int Magenta = 0x00FF00FF;

    [STAThread]
    static int Main(string[] args)
    {
        int holdMs = 1500;
        string outPath = Path.Combine(Environment.CurrentDirectory, "probe-result.json");
        int sampleX = -1;
        int sampleY = -1;
        for (int i = 0; i < args.Length; i++)
        {
            if (args[i] == "--hold-ms" && i + 1 < args.Length) holdMs = int.Parse(args[++i]);
            else if (args[i] == "--out" && i + 1 < args.Length) outPath = args[++i];
            else if (args[i] == "--sample-x" && i + 1 < args.Length) sampleX = int.Parse(args[++i]);
            else if (args[i] == "--sample-y" && i + 1 < args.Length) sampleY = int.Parse(args[++i]);
        }

        var result = new Result();
        Form form = null;
        IDirectDraw dd = null;
        IDirectDrawSurface primary = null;
        IDirectDrawSurface back = null;
        try
        {
            form = new Form
            {
                FormBorderStyle = FormBorderStyle.None,
                StartPosition = FormStartPosition.Manual,
                Bounds = Screen.PrimaryScreen.Bounds,
                BackColor = Color.Black,
                ShowInTaskbar = false,
                TopMost = true,
                Text = "CossacksDdrawProbe"
            };
            form.Show();
            Application.DoEvents();
            result.Window = form.Handle.ToInt32();

            int hr = Native.DirectDrawCreate(IntPtr.Zero, out dd, IntPtr.Zero);
            result.DirectDrawCreate = Hex(hr);
            if (hr < 0) return Write(outPath, result, 2);

            hr = dd.SetCooperativeLevel(form.Handle, Native.DDSCL_EXCLUSIVE | Native.DDSCL_FULLSCREEN);
            result.SetCooperativeLevel = Hex(hr);
            if (hr < 0) return Write(outPath, result, 3);

            hr = dd.SetDisplayMode(1024, 768, 32);
            result.SetDisplayMode = Hex(hr);
            if (hr < 0) return Write(outPath, result, 4);

            var desc = new DDSURFACEDESC();
            desc.dwSize = Marshal.SizeOf(typeof(DDSURFACEDESC));
            desc.dwFlags = Native.DDSD_CAPS | Native.DDSD_BACKBUFFERCOUNT;
            desc.ddsCaps.dwCaps = Native.DDSCAPS_PRIMARYSURFACE | Native.DDSCAPS_FLIP | Native.DDSCAPS_COMPLEX;
            desc.dwBackBufferCount = 1;
            hr = dd.CreateSurface(ref desc, out primary, IntPtr.Zero);
            result.CreateSurface = Hex(hr);
            result.SurfaceDescSize = desc.dwSize;
            if (hr < 0) return Write(outPath, result, 5);

            var caps = new DDSCAPS { dwCaps = Native.DDSCAPS_BACKBUFFER };
            hr = primary.GetAttachedSurface(ref caps, out back);
            result.GetAttachedSurface = Hex(hr);

            var fill = new DDBLTFX();
            fill.dwSize = Marshal.SizeOf(typeof(DDBLTFX));
            fill.dwFillColor = Magenta;
            var target = (hr == 0 && back != null) ? back : primary;
            result.FilledSurface = (target == back) ? "back" : "primary";
            hr = target.Blt(IntPtr.Zero, null, IntPtr.Zero, Native.DDBLT_COLORFILL | Native.DDBLT_WAIT, ref fill);
            result.ColorFill = Hex(hr);

            if (back != null)
            {
                hr = primary.Flip(null, Native.DDFLIP_WAIT);
                result.Flip = Hex(hr);
            }

            SampleSurface(primary, result, "primary");
            if (back != null) SampleSurface(back, result, "back");

            IntPtr gdiDc;
            if (primary.GetDC(out gdiDc) == 0)
            {
                using (var g = Graphics.FromHdc(gdiDc))
                using (var brush = new SolidBrush(Color.FromArgb(0, 255, 0)))
                {
                    g.FillRectangle(brush, 100, 100, 200, 200);
                    g.DrawString("GDI", new Font("Arial", 48), Brushes.White, 120, 140);
                }
                primary.ReleaseDC(gdiDc);
                result.GdiFill = "ok";
            }
            else
            {
                result.GdiFill = "GetDC failed";
            }

            Application.DoEvents();
            System.Threading.Thread.Sleep(holdMs);
            SampleDesktop(result, sampleX, sampleY);
        }
        catch (Exception ex)
        {
            result.Exception = ex.GetType().Name + ": " + ex.Message;
            Write(outPath, result, 1);
            return 1;
        }
        finally
        {
            try { if (dd != null) dd.RestoreDisplayMode(); } catch { }
            if (form != null)
            {
                form.Close();
                form.Dispose();
            }
        }
        return Write(outPath, result, 0);
    }

    static void SampleSurface(IDirectDrawSurface surface, Result result, string name)
    {
        var desc = new DDSURFACEDESC();
        desc.dwSize = Marshal.SizeOf(typeof(DDSURFACEDESC));
        int hr = surface.Lock(IntPtr.Zero, ref desc, Native.DDLOCK_READONLY | Native.DDLOCK_WAIT, IntPtr.Zero);
        if (hr < 0)
        {
            if (name == "primary") result.PrimaryLock = Hex(hr);
            else result.BackLock = Hex(hr);
            return;
        }
        try
        {
            int w = Math.Min(desc.dwWidth, 32);
            int h = Math.Min(desc.dwHeight, 32);
            int bpp = desc.ddpfPixelFormat.dwRGBBitCount == 0 ? 32 : desc.ddpfPixelFormat.dwRGBBitCount;
            int bytes = Math.Max(4, bpp / 8);
            long sum = 0;
            int count = 0;
            for (int y = 0; y < h; y++)
            {
                IntPtr row = IntPtr.Add(desc.lpSurface, y * desc.lPitch);
                for (int x = 0; x < w; x++)
                {
                    sum += Marshal.ReadInt32(row, x * bytes) & 0x00FFFFFF;
                    count++;
                }
            }
            string avg = count == 0 ? "0" : (sum / count).ToString("X6");
            if (name == "primary")
            {
                result.PrimaryLock = Hex(0);
                result.PrimaryAvg = avg;
                result.PrimarySize = desc.dwWidth + "x" + desc.dwHeight;
                result.PrimaryPitch = desc.lPitch;
            }
            else
            {
                result.BackLock = Hex(0);
                result.BackAvg = avg;
                result.BackSize = desc.dwWidth + "x" + desc.dwHeight;
            }
        }
        finally
        {
            surface.Unlock(desc.lpSurface);
        }
    }

    static void SampleDesktop(Result result, int sampleX, int sampleY)
    {
        Native.SetThreadDpiAwarenessContext(new IntPtr(-4));
        var bounds = Screen.PrimaryScreen.Bounds;
        int x = sampleX >= 0 ? sampleX : bounds.X + bounds.Width / 2;
        int y = sampleY >= 0 ? sampleY : bounds.Y + bounds.Height / 2;
        IntPtr hdc = Native.GetDC(IntPtr.Zero);
        if (hdc == IntPtr.Zero)
        {
            result.DesktopPixel = "no-dc";
            return;
        }
        try
        {
            uint centre = Native.GetPixel(hdc, x, y);
            uint left = Native.GetPixel(hdc, Math.Max(0, x - 800), y);
            result.DesktopPixel = centre.ToString("X6");
            result.DesktopSampleAt = x + "," + y;
            result.DesktopLeftPixel = left.ToString("X6");
            result.DesktopBounds = bounds.Width + "x" + bounds.Height + "@" + bounds.X + "," + bounds.Y;
        }
        finally
        {
            Native.ReleaseDC(IntPtr.Zero, hdc);
        }
    }

    static string Hex(int hr)
    {
        return "0x" + unchecked((uint)hr).ToString("X8");
    }

    static int Write(string path, Result result, int code)
    {
        result.Exit = code;
        File.WriteAllText(path, result.ToJson());
        Console.WriteLine(result.ToJson());
        return code;
    }
}

internal sealed class Result
{
    public int Exit;
    public int Window;
    public int SurfaceDescSize;
    public string DirectDrawCreate = "";
    public string SetCooperativeLevel = "";
    public string SetDisplayMode = "";
    public string CreateSurface = "";
    public string GetAttachedSurface = "";
    public string FilledSurface = "";
    public string ColorFill = "";
    public string Flip = "";
    public string PrimaryLock = "";
    public string PrimaryAvg = "";
    public string PrimarySize = "";
    public int PrimaryPitch;
    public string BackLock = "";
    public string BackAvg = "";
    public string BackSize = "";
    public string GdiFill = "";
    public string DesktopPixel = "";
    public string DesktopLeftPixel = "";
    public string DesktopSampleAt = "";
    public string DesktopBounds = "";
    public string Exception = "";

    public string ToJson()
    {
        return "{"
            + "\"exit\":" + Exit + ","
            + "\"window\":" + Window + ","
            + "\"directDrawCreate\":\"" + DirectDrawCreate + "\","
            + "\"setCooperativeLevel\":\"" + SetCooperativeLevel + "\","
            + "\"setDisplayMode\":\"" + SetDisplayMode + "\","
            + "\"createSurface\":\"" + CreateSurface + "\","
            + "\"getAttachedSurface\":\"" + GetAttachedSurface + "\","
            + "\"filledSurface\":\"" + FilledSurface + "\","
            + "\"colorFill\":\"" + ColorFill + "\","
            + "\"flip\":\"" + Flip + "\","
            + "\"primaryLock\":\"" + PrimaryLock + "\","
            + "\"primaryAvg\":\"" + PrimaryAvg + "\","
            + "\"primarySize\":\"" + PrimarySize + "\","
            + "\"backLock\":\"" + BackLock + "\","
            + "\"backAvg\":\"" + BackAvg + "\","
            + "\"backSize\":\"" + BackSize + "\","
            + "\"gdiFill\":\"" + Escape(GdiFill) + "\","
            + "\"desktopPixel\":\"" + DesktopPixel + "\","
            + "\"desktopLeftPixel\":\"" + DesktopLeftPixel + "\","
            + "\"desktopSampleAt\":\"" + DesktopSampleAt + "\","
            + "\"desktopBounds\":\"" + DesktopBounds + "\","
            + "\"exception\":\"" + Escape(Exception) + "\""
            + "}";
    }

    static string Escape(string s)
    {
        return (s ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"");
    }
}

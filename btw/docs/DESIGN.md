# Design

## Constraints

The Steam *Back to War* build is still a DirectDraw 2D engine. `dmcr.exe` loads `csemu.dll`; `csemu.dll` calls `LoadLibrary("DDRAW.DLL")` and `DirectDrawCreate`. The original 4:3 framebuffers are **800x600** and **1024x768**. Steam's own readme emulates **1024x768** specifically so the menu layout is correct.

Steam's `csbtw.exe` exposes a `CSBTW_LAUNCHER` interface. `csemu.dll` calls `LauncherInterfaceCheck()` on startup; launching `dmcr.exe` alone returns error 2. The installer shortcut must start `csbtw.exe`.


Windows 11 breaks the original contract in four ways that match the failures people hit:

1. Exclusive fullscreen + lost primary surface → crash or black screen on Alt+Tab.
2. Uncapped Flip / primary blits on a high-refresh desktop → menu thread never processes input (freeze).
3. Enumerated widescreen desktop modes → HUD designed for 4:3 is either cropped or microscopic.
4. Hybrid GPUs and extra virtual monitors confuse `EnumDisplayDevices`.

Community 1.52 (SDL2) solves all of that by **leaving DirectDraw**. That is the wrong trade for “close fidelity on DirectDraw instructions.”

cnc-ddraw also works, but it is a GLES/D3D9 reimplementation aimed at windowing and shaders. DDrawCompat keeps the DirectDraw API surface and emulates the missing bits (color key, lost surfaces, 16-bit modes) on a modern D3D9 path. For Blt/Flip/color-key 2D, that is the closer wrapper.

## Chosen settings

| Setting | Value | Why |
| --- | --- | --- |
| `FullscreenMode` | `borderless` | Steam BTW still creates COMPLEX+FLIP and `GetAttachedSurface(BACKBUFFER)`. DDrawCompat 0.7.1 attaches that backbuffer in borderless. Exclusive D3D9 present eats GDI, which is the BTW menu. |
| `DisplayAspectRatio` | `4:3` | Pillarbox; never stretch to 16:9. |
| `DisplayFilter` | `point` (default) / `integer` (optional) | No bilinear smear. Integer keeps whole-pixel scale and adds more pillarbox. |
| `BltFilter` | `point` | CPU and GPU stretches stay nearest-neighbour. |
| `RenderColorDepth` | `app` | Follow the application's colour depth. Original retail DirectDraw was 16-bit High Color; Steam BTW's `csemu` requests 32-bit. |
| `ColorKeyMethod` | `alphatest(1)` | Native GPU color key on current drivers is wrong; alpha test is the working equivalent of `DDBLT_KEYSRC`. |
| `ResolutionScale` | `app(1)` | No extra 3D render-target upscale. Cossacks is not that game. |
| `SupportedResolutions` | `native` plus 4:3 classics | Steam `csemu` SetDisplayMode()s the desktop mode at init. Hiding it returns `887601C2` (`DDERR_UNSUPPORTEDMODE`). |
| `FpsLimiter` | `msgloop(60)` | Menus often blit the primary without Flip; cap the message loop. |
| `VSync` | `on` | Second brake on the same spin. |
| `AltTabFix` | `keepvidmem(1)` | Exclusive Flip loses the device on Alt+Tab. Keep the surfaces. |
| `CpuAffinity` | `all` | Pinning a single core can starve the menu message pump. |
| `CompatFixes` | `nowindowborders` | Do not force the Windows primary (`singlemonitor`). The launcher targets the largest attached monitor. |
| `GdiInterops` | `all` | The BTW menu is GDI on the DirectDraw primary. `none` is a black screen with working hover sounds. |

Steam `csemu` LoadLibrary’s SYSTEM `ddraw.dll`. That import pulls `dciman32`; DDrawCompat in the game folder as `dciman32.dll` is Method 1. A local `ddraw.dll` double-wraps and fails init.

Do not add a High DPI compatibility shim. `HIGHDPIAWARE` makes the process start already per-monitor DPI; DDrawCompat then fails `SetProcessDpiAwarenessContext` and present stays black.

At every launch the bat rewrites `DisplayResolution` to the largest non-virtual monitor and moves the cursor there. The game framebuffer stays **1024x768** or **800x600** 4:3 and is pillarboxed onto that panel.

`btw/tools/Test-DdrawPresent.ps1` replays `SetDisplayMode(1024,768,32)` + COMPLEX+FLIP + `GetAttachedSurface`. Use it to separate a black primary from `887601C2`.

## What we refuse to ship

- Game binaries, `.gsc` resources, `csemu.dll`, maps, campaigns.
- A vendored `ddraw.dll`. The installer pulls a tagged GitHub release.
- XP compatibility mode. It forces admin + old shims and fights DDrawCompat's DPI and COM hooks.
- Disabling “Generic PnP Monitor.” That is a Windows display-stack hack, not a game fix.

## Verification

1. `btw/scripts/Test-CossacksClassic.ps1` - preset text and `mode.dat` rewrite.
2. Manual: install, launch the bat file, confirm pillarboxed 4:3, open the menu and wait, Alt+Tab to desktop and back without a crash.

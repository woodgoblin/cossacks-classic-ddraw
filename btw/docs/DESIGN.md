# Design

## Constraints

The Steam *Back to War* build is still a DirectDraw 2D engine. `dmcr.exe` loads `csemu.dll`; `csemu.dll` calls `LoadLibrary("DDRAW.DLL")` and `DirectDrawCreate`. The original 4:3 framebuffers are **800×600** and **1024×768**. Steam's own readme emulates **1024×768** specifically so the menu layout is correct.

Windows 11 breaks the original contract in four ways that match the failures people hit:

1. Exclusive fullscreen + lost primary surface → crash or black screen on Alt+Tab.
2. Uncapped Flip / primary blits on a 144+ Hz desktop → menu thread never processes input (freeze).
3. Enumerated desktop modes include 2560×1440 / 3840×2160 → HUD designed for 4:3 is either cropped or microscopic.
4. Hybrid GPUs and extra virtual monitors (this machine has AMD + NVIDIA + a Meta virtual display) confuse `EnumDisplayDevices`.

Community 1.52 (SDL2) solves all of that by **leaving DirectDraw**. That is the wrong trade for “close fidelity on DirectDraw instructions.”

cnc-ddraw also works, but it is a GLES/D3D9 reimplementation aimed at windowing and shaders. DDrawCompat keeps the DirectDraw API surface and emulates the missing bits (color key, lost surfaces, 16-bit modes) on a modern D3D9 path. For Blt/Flip/color-key 2D, that is the closer wrapper.

## Chosen settings

| Setting | Value | Why |
| --- | --- | --- |
| `FullscreenMode` | `borderless` | Alt+Tab does not destroy an exclusive swap chain. |
| `DisplayAspectRatio` | `4:3` | Pillarbox; never stretch to 16:9. |
| `DisplayFilter` | `point` (default) / `integer` (optional) | No bilinear smear. Integer is pixel-perfect but small on 1440p at 1024×768. |
| `BltFilter` | `point` | CPU and GPU stretches stay nearest-neighbour. |
| `RenderColorDepth` | `app` | Do not promote the 16-bit look to a 32-bit framebuffer. |
| `ColorKeyMethod` | `alphatest(1)` | Native GPU color key on current drivers is wrong; alpha test is the working equivalent of `DDBLT_KEYSRC`. |
| `ResolutionScale` | `app(1)` | No extra 3D render-target upscale. Cossacks is not that game. |
| `SupportedResolutions` | `800x600, 1024x768` | Hide the desktop 16:9 modes from the in-game list. |
| `FpsLimiter` | `msgloop(60)` | Menus often blit the primary without Flip; cap the message loop. |
| `VSync` | `on` | Second brake on the same spin. |
| `AltTabFix` | `noactivateapp(1)` | Do not tell DirectDraw the device was lost. Still notify the app so it can pause. |
| `CpuAffinity` | `1` | This engine was not written for 16 cores. |
| `CompatFixes` | `singlemonitor,nowindowborders` | Ignore the VR virtual monitor and stray Win32 chrome. |
| `GdiInterops` | `all`, with `none` fallback | Menus mix GDI; if that path deadlocks, drop it. |

`dciman32.dll` is a copy of DDrawCompat. Cossacks titles sometimes `LoadLibrary` System32 `ddraw.dll`; that copy imports `dciman32`, which then loads from the game directory. Steam's `csemu` uses a bare `DDRAW.DLL` name, so `ddraw.dll` beside `dmcr.exe` is the primary hit. Installing both covers both loaders.

## What we refuse to ship

- Game binaries, `.gsc` resources, `csemu.dll`, maps, campaigns.
- A vendored `ddraw.dll`. The installer pulls a tagged GitHub release.
- XP compatibility mode. It forces admin + old shims and fights DDrawCompat's DPI and COM hooks.
- Disabling “Generic PnP Monitor.” That is a Windows display-stack hack, not a game fix.

## Verification

1. `btw/scripts/Test-CossacksClassic.ps1` - preset text and `mode.dat` rewrite.
2. Manual: install, launch the bat file, confirm pillarboxed 4:3, open the menu and wait, Alt+Tab to desktop and back without a crash.

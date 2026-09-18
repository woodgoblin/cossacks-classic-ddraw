# Cossacks: Back to War — classic 4:3 DirectDraw (Windows 11)

A **preset + installer**, not a game. It makes a legal Steam/GOG/retail copy of *Cossacks: Back to War* run as a 4:3 DirectDraw game on Windows 11: original framebuffer, point sampling, a menu that keeps pumping messages, and Alt+Tab that does not tear down exclusive fullscreen.

This repository contains **no GSC assets, no `dmcr.exe`, no `.gsc` files**. You already own the game.

## What you get

| Goal | How |
| --- | --- |
| 4:3 as shipped in 2001–2002 | Internal mode locked to **1024×768** (Steam menu design size) or **800×600**. Widescreen modes are hidden. |
| Close DirectDraw behaviour | [DDrawCompat](https://github.com/narzoul/DDrawCompat) wraps `DirectDrawCreate` / Blt / Flip. Point filter, app color depth, no resolution-scale shader. |
| Menu does not freeze | Borderless presentation + `FpsLimiter=msgloop(60)` so the UI thread cannot spin on Flip. |
| Alt+Tab to desktop | `FullscreenMode=borderless` and `AltTabFix=noactivateapp`. No exclusive-mode device loss. |

Steam's `csemu.dll` already `LoadLibrary("DDRAW.DLL")`. The installer drops DDrawCompat next to `dmcr.exe` as both `ddraw.dll` and `dciman32.dll` (the Cossacks-series fallback when the engine asks for System32).

This is **not** Cossacks 1.52 / SDL2. That rewrite is excellent for modern widescreen, and it is the opposite of this preset.

## Install (Windows 11)

In PowerShell, from this repo:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Install-CossacksClassic.ps1
```

Optional:

```powershell
# Original 800x600 framebuffer
.\scripts\Install-CossacksClassic.ps1 -InternalResolution 800x600

# Integer pixels (more black bars; 1024x768 is 1x on 1440p)
.\scripts\Install-CossacksClassic.ps1 -Preset integer

# If the main menu still freezes
.\scripts\Install-CossacksClassic.ps1 -Preset menu-gdi-off
```

Then:

1. Steam → *Cossacks: Back to War* → Properties → **disable the overlay**.
2. Run `Cossacks Classic 4x3.bat` in the game `bin` folder (the installer writes it).
3. In video options keep **1024×768** or **800×600**. Do not pick a 16:9 desktop mode.
4. Shift+F11 opens the DDrawCompat overlay if you need to inspect the wrapper.

DirectPlay: the installer tries to enable the Windows **Legacy Components → DirectPlay** feature. If it cannot (no admin), turn that on yourself. Needed for `0xc0000022` on launch, not for the picture.

Uninstall:

```powershell
.\scripts\Uninstall-CossacksClassic.ps1
```

## Tests

```powershell
.\scripts\Test-CossacksClassic.ps1
```

## Why this stack

See [docs/DESIGN.md](docs/DESIGN.md).

## License

Installer, presets, and docs: MIT. DDrawCompat is downloaded from upstream at install time and remains Narzoul's (LGPL). Cossacks remains GSC Game World's.

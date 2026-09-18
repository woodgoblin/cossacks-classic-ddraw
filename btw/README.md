# Cossacks: Back to War

Classic 4:3 DirectDraw preset for a legal Steam/GOG/retail copy of *Cossacks: Back to War*.

Steam's `csemu.dll` already `LoadLibrary("DDRAW.DLL")`. The installer drops [DDrawCompat](https://github.com/narzoul/DDrawCompat) next to `dmcr.exe` as both `ddraw.dll` and `dciman32.dll`.

This is **not** Cossacks 1.52 / SDL2. That rewrite leaves DirectDraw; this one keeps it.

## What you get

| Goal | How |
| --- | --- |
| 4:3 as shipped in 2001-2002 | Internal mode locked to **1024x768** (Steam menu design size) or **800x600**. Widescreen modes are hidden. |
| Close DirectDraw behaviour | DDrawCompat wraps `DirectDrawCreate` / Blt / Flip. Point filter, app color depth, no resolution-scale shader. |
| Menu does not freeze | Borderless presentation + `FpsLimiter=msgloop(60)` so the UI thread cannot spin on Flip. |
| Alt+Tab to desktop | `FullscreenMode=borderless` and `AltTabFix=noactivateapp`. No exclusive-mode device loss. |

## Install (Windows 11)

From the repository root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\btw\scripts\Install-CossacksClassic.ps1
```

Optional:

```powershell
.\btw\scripts\Install-CossacksClassic.ps1 -InternalResolution 800x600
.\btw\scripts\Install-CossacksClassic.ps1 -Preset integer
.\btw\scripts\Install-CossacksClassic.ps1 -Preset menu-gdi-off
```

Then:

1. Steam -> *Cossacks: Back to War* -> Properties -> **disable the overlay**.
2. Run `Cossacks Classic 4x3.bat` in the game `bin` folder (the installer writes it).
3. In video options keep **1024x768** or **800x600**.
4. Shift+F11 opens the DDrawCompat overlay.

DirectPlay: the installer tries to enable **Legacy Components -> DirectPlay**. If it cannot (no admin), turn that on yourself. Needed for `0xc0000022` on launch, not for the picture.

Uninstall:

```powershell
.\btw\scripts\Uninstall-CossacksClassic.ps1
```

## Tests

```powershell
.\btw\scripts\Test-CossacksClassic.ps1
```

## Why this stack

See [docs/DESIGN.md](docs/DESIGN.md).

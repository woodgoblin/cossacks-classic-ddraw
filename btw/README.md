# Cossacks: Back to War

Classic 4:3 DirectDraw preset for a legal Steam/GOG/retail copy of *Cossacks: Back to War*.

Steam's `csemu.dll` LoadLibrary’s SYSTEM `ddraw.dll`. The installer drops [DDrawCompat](https://github.com/narzoul/DDrawCompat) next to `dmcr.exe` as `dciman32.dll` only.

This is **not** Cossacks 1.52 / SDL2. That rewrite leaves DirectDraw; this one keeps it.

## What you get

| Goal | How |
| --- | --- |
| 4:3 as shipped in 2001-2002 | Internal mode locked to **1024x768** (Steam menu design size) or **800x600**. That framebuffer is pillarboxed onto the largest attached monitor. |
| Close DirectDraw behaviour | DDrawCompat wraps `DirectDrawCreate` / Blt / Flip. Point filter, app color depth, no resolution-scale shader. |
| Menu does not freeze | `FpsLimiter=msgloop(60)` so the UI thread cannot spin on Flip. |
| Picture is GDI + DirectDraw | `FullscreenMode=borderless`, `GdiInterops=all`, `DpiAwareness=app`. Exclusive Present hides GDI. Forcing per-monitor DPI after `csemu` starts unaware also blacks the menu. |
| Largest attached monitor | Launcher picks the attached panel with the most native pixels, restores **that panel only** if its mode was changed, writes its native mode into `DisplayResolution`, and parks the cursor there. Other monitors are left alone. `dmcr.exe.manifest` makes that process DPI-aware so `SetDisplayMode` asks for that same native size. |
| Alt+Tab to desktop | `AltTabFix=keepvidmem(1)` so surfaces stay allocated. |

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
2. Run `Cossacks Classic 4x3.bat` in the game `bin` folder. It starts `csbtw.exe` (required). Starting `dmcr.exe` directly fails with `LauncherInterfaceCheck error 2`.
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

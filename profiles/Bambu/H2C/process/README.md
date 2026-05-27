# Bambu Lab H2C — 0.2 mm Nozzle Print Profiles (CF / GF Filled)

**Bambu Studio** process profiles for the **Bambu Lab H2C** fitted with a
**0.2 mm hardened nozzle**, conservatively tuned for **fiber-filled
filaments** (Carbon Fiber and Glass Fiber). Also imports cleanly into
OrcaSlicer (Bambu Studio is a strict subset of Orca's schema).

## Files

| File | Layer height | Use case |
| --- | --- | --- |
| `0.08mm Fine @BBL H2C 0.2 nozzle CF-GF.json` | 0.08 mm | Smallest detail, miniature/jewelry-scale parts |
| `0.10mm Standard @BBL H2C 0.2 nozzle CF-GF.json` | 0.10 mm | Balanced default for any CF/GF — start here |
| `0.12mm Draft @BBL H2C 0.2 nozzle CF-GF.json` | 0.12 mm | Fastest (still inside 0.75 × nozzle limit) |
| `0.10mm PPS-CF-GF @BBL H2C 0.2 nozzle.json` | 0.10 mm | **PPS-CF / PPS-GF dialed** — engineering tune |

## Verified filament pairings

The PPS profile is built around the **Bambu Studio "Generic PPS-CF" filament
preset** driving **Fiberon PPS-GF** filament — that combination prints
cleanly, where the Fiberon-branded filament preset did not. Use Generic
PPS-CF as your filament selection in Bambu Studio when running this
process profile, regardless of brand/CF-vs-GF, unless your filament's own
preset has been verified.

## Supported filaments (other CF/GF profiles)

The three `... CF-GF.json` profiles will print safely with any of the
following — the slicer pulls material temperature/fan from the filament
profile:

**Bambu Lab CF / GF**
- Bambu PLA-CF
- Bambu PETG-CF / PETG-GF
- Bambu PA-CF
- Bambu PA6-CF / PA6-GF
- Bambu PAHT-CF
- Bambu PET-CF
- Bambu PPS-CF / PPS-GF
- Bambu PPA-CF

**Generic CF / GF**
- Generic PLA-CF / PLA-GF
- Generic PETG-CF / PETG-GF
- Generic PA-CF, PA6-CF, PAHT-CF, PA-GF, PA6-GF
- Generic PET-CF
- Generic PPS-CF / PPS-GF
- Generic PPA-CF

## Design choices (general CF/GF profiles)

- **Line width 0.20 / 0.22 mm.** Outer walls and visible surfaces at 0.20 mm
  for sharp detail; internal extrusions at 0.22 mm to keep flow consistent.
- **3 walls, beefy top/bottom shells.** Filled filaments are stiff but
  delaminate under-skinned; the shell counts compensate at thin layer heights.
- **Conservative speeds.** Outer wall ≤ 55 mm/s, infill ≤ 100 mm/s. Peak
  volumetric flow is held under ~2.6 mm³/s so any commodity hotend keeps up
  even at PPS-CF temperatures.
- **Reduced retraction (0.8 mm @ 35 mm/s) + Z-hop.** Fiber filaments are
  prone to stringing-on-clog rather than stringing-on-distance — long retracts
  pull abrasive fiber into the cold zone and cause jams.
- **Bridge flow 0.85, bridge speed 25 mm/s.** Filled materials sag less than
  unfilled but don't bridge well; tuned for short spans only.
- **Tree (slim) auto-support.** Lower support_object_xy_distance (0.35) and
  generous interface settings since CF/GF leaves rougher witness marks.
- **Precise outer wall: on.** Worth the extra travel for tolerance-sensitive
  engineering prints.

## Design choices (PPS-CF/GF profile)

PPS warps more than PA and sags more on bridges, so this profile diverges:

- **4 walls, 7 top / 6 bottom shells, 20 % grid infill.** Engineering defaults
  for pressure-tight or fastener-loaded parts.
- **Initial layer height 0.12 mm + 0.28 mm line width + 8 mm outer-and-inner
  brim.** PPS-CF/GF is the worst-warping filament in the lineup; this brim
  + squish strategy keeps corners pinned through the print.
- **Outer wall 45 mm/s, infill 80 mm/s, bridge 20 mm/s.** Slower than the
  general profiles; keeps peak volumetric flow near 1.6 mm³/s, well within
  what the H2C hotend can sustain at 320–340 °C with the fan off.
- **Retraction 0.6 mm @ 30 mm/s, Z-hop 0.2 mm.** PPS-CF/GF barely ooze;
  aggressive retracts only wear the nozzle and risk fiber feed faults.
- **Bridge flow 0.80.** PPS sags noticeably more than nylons.
- **No ironing.** Fiber smears across hot ironing passes.
- **Elephant-foot compensation 0.15 mm.** First-layer squish is intentional;
  this trims it back to spec.

## Importing into Bambu Studio

1. Open Bambu Studio.
2. Select printer **Bambu Lab H2C 0.2 nozzle**.
3. For PPS-GF (Fiberon or otherwise), select filament **Generic PPS-CF**.
4. Process dropdown → gear icon → **Import preset**.
5. Pick the desired JSON from this folder.
6. The profile appears under **User Presets** in the process list.

Unknown fields (if any survive Orca-to-Studio drift) are silently ignored
on import; the profile still loads and applies all recognized fields.

## Tuning notes

- **PPS-CF / PPS-GF**: use the dedicated `0.10mm PPS-CF-GF` profile. If you
  still see corner curl, raise brim width to 10 mm and drop chamber-cool
  fan (filament preset) further.
- **PPA-CF**: start from `0.10mm PPS-CF-GF` and bump outer-wall to 50 mm/s
  — PPA tolerates more flow than PPS.
- **PLA-CF / PETG-CF**: use `0.10mm Standard`; you can comfortably raise
  infill to 130 mm/s once printed.
- **PA-CF / PA6-CF**: use `0.10mm Standard`; verify your filament preset
  disables the part fan and the chamber is warm.
- If you see fiber pulling/tearing on outer walls, increase outer-wall flow
  ratio by +5 % **at the filament level**, not in the process profile.

## Warnings

- A **0.2 mm hardened nozzle** is mandatory. Brass will be destroyed in
  minutes by CF/GF.
- Some long-fiber blends (notably aftermarket PPS-CF) have fiber lengths
  approaching 0.2 mm and **will jam regardless of nozzle hardness**. If
  you experience repeated clogs, those filaments need a 0.4 mm nozzle.
- These profiles are starting points — flow, pressure advance, and
  temperature still need per-filament calibration on your machine.

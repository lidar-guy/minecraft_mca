# Bambu Lab H2C — 0.2 mm Nozzle Print Profiles (CF / GF Filled)

OrcaSlicer / Bambu Studio process profiles for the **Bambu Lab H2C** fitted with
a **0.2 mm hardened nozzle**, conservatively tuned for **fiber-filled
filaments** (Carbon Fiber and Glass Fiber).

## Files

| File | Layer height | Use case |
| --- | --- | --- |
| `0.08mm Fine @BBL H2C 0.2 nozzle CF-GF.json` | 0.08 mm | Smallest detail, miniature/jewelry-scale parts |
| `0.10mm Standard @BBL H2C 0.2 nozzle CF-GF.json` | 0.10 mm | Balanced default — start here |
| `0.12mm Draft @BBL H2C 0.2 nozzle CF-GF.json` | 0.12 mm | Fastest (still inside 0.75 × nozzle limit) |

## Supported filaments

Designed to print safely with any of the following filaments (slicer will pick
material temperature / fan from the filament profile):

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

## Design choices

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
- **Slowdown for curled perimeters: on.** Critical for filled nylons that
  curl when corners get hot.
- **Precise outer wall: on.** Worth the extra travel for tolerance-sensitive
  engineering prints.

## Importing

1. Open OrcaSlicer (or Bambu Studio).
2. Select printer **Bambu Lab H2C 0.2 nozzle**, any filled filament.
3. In the process dropdown, click the gear icon → **Import preset**.
4. Pick the desired JSON from this folder.
5. The profile appears as **`User`** in the process list.

## Tuning notes

- **PPS-CF / PPA-CF**: drop outer-wall speed to 40 mm/s and infill to 70 mm/s
  if your hotend struggles to hold 320–350 °C at flow.
- **PLA-CF / PETG-CF**: you can comfortably raise infill to 130 mm/s.
- **PA-CF / PA6-CF**: keep chamber warm and fan off; the cooling values here
  defer to the filament profile, but verify your filament preset disables the
  part fan.
- If you see fiber pulling/tearing on outer walls, increase outer-wall flow
  ratio by +5 % at the filament level (not in the process profile).

## Warnings

- A **0.2 mm hardened nozzle** is mandatory. Brass will be destroyed in
  minutes by CF/GF.
- Some filaments (e.g. long-fiber PPS-CF) have fiber lengths approaching
  0.2 mm and **will jam regardless of nozzle hardness**. If you experience
  repeated clogs, those filaments need a 0.4 mm nozzle.
- These profiles are starting points — flow, pressure advance, and
  temperature still need per-filament calibration on your machine.

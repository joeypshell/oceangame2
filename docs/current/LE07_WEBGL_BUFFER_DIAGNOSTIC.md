# LE07 WebGL Buffer Diagnostic

Date: 2026-09-20. Issue: #1405. Later [#1397 closeout](LIVING_EXPEDITION_07_CLOSEOUT.md)
records owner GO after this repair and the #1408 arrival correction.

## Cause And Scope

The warning recorded in [LE07 Web verification](LIVING_EXPEDITION_07_WEB_VERIFICATION.md)
is a rejected GPU operation, not harmless console noise. Reproduced on public
runtime `5819f1d46425a5c6b0e3c4c5f2e0448b915816f3`, Godot
`4.7.stable.official.5b4e0cb0f`, Chromium `151.0.7922.34`.

`greybox_hostile_renderer.gd` rewrote the visible eel health-fill Polygon2D
every update, even with unchanged health. Instrumentation caught its 12-byte
quad index update rebinding an ELEMENT_ARRAY_BUFFER as ARRAY_BUFFER, followed
by a failed bufferSubData. Both return GL_INVALID_OPERATION (1282).
Godot's [exact GLES mesh source](https://github.com/godotengine/godot/blob/5b4e0cb0f/drivers/gles3/storage/mesh_storage.cpp)
uses GL_ARRAY_BUFFER in `mesh_surface_update_index_region`, although index
buffers are created as GL_ELEMENT_ARRAY_BUFFER. The isolated renderer produces
the same WebAssembly call stack as the full public field checkpoint.

## Isolation Evidence

| Isolated scene, same Web export template | Result |
| --- | --- |
| Original eel, repeated visible health updates | 476 rejected bind/update pairs in software trace |
| Original eel, state set once | No buffer errors |
| Original eel, repeated updates with health bar hidden | No buffer errors |
| Animated refuge presentation alone | No buffer errors |
| Original eel on NVIDIA RTX 2070 SUPER / ANGLE D3D11 | 697 rejected pairs; not software-only |
| Repaired rectangle bar, repeated health/visibility cycles | Zero errors on software and NVIDIA D3D11 |

Counts are observations over short runs, not stable assertions. Instrumented
getError calls synchronize GPU work and heavily distort full-scene timing;
they are not performance benchmarks. Brief uninstrumented field runs retained
animation before/after. No omitted body/refuge geometry was demonstrated, but
rejected writes cannot be certified safe. No Safari/iPhone claim is made.

## Bounded Repair

- Only the two health-bar rectangles switch from Polygon2D to ColorRect.
  Width, left anchor, offset, color thresholds, facing compensation, visibility,
  health metadata, and defeat linger remain unchanged; pointer input is ignored.
- Merely scaling an immutable polygon is insufficient: polygon redraw/color
  or reappearance can still enter the engine's index update path.
- No engine upgrade, warning suppression, map/collision change, creature art
  replacement, action timing change, or baseline acceptance.
- Combat smoke checks repeated 3/2/1/0/3 health, both facings, exact rectangle
  geometry/colors, input pass-through, and the existing defeat/reset semantics.
- The Web checker now fails on invalid bindBuffer/bufferSubData operations,
  including warnings. It correctly rejects the original public build.
  Export CI selects `living_expedition_07_pin` within its existing matrix;
  root, fresh profile, retained slice, wide, and mobile checks remain.

## Verification And Evidence

Local ignored evidence is under `tmp/webgl-1405/`: original public trace,
isolated before/after traces, software/hardware renderer identities, full-scene
controls, console logs, timing probes, and before/after screenshots.
The local repaired export is based on `bad5706` plus this issue's renderer diff;
its dirty build label is not an exact committed release claim.

All eighteen LE07 native frames were regenerated and checked. RGB comparisons
are unchanged outside the health-bar rasterization and build label; the night
pair is fully identical. Inspected desktop/mobile frames retain the intended
bar size and placement. Accepted baselines are untouched.

```powershell
& $godot --headless --path . --script scripts/main/smoke/smoke_combat_runtime_state.gd
python tools/capture_living_expedition_07.py --godot "$godot"
python tools/check_living_expedition_07_captures.py
node tools/check_web_preview.cjs http://127.0.0.1:8064/ --checkpoint living_expedition_07_refuge
python tools/check_file_lengths.py
git diff --check
```

Serve the export over HTTP. The public post-merge SHA, applicable CI results,
and exact-public checkpoint verification belong in #1405's completion comment.
This technical repair does not supply the separate Marl playtest verdict.

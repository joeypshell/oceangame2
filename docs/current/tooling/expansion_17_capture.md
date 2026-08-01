# Expansion 17 Capture

Run the focused wreck-network review captures from the repository root:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-17-wreck-network
```

The command writes paired 1280x720 desktop and 844x390 iPhone-landscape PNGs
under ignored `visual_captures/expansion_17_wreck_network/`. The states cover
both night leads, alternate pinning, each relay approach and 50% held-scanner
progress, one-fragment return feedback, two-fragment analysis readiness, and
the committed triangulation result. It uses isolated in-memory profile state
and the authored Expansion 17 camera tests; it does not mutate map source or
accept baselines.

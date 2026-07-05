# Visual Captures

`visual_captures/latest/` contains generated screenshots from the current project state.

These captures are not automatically approved baselines. They are review artifacts used to compare the current in-engine result against `visual_baselines/` and the art direction docs.

Regenerate named camera captures with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-camera-tests
```

The named views come from `camera_tests` in `maps/cave_salvage_test_01.greybox.json`.

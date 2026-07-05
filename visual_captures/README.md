# Visual Captures

`visual_captures/latest/` contains generated screenshots from the current salvage map.

`visual_captures/tileset_test/` contains generated screenshots from the organic cave tileset stress-test map.

These captures are not automatically approved baselines. They are review artifacts used to compare the current in-engine result against `visual_baselines/` and the art direction docs.

Regenerate named camera captures with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-camera-tests
```

The named views come from `camera_tests` in `maps/cave_salvage_test_01.greybox.json`.

Regenerate tileset stress-test captures with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-tileset-test
```

Those named views come from `camera_tests` in `maps/cave_tileset_test_01.greybox.json`.

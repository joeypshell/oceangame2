# Visual Baselines

Baseline screenshots are saved here when the project reaches a visual checkpoint.

## 001 - Greybox In Engine

File: `001_greybox_in_engine.png`

Represents:

- first Godot-rendered view of `maps/cave_salvage_test_01.greybox.json`
- greybox terrain, extraction zone, salvage, hazards, player marker, and camera scale
- pre-art baseline before modular terrain assets are generated

This is not an art target. It is a topology and scale reference for later visual work.

Regenerate locally with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 5 --capture-greybox-screenshot
```

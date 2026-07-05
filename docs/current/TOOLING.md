# Tooling

## Local Checks

Validate map reachability:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
```

Regenerate the SVG preview from source data:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
```

Run whitespace checks:

```bash
git diff --check
```

Run the Godot headless launch smoke check on this Windows setup:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
```

The headless command can exit `0` even when script errors appear in output, so treat `SCRIPT ERROR` or `ERROR:` lines as failures.

## Generated Files

Do not commit:

- `.godot/`
- `.import/`
- `*.import`
- `builds/`
- `exports/`
- local editor state

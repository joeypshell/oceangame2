# Living Expedition 01 Technical Review

Date: 2026-08-05

Issue: #1232 `Verify Living Expedition 01 Web build and run partnership owner closeout`

Status: **TECHNICAL PASS; OWNER GO/HOLD VERDICT PENDING**

## Exact Candidate

- runtime/evidence SHA: `0b6c1c8fb845a184cc7eb62f386c7d15656bca09`
- build version: `0b6c1c8`
- evidence PR: [#1247](https://github.com/joeypshell/oceangame2/pull/1247)
- [Godot Smoke run 31067443655](https://github.com/joeypshell/oceangame2/actions/runs/31067443655): core, regional journey, and source/map jobs passed
- [Progression Audit run 31067443654](https://github.com/joeypshell/oceangame2/actions/runs/31067443654): passed
- [Godot Web Export run 31067443686](https://github.com/joeypshell/oceangame2/actions/runs/31067443686): browser verification and Pages deployment passed

Public review URLs:

- fresh empty profile: `https://joeypshell.github.io/oceangame2/?review=0b6c1c8fb845a184cc7eb62f386c7d15656bca09`
- pre-rescue milestone checkpoint: `https://joeypshell.github.io/oceangame2/?review=0b6c1c8fb845a184cc7eb62f386c7d15656bca09&checkpoint=living_expedition_01_start`

The `review` query selects isolated state; it does not pin Pages history. Confirm public `build_info.json` still reports the exact SHA before treating the URL as owner evidence.

## Deterministic Evidence

The Living Expedition journey starts from the isolated pre-rescue checkpoint and runs separate Anchor Fins and Guardian Pulse profiles. Both branches passed:

- source-authored Cutter rescue remains possible with full cargo
- canonical-boat return commits the bond exactly once
- the following sortie unlocks BOND, base riding, mounted movement, and Glide Surge
- `held_the_flow` and `stood_ground` qualify and commit only through their meaningful shared events
- Night 2 requires deliberate consolidation of the earned adaptation
- both adaptations work in independent and mounted roles on Day 3
- Retry restores unmounted, full-speed control
- profile isolation, health, oxygen, day/sortie, action, memory, and payoff are reported

Focused owner smokes also passed rescue/failure restoration, follow/separation, rider clearance, hard equipment-gate protection, hotbar ownership, mobile BOND, exact-once memory/profile reload, forced dismount, eel/Shock Prod behavior, current/Fins behavior, and oxygen failure.

## Visual Stability

`compare-all` regenerated all six configured review sheets. Every difference column remained empty/black for `production_level_01`, slices 01-04, and `transfer_hub_interior_01`. `check-clean --all-slices` passed for every accepted baseline directory.

No baseline was accepted or replaced. The only new visual evidence is the ignored Living Expedition capture set: 11 states at desktop `1280x720` and landscape-mobile `844x390`, covering rescue, follow, command palette, base riding, both memories, night choice, and independent/mounted payoff for both adaptations. Sampled frames showed the expected BOND palette, mounted creature hotbar, night choice, current brace, and Guardian Pulse without unrelated terrain, diver, boat, camera, or HUD drift.

## Public Web Evidence

The independent checker confirmed:

- external build metadata matches exact SHA `0b6c1c8fb845a184cc7eb62f386c7d15656bca09`
- root and fresh review load `production_level_01`
- the Living Expedition checkpoint reports isolated state on desktop and landscape mobile
- explicit slice fallback still loads `production_slice_01`
- desktop canvas is 1280x720; wide canvas is 1920x1080
- mobile canvas is 2532x1170 intrinsic at 844x390 CSS, positioned at `(0, 0)`
- root and checkpoint mobile touch controls respond at their rendered positions
- framing mean difference is `1.31`, below the maximum `18`
- no failed requests, page errors, Godot `SCRIPT ERROR`, or Godot `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warning.

## Owner Review Boundary

Automation cannot decide whether Kite feels like an individual partner, BOND is understandable, mounted movement feels embodied, the memories read as earned experiences, the adaptation changes play, or the result motivates another day.

The checkpoint is a fresh isolated **milestone** profile. It commits prior progression through normal profile transactions, then leaves rescue and all partnership state incomplete. A literally empty historical profile cannot reach the Cutter-gated rescue on its first day; use the empty URL for startup/progression regression and the checkpoint for the natural three-day partnership proof.

For the owner review:

1. Open the checkpoint URL in an incognito/private tab and play without external instructions until Day 3 or the first unclear/broken moment.
2. Rescue Kite, return to the canonical boat, and test BOND/riding on the following sortie.
3. Earn one shared memory, choose its night adaptation, and test its independent and mounted payoff.
4. Restart the isolated checkpoint and test the other memory/adaptation branch.
5. Report GO, HOLD, or the smallest bounded corrections, especially whether the proof creates attachment, build curiosity, and a desire to begin another day.

Issue #1232 and milestone #45 remain open until that verdict is recorded. Do not create Living Expedition 02 or a second species before GO.

## Commands

```powershell
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 0b6c1c8fb845a184cc7eb62f386c7d15656bca09 --checkpoint living_expedition_01_start
python tools/check_file_lengths.py
git diff --check
```

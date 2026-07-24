# Expansion 14 Owner-HOLD Correction Visual Review

Date: 2026-07-24

Issue: #1076

Status: Focused visual review PASS. No accepted baseline was changed.

## Decision

The bounded combat, scanner, relay, and passive-equipment differences are
intentional and match the locked owner-HOLD correction contract. The evidence
does not show terrain, player, boat, camera, unrelated HUD, or slice drift.

## Focused Evidence

- `visual_captures/expansion_06_combat_foundation/`
  - warning and lunge context
  - directional Shock Prod miss
  - connected 1/3-health damage and recoil state
  - 1280x720, 1920x1080, and 844x390 landscape-mobile windows
- `visual_captures/expansion_14_archive_current_return/`
  - passive post-build current
  - ordinary current identification card
  - recognizable Northwest Wreck Relay console
  - mixed full cargo plus separate equipped-capability strip
  - 50% held relay scan and pending boat return
  - 1280x720 and 844x390 landscape-mobile windows

The focused PNGs remain ignored review output. No `.import` sidecars or
transient captures are accepted as source.

## Intentional Differences

- The eel exposes a compact world-local health bar while engaged or damaged.
- A connected Shock Prod discharge visibly joins diver and eel; the damaged
  state leaves a readable spatial opening consistent with bounded recoil.
- A miss projects forward to a small electrical fizzle. The old broad
  semicircle is absent.
- Scanner identification and held progression use the same forward cone but
  distinct target-local text and progress treatment.
- The relay destination has a recognizable source-linked console/signal.
- Passive capabilities occupy a distinct top `EQUIPPED` segment; active tools
  remain in the bottom hotbar and cargo quantities remain separate.

## Mobile Review

The combat capture uses capture-only right-edge padding so the diver, bolt,
eel, and health bar remain in the usable center lane between touch regions.
Expansion 14 mobile frames keep the top cargo/equipment strip clear of the
bottom hotbar and touch controls. Scanner cards remain compact and target-local.

## Stable Areas

`python tools/manage_production_slice_baseline.py compare-all` rendered all
five production-map review sheets with black difference panels. All 35 accepted
PNG files across the full level and four slices were byte-identical to their
current captures. `check-clean --all-slices` passed.

No baseline acceptance is warranted: the corrected subjects are reviewed in
focused states, while the established map overview/opening/return frames remain
unchanged.

## Next Gate

#1077 must verify one exact public Web build and refresh the concise retest
checklist on #1040. #1040 and milestone #40 remain open for owner GO/HOLD; this
visual PASS does not select Expansion 15.

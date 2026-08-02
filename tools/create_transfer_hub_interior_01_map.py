#!/usr/bin/env python3
"""Generate the compact Transfer Hub interior for Expansion 18."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_MAP_PATH = ROOT / "maps" / "transfer_hub_interior_01.greybox.json"
MAP_ID = "transfer_hub_interior_01"
WIDTH = 44
HEIGHT = 28
ENTRY_ID = "transfer_hub_interior_entry"
RETURN_ID = "transfer_hub_interior_return"
EXTERIOR_MAP_ID = "production_level_01"
EXTERIOR_RETURN_ID = "transfer_hub_exterior_return"
EXTERIOR_ENTRANCE_ID = "transfer_hub_exterior_entrance"
CORE_ID = "transfer_hub_navigation_core_cradle"
CORE_DISCOVERY_ID = "transfer_hub_navigation_core_discovery"
BOAT_ID = "surface_boat_entry"


def terrain() -> list[dict]:
    rectangles = (
        ("ceiling", 0, 0, WIDTH, 2),
        ("floor", 0, HEIGHT - 2, WIDTH, 2),
        ("west_wall", 0, 2, 2, HEIGHT - 4),
        ("east_wall", WIDTH - 2, 2, 2, HEIGHT - 4),
        ("upper_west_strut", 8, 2, 5, 4),
        ("upper_east_strut", 27, 2, 5, 5),
        ("lower_west_strut", 9, 22, 7, 4),
        ("lower_east_strut", 26, 22, 6, 4),
        ("navigation_ring_core", 20, 8, 4, 12),
        ("cradle_upper_jaw", 35, 4, 7, 7),
        ("cradle_lower_jaw", 35, 18, 7, 8),
    )
    return [
        {"id": f"transfer_hub_{name}", "type": "solid", "x": x, "y": y, "w": w, "h": h}
        for name, x, y, w, h in rectangles
    ]


def zones() -> list[dict]:
    return [
        {
            "id": "transfer_hub_interior_bounds",
            "type": "marker",
            "x": 0,
            "y": 0,
            "w": WIDTH,
            "h": HEIGHT,
            "intent": "Review extent of the one compact loaded interior.",
        },
        {
            "id": "transfer_hub_navigation_ring_landmark",
            "type": "marker",
            "x": 16,
            "y": 6,
            "w": 12,
            "h": 16,
            "regional_landmark": True,
            "landmark_label": "Transfer Hub Navigation Ring",
            "intent": "Distinct central machinery silhouette anchoring interior navigation.",
        },
        {
            "id": RETURN_ID,
            "type": "marker",
            "x": 2,
            "y": 12,
            "w": 3,
            "h": 5,
            "world_connector": True,
            "connector_kind": "exceptional_interior",
            "connector_label": "Return To Cave",
            "destination_map_id": EXTERIOR_MAP_ID,
            "destination_map_path": f"res://maps/{EXTERIOR_MAP_ID}.greybox.json",
            "destination_entry_id": EXTERIOR_RETURN_ID,
            "connector_direction": "return",
            "paired_connector_id": EXTERIOR_ENTRANCE_ID,
            "intent": "The only paired return from the Transfer Hub to the original cave doorway.",
        },
    ]


def entities() -> list[dict]:
    return [
        {
            "id": ENTRY_ID,
            "type": "spawn",
            "x": 6,
            "y": 14,
            "intent": "Arrival point inside the original paired doorway.",
        },
        {
            "id": CORE_ID,
            "type": "tool_target",
            "x": 38,
            "y": 14,
            "kind": "crate",
            "tier": "valuable",
            "interaction": "cutter_salvage",
            "interaction_seconds": 2.5,
            "interaction_label": "navigation core",
            "required_tool_id": "salvage_cutter",
            "tool_project_id": "salvage_cutter_project",
            "reward_kind": "held_discovery_cargo",
            "reward_id": CORE_DISCOVERY_ID,
            "reward_pending_label": "Navigation core secured | Return to the boat",
            "reward_commit_label": "Navigation core delivered",
            "reward_next_lead_label": "Transfer Hub core ready for night analysis",
            "reward_commit_map_id": EXTERIOR_MAP_ID,
            "reward_commit_map_path": f"res://maps/{EXTERIOR_MAP_ID}.greybox.json",
            "reward_commit_entry_id": BOAT_ID,
            "intent": "One deliberate Cutter recovery whose discovery commits only at the canonical boat.",
        },
    ]


def background() -> list[dict]:
    return [
        {
            "id": "transfer_hub_navigation_ring_backdrop",
            "type": "background",
            "x": 14,
            "y": 4,
            "w": 16,
            "h": 20,
            "intent": "Large non-collision machinery silhouette around the central ring.",
        },
        {
            "id": "transfer_hub_core_cradle_backdrop",
            "type": "background",
            "x": 33,
            "y": 9,
            "w": 9,
            "h": 10,
            "intent": "Non-collision cradle silhouette framing the navigation core.",
        },
    ]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "transfer_hub_interior_overview",
            "center_x": 22.0,
            "center_y": 14.0,
            "zoom": 0.52,
            "intent": "Whole-interior topology, paired doorway, landmark, and core review.",
        },
        {
            "id": "transfer_hub_interior_arrival",
            "center_x": 6.0,
            "center_y": 14.0,
            "zoom": 0.85,
            "intent": "Arrival and immediately reachable paired return doorway.",
        },
        {
            "id": "transfer_hub_navigation_ring",
            "center_x": 22.0,
            "center_y": 14.0,
            "zoom": 0.78,
            "intent": "Distinct central navigation-ring landmark and two-sided swim route.",
        },
        {
            "id": "transfer_hub_navigation_core",
            "center_x": 38.0,
            "center_y": 14.0,
            "zoom": 0.95,
            "intent": "Cutter cradle, core target, and uncluttered retreat route.",
        },
    ]


def build_map_data() -> dict:
    return {
        "id": MAP_ID,
        "version": 1,
        "purpose": (
            "Compact source-generated Transfer Hub interior for one continuous-sortie "
            "Cutter recovery and paired return."
        ),
        "source": {
            "generator": "tools/create_transfer_hub_interior_01_map.py",
            "coordinate_space": "interior_map_tiles",
            "topology": "authored_rectangles",
            "review_artifact": "references/greybox/transfer_hub_interior_01.svg",
            "expansion": "transfer_hub_interior_expedition",
            "terrain_changes": [item["id"] for item in terrain()],
        },
        "units": {"tile_size_px": 32, "width_tiles": WIDTH, "height_tiles": HEIGHT},
        "legend": {
            "water": "Enclosed swimmable interior space",
            "solid": "Transfer Hub wall and machinery collision",
            "spawn": "Paired exterior-door arrival only",
            "marker": "Review landmark or paired return",
            "tool_target": "Cutter-released held navigation core",
        },
        "terrain": terrain(),
        "zones": zones(),
        "background": background(),
        "entities": entities(),
        "camera_tests": camera_tests(),
        "review_questions": [
            "Is the paired return obvious from arrival without reading a map menu?",
            "Does the central ring make this compact interior feel different from the cave?",
            "Can the player reach the Cutter cradle and return with a clear footprint route?",
            "Does the map avoid boat, refill, extraction, night, enemy, and second-interior ownership?",
        ],
    }


def main() -> int:
    map_data = build_map_data()
    OUTPUT_MAP_PATH.write_text(
        json.dumps(map_data, indent=2) + "\n", encoding="utf-8", newline="\n"
    )
    print(
        f"Wrote {OUTPUT_MAP_PATH.relative_to(ROOT)} with "
        f"{len(map_data['terrain'])} collision rectangles."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Render a greybox map JSON file to a simple SVG preview."""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path


COLORS = {
    "water": "#16b9ee",
    "grid": "#d8f7ff",
    "solid": "#26333f",
    "solid_edge": "#8ea9b5",
    "base": "#f2d6a2",
    "boat": "#f0a33a",
    "background": "#237fad",
    "spawn": "#29d66f",
    "salvage": "#ffd34a",
    "material": "#5ce1c8",
    "tool_target": "#ffad42",
    "hazard": "#ff4b5f",
    "moving_hazard": "#ff96b0",
    "hostile": "#ff745e",
    "survey": "#69f0dc",
    "marker": "#ffffff",
    "container": "#d68cff",
    "label": "#eaffff",
}


def tile_rect(item: dict, tile_size: int) -> tuple[int, int, int, int]:
    return (
        int(item["x"]) * tile_size,
        int(item["y"]) * tile_size,
        int(item["w"]) * tile_size,
        int(item["h"]) * tile_size,
    )


def entity_center(item: dict, tile_size: int) -> tuple[float, float]:
    return ((float(item["x"]) + 0.5) * tile_size, (float(item["y"]) + 0.5) * tile_size)


def boat_entry_center(item: dict, tile_size: int) -> tuple[float, float]:
    return (
        (float(item.get("entry_x", item["x"])) + 0.5) * tile_size,
        (float(item.get("entry_y", item["y"])) + 0.5) * tile_size,
    )


def text(x: float, y: float, value: str, size: int = 28) -> str:
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" fill="{COLORS["label"]}" '
        f'font-family="Arial, sans-serif" font-size="{size}" '
        f'paint-order="stroke" stroke="#10384a" stroke-width="4">{html.escape(value)}</text>'
    )


def render_svg(map_data: dict) -> str:
    units = map_data["units"]
    tile_size = int(units["tile_size_px"])
    width_px = int(units["width_tiles"]) * tile_size
    height_px = int(units["height_tiles"]) * tile_size

    parts: list[str] = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width_px} {height_px}" width="{width_px}" height="{height_px}">',
        "<defs>",
        '<linearGradient id="water" x1="0" y1="0" x2="0" y2="1">',
        '<stop offset="0%" stop-color="#4ee6ff"/>',
        '<stop offset="55%" stop-color="#13b3ec"/>',
        '<stop offset="100%" stop-color="#0874b7"/>',
        "</linearGradient>",
        f'<pattern id="grid" width="{tile_size}" height="{tile_size}" patternUnits="userSpaceOnUse">',
        f'<path d="M {tile_size} 0 L 0 0 0 {tile_size}" fill="none" stroke="{COLORS["grid"]}" stroke-width="1" opacity="0.22"/>',
        "</pattern>",
        "</defs>",
        f'<rect x="0" y="0" width="{width_px}" height="{height_px}" fill="url(#water)"/>',
    ]

    for bg in map_data.get("background", []):
        x, y, w, h = tile_rect(bg, tile_size)
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{tile_size * 2}" '
            f'fill="{COLORS["background"]}" opacity="0.22"/>'
        )

    for zone in map_data.get("zones", []):
        if zone["type"] != "marker":
            continue
        x, y, w, h = tile_rect(zone, tile_size)
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{COLORS["marker"]}" '
            'opacity="0.08" stroke="#ffffff" stroke-width="4" stroke-dasharray="16 14"/>'
        )
        parts.append(text(x + 12, y + 34, zone["id"], 24))

    for terrain in map_data.get("terrain", []):
        x, y, w, h = tile_rect(terrain, tile_size)
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{COLORS["solid"]}" '
            f'stroke="{COLORS["solid_edge"]}" stroke-width="3"/>'
        )

    for zone in map_data.get("zones", []):
        if zone["type"] != "base":
            continue
        x, y, w, h = tile_rect(zone, tile_size)
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{COLORS["base"]}" '
            'opacity="0.95" stroke="#704e22" stroke-width="4"/>'
        )
        parts.append(text(x + 12, y + 34, "EXTRACT", 28))

    for entity in map_data.get("entities", []):
        cx, cy = entity_center(entity, tile_size)
        entity_type = entity["type"]
        if entity_type == "boat_spawn":
            x, y, w, h = tile_rect(entity, tile_size)
            points = [
                (x, y + h * 0.28),
                (x + w, y + h * 0.28),
                (x + w * 0.82, y + h),
                (x + w * 0.18, y + h),
            ]
            point_text = " ".join(f"{px:.1f},{py:.1f}" for px, py in points)
            ex, ey = boat_entry_center(entity, tile_size)
            parts.append(f'<polygon points="{point_text}" fill="{COLORS["boat"]}" stroke="#6e4210" stroke-width="5"/>')
            parts.append(f'<circle cx="{ex}" cy="{ey}" r="16" fill="{COLORS["base"]}" stroke="#704e22" stroke-width="5"/>')
            parts.append(text(x + 12, y + h + 28, "BOAT", 22))
        elif entity_type == "spawn":
            parts.append(f'<circle cx="{cx}" cy="{cy}" r="18" fill="{COLORS["spawn"]}" stroke="#08351c" stroke-width="5"/>')
            parts.append(text(cx + 24, cy + 10, "START", 22))
        elif entity_type == "salvage":
            r = 17
            points = [
                (cx, cy - r),
                (cx + r, cy),
                (cx, cy + r),
                (cx - r, cy),
            ]
            point_text = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
            parts.append(f'<polygon points="{point_text}" fill="{COLORS["salvage"]}" stroke="#7f5b00" stroke-width="5"/>')
        elif entity_type == "material_candidate":
            parts.append(f'<circle cx="{cx}" cy="{cy}" r="15" fill="{COLORS["material"]}" stroke="#07584f" stroke-width="5"/>')
        elif entity_type == "tool_target":
            parts.append(f'<rect x="{cx - 17}" y="{cy - 17}" width="34" height="34" fill="{COLORS["tool_target"]}" stroke="#6e4210" stroke-width="5"/>')
        elif entity_type == "hazard":
            parts.append(f'<circle cx="{cx}" cy="{cy}" r="19" fill="{COLORS["hazard"]}" stroke="#64121d" stroke-width="5"/>')
            parts.append(f'<line x1="{cx - 12}" y1="{cy - 12}" x2="{cx + 12}" y2="{cy + 12}" stroke="#ffffff" stroke-width="5"/>')
            parts.append(f'<line x1="{cx + 12}" y1="{cy - 12}" x2="{cx - 12}" y2="{cy + 12}" stroke="#ffffff" stroke-width="5"/>')

    for container in map_data.get("progression_containers", []):
        x, y, w, h = tile_rect(container, tile_size)
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{COLORS["container"]}" '
            'stroke="#5b236b" stroke-width="5"/>'
        )
        parts.append(text(x + 8, y - 10, container["id"], 22))

    for target in map_data.get("survey_targets", []):
        x, y, w, h = tile_rect(target, tile_size)
        cx, cy = x + w * 0.5, y + h * 0.5
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{COLORS["survey"]}" '
            'fill-opacity="0.28" stroke="#07584f" stroke-width="6"/>'
        )
        parts.append(f'<circle cx="{cx}" cy="{cy}" r="14" fill="none" stroke="{COLORS["survey"]}" stroke-width="6"/>')
        parts.append(text(x + 8, y - 10, target["id"], 22))

    for hazard in map_data.get("moving_hazards", []):
        path = hazard.get("path", [])
        if len(path) >= 2:
            points = []
            for point in path:
                cx = (point["x"] + 0.5) * tile_size
                cy = (point["y"] + 0.5) * tile_size
                points.append(f"{cx},{cy}")
            parts.append(
                f'<polyline points="{" ".join(points)}" fill="none" stroke="{COLORS["moving_hazard"]}" '
                'stroke-width="5" stroke-dasharray="12 8"/>'
            )
        x = (hazard["x"] + 0.5) * tile_size
        y = (hazard["y"] + 0.5) * tile_size
        parts.append(f'<circle cx="{x}" cy="{y}" r="15" fill="{COLORS["moving_hazard"]}" stroke="#721d35" stroke-width="5"/>')
        parts.append(text(x + 18, y - 18, hazard["id"], 22))

    for hostile in map_data.get("hostile_encounters", []):
        territory = hostile["territory"]
        tx, ty, tw, th = tile_rect(territory, tile_size)
        cx = (hostile["x"] + 0.5) * tile_size
        cy = (hostile["y"] + 0.5) * tile_size
        parts.append(
            f'<rect x="{tx}" y="{ty}" width="{tw}" height="{th}" fill="{COLORS["hostile"]}" '
            'fill-opacity="0.09" stroke="#8f281c" stroke-width="5" stroke-dasharray="14 8"/>'
        )
        parts.append(f'<ellipse cx="{cx}" cy="{cy}" rx="28" ry="14" fill="{COLORS["hostile"]}" stroke="#64180f" stroke-width="5"/>')
        parts.append(text(cx + 34, cy - 18, hostile["id"], 22))

    parts.extend(
        [
            f'<rect x="0" y="0" width="{width_px}" height="{height_px}" fill="url(#grid)"/>',
            text(24, 42, f'{map_data["id"]} - greybox source preview', 30),
            text(24, height_px - 42, "cyan=open | gray=solid | tan=extraction | orange=boat/tool | green=start | yellow=salvage | teal=material/survey", 22),
            text(24, height_px - 16, "red=hazard | pink=moving | coral=hostile | purple=container", 22),
            "</svg>",
            "",
        ]
    )

    return "\n".join(parts)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", type=Path)
    parser.add_argument("output_svg", type=Path)
    args = parser.parse_args()

    with args.map_json.open("r", encoding="utf-8") as handle:
        map_data = json.load(handle)

    args.output_svg.parent.mkdir(parents=True, exist_ok=True)
    args.output_svg.write_text(render_svg(map_data), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

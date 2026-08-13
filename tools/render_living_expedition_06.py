"""Render focused Signal Reef nursery source records."""

from __future__ import annotations

import html


SCHOOL_COLOR = "#66f5ff"
NURSERY_COLOR = "#78f0b1"
PRESSURE_COLOR = "#ff96b0"
ACTION_COLOR = "#ffd76a"
LABEL_COLOR = "#eaffff"


def _center(item: dict, tile_size: int) -> tuple[float, float]:
    return (
        (float(item["x"]) + float(item.get("w", 1)) * 0.5) * tile_size,
        (float(item["y"]) + float(item.get("h", 1)) * 0.5) * tile_size,
    )


def _label(x: float, y: float, value: str) -> str:
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" fill="{LABEL_COLOR}" '
        'font-family="Arial, sans-serif" font-size="20" paint-order="stroke" '
        f'stroke="#10384a" stroke-width="4">{html.escape(value)}</text>'
    )


def _index(map_data: dict) -> dict[str, dict]:
    return {
        str(item["id"]): item
        for collection in (
            "entities", "zones", "passive_wildlife_groups", "creature_nurseries",
            "ecological_pressures",
        )
        for item in map_data.get(collection, [])
        if isinstance(item, dict) and "id" in item
    }


def render_living_expedition_06(map_data: dict, tile_size: int) -> list[str]:
    parts: list[str] = []
    records = _index(map_data)
    for pressure in map_data.get("ecological_pressures", []):
        x = int(pressure["x"]) * tile_size
        y = int(pressure["y"]) * tile_size
        w = int(pressure["w"]) * tile_size
        h = int(pressure["h"]) * tile_size
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{PRESSURE_COLOR}" '
            'fill-opacity="0.13" stroke="#8f3f67" stroke-width="5" stroke-dasharray="10 7"/>'
        )
        points = [
            ((float(point["x"]) + 0.5) * tile_size, (float(point["y"]) + 0.5) * tile_size)
            for point in pressure.get("path", [])
        ]
        if len(points) >= 2:
            parts.append(
                f'<polyline points="{" ".join(f"{px},{py}" for px, py in points)}" '
                f'fill="none" stroke="{PRESSURE_COLOR}" stroke-width="7"/>'
            )
        parts.append(_label(x + 10, y - 10, str(pressure["id"])))

    for school in map_data.get("passive_wildlife_groups", []):
        points = [
            ((float(point["x"]) + 0.5) * tile_size, (float(point["y"]) + 0.5) * tile_size)
            for point in school.get("path", [])
        ]
        if len(points) >= 2:
            parts.append(
                f'<polyline points="{" ".join(f"{px},{py}" for px, py in points)}" '
                f'fill="none" stroke="{SCHOOL_COLOR}" stroke-width="6" stroke-dasharray="12 7"/>'
            )
        for px, py in points:
            parts.append(
                f'<path d="M {px - 16} {py} Q {px} {py - 10} {px + 16} {py} '
                f'Q {px} {py + 10} {px - 16} {py}" fill="none" '
                f'stroke="{SCHOOL_COLOR}" stroke-width="4"/>'
            )
        if points:
            parts.append(_label(points[0][0] + 20, points[0][1] - 18, str(school["id"])))

    for nursery in map_data.get("creature_nurseries", []):
        x = int(nursery["x"]) * tile_size
        y = int(nursery["y"]) * tile_size
        w = int(nursery["w"]) * tile_size
        h = int(nursery["h"]) * tile_size
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" '
            f'fill="{NURSERY_COLOR}" fill-opacity="0.14" stroke="{NURSERY_COLOR}" '
            'stroke-width="6"/>'
        )
        parts.append(_label(x + 10, y + h + 24, str(nursery["id"])))

    for context in map_data.get("companion_contexts", []):
        if context.get("context_kind") != "regional_journey_action":
            continue
        target = records.get(str(context.get("target_id", "")))
        if target is None:
            continue
        tx, ty = _center(target, tile_size)
        parts.append(
            f'<path d="M {tx} {ty - 20} L {tx + 20} {ty} L {tx} {ty + 20} '
            f'L {tx - 20} {ty} Z" fill="none" stroke="{ACTION_COLOR}" stroke-width="5"/>'
        )
        parts.append(_label(tx + 18, ty - 18, str(context["id"])))
    return parts

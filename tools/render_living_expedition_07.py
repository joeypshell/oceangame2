"""Review-only SVG projection of Marl's refuge and ground anchors."""

from __future__ import annotations

import html


def render_living_expedition_07(map_data: dict, tile_size: int) -> list[str]:
    parts = []

    def center(point: dict) -> tuple[float, float]:
        return ((point["x"] + 0.5) * tile_size, (point["y"] + 0.5) * tile_size)

    def label(x: float, y: float, value: str) -> None:
        parts.append(
            f'<text x="{x}" y="{y}" fill="#eaffff" font-family="Arial,sans-serif" '
            'font-size="16" paint-order="stroke" stroke="#10384a" stroke-width="4">'
            f'{html.escape(value)}</text>'
        )

    for refuge in map_data.get("burrow_refuges", []):
        x, y, w, h = (refuge[key] * tile_size for key in ("x", "y", "w", "h"))
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" '
            'fill="#d7c17d" fill-opacity="0.25" stroke="#ffd76a" stroke-width="4"/>'
        )
        path = " ".join(f"{px},{py}" for px, py in map(center, refuge["wildlife_path"]))
        parts.append(
            f'<polyline points="{path}" fill="none" stroke="#78f0b1" '
            'stroke-width="5" stroke-dasharray="6 4"/>'
        )
        for field, color in (("approach_point", "#66f5ff"), ("dig_point", "#ffd76a")):
            px, py = center(refuge[field])
            parts.append(f'<circle cx="{px}" cy="{py}" r="6" fill="{color}"/>')
        label(x - 150, y - 12, str(refuge["id"]))
        label(x - 150, y + h + 34, "cyan: approach / gold: dig / green: scallops")
    for context in map_data.get("companion_contexts", []):
        if context.get("action_id") != "ground_pin":
            continue
        for anchor in context["ground_anchors"]:
            x, y = center(anchor)
            parts.append(
                f'<path d="M {x-12} {y+9} L {x-12} {y+16} L {x+12} {y+16} '
                f'L {x+12} {y+9}" fill="none" stroke="#ff96b0" stroke-width="4"/>'
            )
        x, y = center(context["ground_anchors"][-1])
        label(x + 38, y + 15, "Ground Pin anchors")
    return parts

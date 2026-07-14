#!/usr/bin/env python3
"""Small normalization helpers shared by the progression graph builder."""

from __future__ import annotations

from typing import Any


def items(payload: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def as_list(value: Any) -> list[Any]:
    if value is None or value == "":
        return []
    return value if isinstance(value, list) else [value]


def as_dict(value: Any) -> dict[Any, Any]:
    return value if isinstance(value, dict) else {}


def display(value: str) -> str:
    return value.replace("_", " ").strip().title()


def item_label(item: dict[str, Any]) -> str:
    fields = (
        "label",
        "project_label",
        "display_label",
        "connector_label",
        "current_gate_label",
        "visibility_label",
        "interaction_label",
        "route_label",
    )
    for field in fields:
        value = str(item.get(field, "")).strip()
        if value:
            return value
    return display(str(item.get("id", "")))


def requirement_id(item: dict[str, Any]) -> str:
    return str(item.get("required_upgrade_id") or item.get("required_capability_id") or "")


def rects_overlap(left: dict[str, Any], right: dict[str, Any]) -> bool:
    try:
        return not (
            int(left["x"]) + int(left.get("w", 1)) <= int(right["x"])
            or int(right["x"]) + int(right.get("w", 1)) <= int(left["x"])
            or int(left["y"]) + int(left.get("h", 1)) <= int(right["y"])
            or int(right["y"]) + int(right.get("h", 1)) <= int(left["y"])
        )
    except (KeyError, TypeError, ValueError):
        return False

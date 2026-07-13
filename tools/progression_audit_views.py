#!/usr/bin/env python3
"""Load separate, explicit map views for the progression audit."""

from __future__ import annotations

import copy
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from progression_graph import ProgressionGraph, ROOT, build_progression_graph, load_production_maps


CONFIG_PATH = ROOT / "config" / "progression_audit_views.json"
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")


@dataclass(frozen=True)
class ProgressionAuditView:
    id: str
    label: str
    map_paths: tuple[Path, ...]
    expected_map_ids: tuple[str, ...]
    map_id_aliases: dict[str, str]
    detailed_review: bool

    @property
    def source_paths(self) -> str:
        return ", ".join(f"`{path.relative_to(ROOT).as_posix()}`" for path in self.map_paths)


def load_audit_views(path: Path = CONFIG_PATH) -> tuple[ProgressionAuditView, ...]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"Could not load progression audit views {path}: {exc}") from exc
    failures = _validate_payload(payload)
    if failures:
        raise ValueError("Invalid progression audit views:\n- " + "\n- ".join(failures))

    views: list[ProgressionAuditView] = []
    for item in payload["views"]:
        paths = tuple((ROOT / raw_path).resolve() for raw_path in item["map_paths"])
        views.append(ProgressionAuditView(
            str(item["id"]),
            str(item["label"]),
            paths,
            tuple(str(map_id) for map_id in item["expected_map_ids"]),
            {str(source): str(target) for source, target in item["map_id_aliases"].items()},
            bool(item["detailed_review"]),
        ))
    return tuple(views)


def build_view_graph(view: ProgressionAuditView, base_contract: dict[str, Any]) -> ProgressionGraph:
    maps = load_production_maps(view.map_paths)
    actual_ids = tuple(str(item.get("id", "")) for item in maps)
    if actual_ids != view.expected_map_ids:
        raise ValueError(
            f"Audit view {view.id!r} expected map ids {view.expected_map_ids}, got {actual_ids}."
        )
    contract = copy.deepcopy(base_contract)
    _remap_contract_maps(contract, view.map_id_aliases)
    canonical_map = str(contract["canonical_start"]["map_id"])
    if canonical_map not in actual_ids:
        raise ValueError(
            f"Audit view {view.id!r} canonical map {canonical_map!r} is not one of {actual_ids}."
        )
    return build_progression_graph(maps, contract)


def _remap_contract_maps(contract: dict[str, Any], aliases: dict[str, str]) -> None:
    start = contract["canonical_start"]
    start["map_id"] = aliases.get(str(start["map_id"]), str(start["map_id"]))
    for collection in ("session_upgrades", "durable_purchases"):
        for item in contract[collection]:
            if "purchase_map_id" in item:
                map_id = str(item["purchase_map_id"])
                item["purchase_map_id"] = aliases.get(map_id, map_id)


def _validate_payload(payload: Any) -> list[str]:
    if not isinstance(payload, dict):
        return ["root must be an object"]
    failures: list[str] = []
    if payload.get("version") != 1:
        failures.append("version must equal 1")
    views = payload.get("views")
    if not isinstance(views, list) or not views:
        return failures + ["views must be a non-empty array"]
    seen_ids: set[str] = set()
    detailed_count = 0
    for index, item in enumerate(views):
        label = f"views[{index}]"
        if not isinstance(item, dict):
            failures.append(f"{label} must be an object")
            continue
        view_id = item.get("id")
        if not isinstance(view_id, str) or not ID_PATTERN.fullmatch(view_id):
            failures.append(f"{label}.id must be lower_snake_case")
        elif view_id in seen_ids:
            failures.append(f"duplicate audit view id {view_id!r}")
        else:
            seen_ids.add(view_id)
        if not isinstance(item.get("label"), str) or not item["label"].strip():
            failures.append(f"{label}.label must be non-empty text")
        paths = item.get("map_paths")
        map_ids = item.get("expected_map_ids")
        if not isinstance(paths, list) or not paths:
            failures.append(f"{label}.map_paths must be a non-empty array")
        elif len(paths) != len(set(paths)):
            failures.append(f"{label}.map_paths must not contain duplicates")
        else:
            for raw_path in paths:
                _validate_map_path(raw_path, f"{label}.map_paths", failures)
        if not isinstance(map_ids, list) or not map_ids or len(map_ids) != len(paths or []):
            failures.append(f"{label}.expected_map_ids must match map_paths")
        else:
            for map_id in map_ids:
                if not isinstance(map_id, str) or not ID_PATTERN.fullmatch(map_id):
                    failures.append(f"{label}.expected_map_ids must contain lower_snake_case ids")
        aliases = item.get("map_id_aliases")
        if not isinstance(aliases, dict):
            failures.append(f"{label}.map_id_aliases must be an object")
        else:
            for source, target in aliases.items():
                if not ID_PATTERN.fullmatch(str(source)) or not ID_PATTERN.fullmatch(str(target)):
                    failures.append(f"{label}.map_id_aliases must map lower_snake_case ids")
        if not isinstance(item.get("detailed_review"), bool):
            failures.append(f"{label}.detailed_review must be boolean")
        elif item["detailed_review"]:
            detailed_count += 1
    if detailed_count != 1:
        failures.append("exactly one audit view must set detailed_review")
    return failures


def _validate_map_path(value: Any, label: str, failures: list[str]) -> None:
    if not isinstance(value, str) or not value.endswith(".greybox.json"):
        failures.append(f"{label} entries must be relative .greybox.json paths")
        return
    candidate = (ROOT / value).resolve()
    if not candidate.is_relative_to(ROOT) or not candidate.is_file():
        failures.append(f"{label} entry {value!r} must resolve to a committed map under the repository")

#!/usr/bin/env python3
"""Build a cross-map progression dependency graph from production map data."""
from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

from progression_graph_contract import CANONICAL_CHAIN_IDS, CANONICAL_EXTENSION_CHAINS
from progression_graph_investigations import add_wreck_network_investigations
from progression_graph_helpers import (
    add_discovery_reward_edges as _add_discovery_reward_edges,
    as_dict as _dict,
    as_list as _list,
    display as _display,
    item_label as _item_label,
    items as _items,
    rects_overlap as _rects_overlap,
    requirement_id as _requirement_id,
)

ROOT = Path(__file__).resolve().parents[1]
PRODUCTION_MAP_PATHS = tuple(sorted((ROOT / "maps").glob("production_slice_*.greybox.json")))
ENTRY_TYPES = {"boat_spawn", "spawn"}
WALLET_ENTITY_TYPES = {"salvage", "tool_target"}
@dataclass
class Node:
    key: str
    label: str
    kind: str
    map_id: str = ""
    route: str = ""
    mandatory: bool = False
    attrs: dict[str, Any] = field(default_factory=dict)
@dataclass(frozen=True)
class Edge:
    source: str
    target: str
    relation: str
    hard: bool = False
    note: str = ""
    quantity: int = 0
@dataclass
class ProgressionGraph:
    nodes: dict[str, Node] = field(default_factory=dict)
    edges: list[Edge] = field(default_factory=list)
    raw_ids: dict[str, list[str]] = field(default_factory=dict)

    def add_node(self, node: Node, raw_id: str = "") -> Node:
        existing = self.nodes.get(node.key)
        if existing is not None:
            existing.mandatory = existing.mandatory or node.mandatory
            existing.attrs.update(node.attrs)
            return existing
        self.nodes[node.key] = node
        if raw_id:
            self.raw_ids.setdefault(raw_id, []).append(node.key)
        return node

    def add_edge(
        self,
        source: str,
        target: str,
        relation: str,
        *,
        hard: bool = False,
        note: str = "",
        quantity: int = 0,
    ) -> None:
        edge = Edge(source, target, relation, hard, note, quantity)
        if edge not in self.edges:
            self.edges.append(edge)

    def resolve(self, raw_id: str, preferred_map: str = "") -> str:
        matches = self.raw_ids.get(raw_id, [])
        if preferred_map:
            local = [key for key in matches if self.nodes[key].map_id == preferred_map]
            if len(local) == 1:
                return local[0]
        if len(matches) == 1:
            return matches[0]
        suffix = "ambiguous" if matches else "missing"
        return f"unresolved:{suffix}:{preferred_map}:{raw_id}"

    def requirements(self, key: str) -> list[Edge]:
        return [edge for edge in self.edges if edge.source == key and edge.relation == "requires" and edge.hard]

    def incoming(self, key: str, relation: str) -> list[Edge]:
        return [edge for edge in self.edges if edge.target == key and edge.relation == relation]

    def outgoing(self, key: str, relation: str = "") -> list[Edge]:
        return [edge for edge in self.edges if edge.source == key and (not relation or edge.relation == relation)]


def load_production_maps(paths: Iterable[Path] = PRODUCTION_MAP_PATHS) -> list[dict[str, Any]]:
    maps: list[dict[str, Any]] = []
    for path in paths:
        payload = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise ValueError(f"{path} must contain a JSON object")
        payload["_source_path"] = str(path.relative_to(ROOT)).replace("\\", "/")
        maps.append(payload)
    return maps


class ProgressionGraphBuilder:
    def __init__(self, maps: list[dict[str, Any]], contract: dict[str, Any]) -> None:
        self.maps = maps
        self.contract = contract
        self.graph = ProgressionGraph()
        self.items_by_map: dict[str, list[tuple[str, dict[str, Any]]]] = {}

    def build(self) -> ProgressionGraph:
        self._add_global_nodes()
        for map_data in self.maps:
            self._add_map_nodes(map_data)
        for map_data in self.maps: add_wreck_network_investigations(self.graph, map_data, Node)
        for map_data in self.maps: self._add_map_edges(map_data)
        self._add_purchase_edges()
        self._mark_mandatory_chain()
        return self.graph

    def _add_global_nodes(self) -> None:
        for item in self.contract["session_upgrades"]:
            self.graph.add_node(Node(f"upgrade:{item['id']}", _display(item["id"]), "upgrade", attrs=dict(item)), item["id"])
        for item in self.contract["durable_capabilities"]:
            self.graph.add_node(Node(f"capability:{item['id']}", _display(item["id"]), "capability", attrs={**item, "declaration_only": True}), item["id"])
        for item in self.contract["durable_purchases"]:
            self.graph.add_node(Node(f"capability:{item['id']}", _display(item["id"]), "capability", attrs=dict(item)), item["id"])

    def _add_map_nodes(self, map_data: dict[str, Any]) -> None:
        map_id = str(map_data.get("id", ""))
        start = self.contract["canonical_start"]
        self.graph.add_node(Node(f"map:{map_id}", map_id, "map", map_id, attrs={"start": map_id == start["map_id"]}), map_id)
        collections = (
            "entities",
            "zones",
            "progression_containers",
            "route_objectives",
            "next_dive_objective_prompts",
            "relay_follow_through_objectives",
            "final_dive_objective_seeds",
            "regional_journeys",
            "survey_targets",
            "material_candidate_pools",
            "material_projects",
            "hostile_encounters",
            "biological_resource_sources",
        )
        for collection in collections:
            for item in _items(map_data, collection):
                kind = self._kind_for(collection, item)
                if not kind:
                    continue
                raw_id = str(item.get("id", ""))
                key = f"{kind}:{map_id}/{raw_id}"
                attrs = dict(item)
                attrs["collection"] = collection
                if kind in WALLET_ENTITY_TYPES:
                    tier = str(item.get("tier", "common"))
                    attrs["wallet_reward"] = int(self.contract["salvage_score_by_tier"].get(tier, 0))
                if kind == "container" and item.get("reward_type") == "wallet":
                    attrs["wallet_reward"] = int(item.get("reward_amount", 0))
                self.graph.add_node(Node(
                    key,
                    _item_label(item),
                    kind,
                    map_id,
                    str(item.get("route_context", "")),
                    mandatory=kind == "regional_journey",
                    attrs=attrs,
                ), raw_id)
                self.items_by_map.setdefault(map_id, []).append((key, item))
                if (discovery_id := str(item.get("reward_id", ""))) and ((kind == "container" and item.get("reward_type") == "blueprint") or item.get("reward_kind") in {"discovery", "held_discovery_cargo"}):
                    self.graph.add_node(Node(f"discovery:{discovery_id}", _display(discovery_id), "discovery", map_id), discovery_id)
                if kind == "hostile":
                    defeat_key = f"defeat:{map_id}/{raw_id}"
                    self.graph.add_node(Node(defeat_key, f"Defeat {_display(raw_id)}", "defeat", map_id, str(item.get("route_context", ""))), f"defeat_{raw_id}")
                if kind in {"material_pool", "biological_source", "material_source"}:
                    material_id = str(item.get("material_id", ""))
                    if material_id:
                        self.graph.add_node(Node(f"material:{material_id}", _display(material_id), "material"), material_id)
                if kind == "project":
                    capability_id = str(item.get("unlocks_capability_id", ""))
                    if capability_id:
                        self.graph.add_node(Node(f"capability:{capability_id}", _display(capability_id), "capability"), capability_id)
                    for material_id in _dict(item.get("required_materials")):
                        self.graph.add_node(Node(f"material:{material_id}", _display(material_id), "material"), material_id)
                if kind == "survey" and (discovery_id := str(item.get("discovery_id", ""))):
                    self.graph.add_node(Node(f"discovery:{discovery_id}", _display(discovery_id), "discovery", map_id, str(item.get("route_context", ""))), discovery_id)
        for item in _items(map_data, "survey_targets"):
            if reward_id := str(item.get("scan_reward_id", "")):
                self.graph.add_node(Node(f"discovery:{reward_id}", _display(reward_id), "discovery", map_id, str(item.get("route_context", ""))), reward_id)

    def _kind_for(self, collection: str, item: dict[str, Any]) -> str:
        if collection == "entities":
            item_type = str(item.get("type", ""))
            if item_type in ENTRY_TYPES:
                return "entry"
            if item_type in WALLET_ENTITY_TYPES:
                return item_type
            if item_type == "material_candidate":
                return "material_source"
            return ""
        if collection == "zones":
            if item.get("world_connector") is True:
                return "connector"
            if item.get("current_gate") is True:
                return "gate"
            if item.get("pressure_zone") is True or item.get("visibility_zone") is True or item.get("oxygen_consumption_zone") is True:
                return "pressure"
            if item.get("regional_landmark") is True:
                return "landmark"
            return ""
        return {
            "progression_containers": "container",
            "route_objectives": "objective",
            "next_dive_objective_prompts": "prompt",
            "relay_follow_through_objectives": "relay_objective",
            "final_dive_objective_seeds": "signal",
            "regional_journeys": "regional_journey",
            "survey_targets": "survey",
            "material_candidate_pools": "material_pool",
            "material_projects": "project",
            "hostile_encounters": "hostile",
            "biological_resource_sources": "biological_source",
        }.get(collection, "")

    def _add_map_edges(self, map_data: dict[str, Any]) -> None:
        map_id = str(map_data.get("id", ""))
        map_key = f"map:{map_id}"
        for key, item in self.items_by_map.get(map_id, []):
            node = self.graph.nodes[key]
            self.graph.add_edge(map_key, key, "contains")
            self.graph.add_edge(key, map_key, "requires", hard=True)
            if node.kind == "connector":
                self._connector_edges(key, item, map_id)
            elif node.kind == "container":
                self._container_edges(key, item, map_id)
            elif node.kind in {"gate", "pressure"}:
                self._gate_edges(key, item)
            elif node.kind == "objective":
                self._required_id_edges(key, item.get("required_banked_targets"), map_id)
            elif node.kind == "prompt":
                self._prompt_edges(key, item, map_id)
            elif node.kind == "relay_objective":
                self._relay_edges(key, item, map_id)
            elif node.kind == "signal":
                self._signal_edges(key, item, map_id)
            elif node.kind == "regional_journey":
                self._regional_journey_edges(key, item, map_id)
            elif node.kind == "survey":
                self._survey_edges(key, item, map_id)
            elif node.kind == "material_pool":
                self._pool_edges(key, item, map_id)
            elif node.kind == "project":
                self._project_edges(key, item, map_id)
            elif node.kind == "hostile":
                self._hostile_edges(key, item, map_id)
            elif node.kind == "biological_source":
                self._biological_edges(key, item, map_id)
            elif node.kind in {"salvage", "tool_target", "material_source"}:
                self._entity_edges(key, item, map_id)

    def _connector_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        destination_map = str(item.get("destination_map_id", ""))
        destination_entry = str(item.get("destination_entry_id", ""))
        self.graph.add_edge(key, f"map:{destination_map}", "travels_to", note=destination_entry)
        self.graph.add_edge(key, self.graph.resolve(destination_entry, destination_map), "travels_to")
        if required_discovery := str(item.get("required_discovery_id", "")): self.graph.add_edge(key, self.graph.resolve(required_discovery), "requires", hard=True)
        for gate_key, gate in self.items_by_map.get(map_id, []):
            if self.graph.nodes[gate_key].kind == "gate" and _rects_overlap(item, gate):
                requirement = _requirement_id(gate)
                if requirement:
                    self.graph.add_edge(key, self.graph.resolve(requirement), "requires", hard=True, note=f"via {gate.get('id')}")
    def _container_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        self._apply_route_gate(key, item, map_id)
        if item.get("reward_type") != "blueprint":
            return
        discovery_key = self.graph.resolve(str(item.get("reward_id", "")))
        self.graph.add_edge(discovery_key, key, "requires", hard=True, note="recovered plan")
        self.graph.add_edge(key, discovery_key, "unlocks")

    def _gate_edges(self, key: str, item: dict[str, Any]) -> None:
        requirement = _requirement_id(item)
        if not requirement:
            return
        requirement_key = self.graph.resolve(requirement)
        hard = (self.graph.nodes[key].kind == "gate" or item.get("pressure_zone") is True) and item.get("visual_only") is not True
        self.graph.add_edge(key, requirement_key, "requires", hard=hard, note="hard gate" if hard else "soft pressure")
        self.graph.add_edge(requirement_key, key, "unlocks", note="hard gate" if hard else "improves soft pressure")

    def _prompt_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        self._required_id_edges(key, [item.get("objective_id")], map_id)
        target = self.graph.resolve(str(item.get("target_id", "")), map_id)
        self.graph.add_edge(key, target, "targets")

    def _relay_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        self._required_id_edges(key, [item.get("target_id")], map_id)
        source_prompt = str(item.get("source_prompt_id", ""))
        if source_prompt:
            self._required_id_edges(key, [source_prompt])

    def _signal_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        self._required_id_edges(key, [item.get("source_objective_id"), item.get("target_id")], map_id)

    def _regional_journey_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        requirement = str(item.get("required_capability_id", ""))
        if requirement:
            self.graph.add_edge(key, self.graph.resolve(requirement), "requires", hard=True)
        self._required_id_edges(key, [item.get("required_discovery_id")], map_id)
        references = [
            item.get("promise_gate_id"),
            *_list(item.get("entry_gate_ids")),
            item.get("landmark_zone_id"),
            item.get("tool_target_id"), item.get("payoff_target_id"),
            item.get("commit_entry_id"),
        ]
        for raw_id in references:
            if raw_id:
                self.graph.add_edge(key, self.graph.resolve(str(raw_id), map_id), "targets")
        survey_id = str(item.get("survey_target_id", ""))
        if survey_id:
            self.graph.add_edge(key, self.graph.resolve(survey_id, map_id), "unlocks")

    def _survey_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        self._required_id_edges(key, [item.get("required_capability_id"), item.get("required_light_capability_id"), item.get("required_pressure_capability_id")])
        route_id = str(item.get("required_route_id", ""))
        if route_id:
            route_key = self.graph.resolve(route_id, map_id)
            self.graph.add_edge(key, route_key, "requires", hard=True, note="regional route")
            self.graph.add_edge(route_key, key, "unlocks")
        else:
            self._apply_route_gate(key, item, map_id)
        for discovery_id in sorted({str(item.get(field, "")) for field in ("discovery_id", "scan_reward_id")} - {""}):
            discovery_key = self.graph.resolve(discovery_id)
            self.graph.add_edge(discovery_key, key, "requires", hard=True, note="survey and commit")
            commit_map = str(item.get("commit_map_id", ""))
            if commit_map:
                self.graph.add_edge(discovery_key, f"map:{commit_map}", "requires", hard=True, note="commit destination")
                commit_entry = str(item.get("commit_entry_id", ""))
                if commit_entry:
                    self.graph.add_edge(discovery_key, self.graph.resolve(commit_entry, commit_map), "requires", hard=True, note="commit entry")
            self.graph.add_edge(key, discovery_key, "unlocks")

    def _pool_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        candidates = [self.graph.resolve(str(raw_id), map_id) for raw_id in _list(item.get("candidate_ids"))]
        self.graph.nodes[key].attrs["candidate_keys"] = candidates
        material_id = str(item.get("material_id", ""))
        quantity = max(0, int(item.get("select_count", 0)))
        relation = "optional_reward" if item.get("pool_role") == "optional_bonus" else "rewards"
        self.graph.add_edge(key, f"material:{material_id}", relation, quantity=quantity)
        for candidate in candidates:
            self.graph.add_edge(key, candidate, "contains")

    def _project_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        self._required_id_edges(key, [item.get("required_project_id"), item.get("required_discovery_id")], map_id)
        required_materials = {str(k): int(v) for k, v in _dict(item.get("required_materials")).items()}
        self.graph.nodes[key].attrs["required_materials"] = required_materials
        for material_id in required_materials:
            self.graph.add_edge(key, f"material:{material_id}", "requires", hard=True, note=f"quantity {required_materials[material_id]}")
        capability_id = str(item.get("unlocks_capability_id", ""))
        if capability_id:
            capability_key = self.graph.resolve(capability_id)
            self.graph.add_edge(capability_key, key, "requires", hard=True)
            self.graph.add_edge(key, capability_key, "unlocks")
        for target_field in ("target_id", "target_gate_id", "target_hostile_id"):
            target_id = str(item.get(target_field, ""))
            if target_id:
                self.graph.add_edge(key, self.graph.resolve(target_id, map_id), "targets")

    def _hostile_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        defeat_key = f"defeat:{map_id}/{item.get('id')}"
        self.graph.add_edge(defeat_key, key, "requires", hard=True, note="encounter")
        weapon = str(item.get("required_weapon_capability_id", ""))
        if weapon:
            self.graph.add_edge(defeat_key, self.graph.resolve(weapon), "requires", hard=True, note="counter")

    def _biological_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        capability = str(item.get("required_capability_id", ""))
        if capability:
            self.graph.add_edge(key, self.graph.resolve(capability), "requires", hard=True)
        hostile_id = str(item.get("hostile_id", ""))
        if hostile_id:
            defeat_key = f"defeat:{map_id}/{hostile_id}"
            self.graph.add_edge(key, defeat_key, "requires", hard=True, note="post-defeat harvest")
        self._apply_route_gate(key, item, map_id)
        material_id = str(item.get("material_id", ""))
        quantity = int(item.get("material_quantity", 0))
        self.graph.add_edge(key, f"material:{material_id}", "rewards", quantity=quantity)

    def _entity_edges(self, key: str, item: dict[str, Any], map_id: str) -> None:
        for field in ("required_capability_id", "required_tool_id"):
            requirement = str(item.get(field, ""))
            if requirement:
                self.graph.add_edge(key, self.graph.resolve(requirement), "requires", hard=True)
        guard_id = str(item.get("guarded_by_hostile_id", ""))
        if guard_id:
            hostile_key = self.graph.resolve(guard_id, map_id)
            defeat_key = f"defeat:{map_id}/{guard_id}"
            self.graph.add_edge(hostile_key, key, "guards", note="explicit hard guard")
            self.graph.add_edge(key, defeat_key, "requires", hard=True, note="guard defeated")
        survey_id = str(item.get("unlocks_survey_target_id", ""))
        if survey_id:
            survey_key = self.graph.resolve(survey_id, map_id)
            self.graph.add_edge(survey_key, key, "requires", hard=True, note="tool target clearance")
            self.graph.add_edge(key, survey_key, "unlocks")
        _add_discovery_reward_edges(self.graph, key, item)
        self._apply_route_gate(key, item, map_id)

    def _apply_route_gate(self, key: str, item: dict[str, Any], map_id: str) -> None:
        route = str(item.get("route_context", ""))
        if not route:
            return
        for gate_key, gate in self.items_by_map.get(map_id, []):
            if self.graph.nodes[gate_key].kind != "gate" or str(gate.get("route_context", "")) != route:
                continue
            requirement = _requirement_id(gate)
            if requirement:
                self.graph.add_edge(key, self.graph.resolve(requirement), "requires", hard=True, note=f"behind {gate.get('id')}")

    def _required_id_edges(self, key: str, raw_ids: Any, preferred_map: str = "") -> None:
        for raw_id in _list(raw_ids):
            if raw_id:
                self.graph.add_edge(key, self.graph.resolve(str(raw_id), preferred_map), "requires", hard=True)

    def _add_purchase_edges(self) -> None:
        reward_nodes = [node for node in self.graph.nodes.values() if int(node.attrs.get("wallet_reward", 0)) > 0]
        purchases = [*self.contract["session_upgrades"], *self.contract["durable_purchases"]]
        for item in purchases:
            key = self.graph.resolve(item["id"])
            node = self.graph.nodes[key]
            purchase_map = str(item.get("purchase_map_id", self.contract["canonical_start"]["map_id"]))
            purchase_entry = str(item.get("purchase_entry_id", self.contract["canonical_start"]["entry_id"]))
            self.graph.add_edge(key, f"map:{purchase_map}", "requires", hard=True, note="purchase location")
            self.graph.add_edge(key, self.graph.resolve(purchase_entry, purchase_map), "requires", hard=True, note="purchase entry")
            lead_source_id = str(item.get("required_lead_source_id", ""))
            if lead_source_id:
                self.graph.add_edge(key, self.graph.resolve(lead_source_id), "requires", hard=True, note="purchase lead")
            configured = _list(item.get("funding_source_ids"))
            funding_keys = [self.graph.resolve(str(raw_id)) for raw_id in configured] if configured else [source.key for source in reward_nodes]
            node.attrs["funding_keys"] = funding_keys
            for source_key in funding_keys:
                source = self.graph.nodes.get(source_key)
                amount = int(source.attrs.get("wallet_reward", 0)) if source is not None else 0
                self.graph.add_edge(source_key, key, "funds", quantity=amount)
            for target_id in _list(item.get("unlocks_target_ids")):
                self.graph.add_edge(key, self.graph.resolve(str(target_id)), "unlocks")

    def _mark_mandatory_chain(self) -> None:
        active_chains = (CANONICAL_CHAIN_IDS, *(chain for trigger, chain in CANONICAL_EXTENSION_CHAINS if self.graph.resolve(trigger) in self.graph.nodes))
        for raw_id in (item for chain in active_chains for item in chain):
            self._mark(self.graph.resolve(raw_id))
        for item in [*self.contract["session_upgrades"], *self.contract["durable_capabilities"], *self.contract["durable_purchases"]]:
            if item.get("mandatory") is True:
                self._mark(self.graph.resolve(item["id"]))
                for raw_id in _list(item.get("funding_source_ids")) + _list(item.get("unlocks_target_ids")):
                    self._mark(self.graph.resolve(str(raw_id)))
        for map_data in self.maps:
            map_id = str(map_data.get("id", ""))
            primary = str(map_data.get("primary_route_objective_id", ""))
            if primary:
                self._mark(self.graph.resolve(primary, map_id))
            for collection in ("next_dive_objective_prompts",):
                for item in _items(map_data, collection):
                    self._mark(self.graph.resolve(str(item.get("id", "")), map_id))
        changed = True
        while changed:
            changed = False
            for node in list(self.graph.nodes.values()):
                if not node.mandatory:
                    continue
                for edge in self.graph.requirements(node.key):
                    if edge.target in self.graph.nodes and not self.graph.nodes[edge.target].mandatory:
                        self.graph.nodes[edge.target].mandatory = True
                        changed = True
                if node.kind in {"project", "prompt", "regional_journey", "investigation", "survey", "upgrade", "capability"}:
                    for edge in self.graph.outgoing(node.key):
                        if edge.relation in {"unlocks", "targets"} and edge.target in self.graph.nodes and not self.graph.nodes[edge.target].mandatory:
                            self.graph.nodes[edge.target].mandatory = True
                            changed = True
                if node.kind == "material":
                    for edge in self.graph.incoming(node.key, "rewards"):
                        if edge.source in self.graph.nodes and not self.graph.nodes[edge.source].mandatory:
                            self.graph.nodes[edge.source].mandatory = True
                            changed = True
                if node.kind == "map" and node.attrs.get("start") is not True:
                    for edge in self.graph.incoming(node.key, "travels_to"):
                        source = self.graph.nodes.get(edge.source)
                        if source is not None and source.attrs.get("connector_direction") == "forward" and not source.mandatory:
                            source.mandatory = True
                            changed = True

    def _mark(self, key: str) -> None:
        if key in self.graph.nodes:
            self.graph.nodes[key].mandatory = True


def build_progression_graph(maps: list[dict[str, Any]], contract: dict[str, Any]) -> ProgressionGraph:
    return ProgressionGraphBuilder(maps, contract).build()

"""Add proposed creature-source nodes and dependencies to the progression graph."""

from __future__ import annotations

from typing import Any


COLLECTION_KINDS = {
    "creature_rescues": "creature_rescue",
    "companion_contexts": "companion_context",
    "creature_memory_opportunities": "creature_memory",
    "creature_adaptation_payoffs": "creature_payoff",
}


def _items(payload: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _ids(value: Any) -> list[str]:
    return [str(item) for item in value] if isinstance(value, list) else []


def _display(value: str) -> str:
    return value.replace("_", " ").title()


def _key(kind: str, map_id: str, item_id: str) -> str:
    return f"{kind}:{map_id}/{item_id}"


def add_creature_nodes(graph: Any, map_data: dict[str, Any], node_type: Any) -> None:
    map_id = str(map_data.get("id", ""))
    for collection, kind in COLLECTION_KINDS.items():
        for item in _items(map_data, collection):
            item_id = str(item.get("id", ""))
            attrs = {**item, "collection": collection, "implementation_status": "proposed"}
            mandatory = kind == "creature_rescue" or item.get("context_kind") == "mounted_route_review"
            graph.add_node(node_type(
                _key(kind, map_id, item_id),
                f"[proposed] {_display(item_id)}",
                kind,
                map_id,
                mandatory=mandatory,
                attrs=attrs,
            ), item_id)
            if kind == "creature_rescue":
                individual_id = str(item.get("individual_id", ""))
                graph.add_node(node_type(
                    f"creature:{individual_id}",
                    f"[proposed] {_display(individual_id)}",
                    "creature",
                    attrs={"implementation_status": "proposed", "species_id": item.get("species_id")},
                ), individual_id)
            if kind == "creature_memory":
                memory_id = str(item.get("memory_id", ""))
                graph.add_node(node_type(
                    f"memory:{memory_id}",
                    f"[proposed] {_display(memory_id)}",
                    "creature_memory_state",
                    attrs={"implementation_status": "proposed"},
                ), memory_id)
            if kind in {"creature_memory", "creature_payoff"}:
                adaptation_ids = _ids(item.get("adaptation_ids"))
                if item.get("adaptation_id"):
                    adaptation_ids.append(str(item["adaptation_id"]))
                for adaptation_id in adaptation_ids:
                    graph.add_node(node_type(
                        f"adaptation:{adaptation_id}",
                        f"[proposed] {_display(adaptation_id)}",
                        "creature_adaptation",
                        attrs={"implementation_status": "proposed"},
                    ), adaptation_id)


def _requires(graph: Any, source: str, raw_id: str, preferred_map: str = "", note: str = "") -> None:
    if raw_id:
        graph.add_edge(source, graph.resolve(raw_id, preferred_map), "requires", hard=True, note=note)


def add_creature_edges(graph: Any, map_data: dict[str, Any]) -> None:
    map_id = str(map_data.get("id", ""))
    map_key = f"map:{map_id}"
    rescue_by_individual = {
        str(item.get("individual_id", "")): item
        for item in _items(map_data, "creature_rescues")
    }
    for collection, kind in COLLECTION_KINDS.items():
        for item in _items(map_data, collection):
            item_id = str(item.get("id", ""))
            key = _key(kind, map_id, item_id)
            graph.add_edge(map_key, key, "contains")
            graph.add_edge(key, map_key, "requires", hard=True, note="source map")
            if kind == "creature_rescue":
                _requires(graph, key, str(item.get("required_capability_id", "")), note="physical rescue")
                _requires(graph, key, str(item.get("commit_entry_id", "")), map_id, "canonical boat")
                individual = graph.resolve(str(item.get("individual_id", "")))
                graph.add_edge(individual, key, "requires", hard=True, note="committed rescue")
                graph.add_edge(key, individual, "unlocks")
                continue
            individual_id = str(item.get("individual_id", ""))
            if not individual_id and len(rescue_by_individual) == 1:
                individual_id = next(iter(rescue_by_individual))
            _requires(graph, key, individual_id, note="active companion")
            for access_id in _ids(item.get("required_access_ids")):
                _requires(graph, key, access_id, note="equipment authority")
            _requires(graph, key, str(item.get("required_adaptation_id", "")), note="selected adaptation")
            target_id = str(item.get("target_id", ""))
            if target_id:
                graph.add_edge(key, graph.resolve(target_id, map_id), "targets")
            if kind == "creature_memory":
                _requires(graph, key, target_id, map_id, "meaningful shared event")
                memory = graph.resolve(str(item.get("memory_id", "")))
                graph.add_edge(memory, key, "requires", hard=True, note="earned memory")
                graph.add_edge(key, memory, "unlocks")
                for adaptation_id in _ids(item.get("adaptation_ids")):
                    adaptation = graph.resolve(adaptation_id)
                    graph.add_edge(adaptation, memory, "requires", hard=True, note="committed memory")
                    graph.add_edge(key, adaptation, "unlocks")
            elif kind == "creature_payoff":
                _requires(graph, key, target_id, map_id, "adaptation payoff context")
                _requires(graph, key, str(item.get("adaptation_id", "")), note="adaptation payoff")
                for field in ("independent_context_id", "mounted_context_id"):
                    context_id = str(item.get(field, ""))
                    if context_id:
                        graph.add_edge(key, graph.resolve(context_id, map_id), "reviews")

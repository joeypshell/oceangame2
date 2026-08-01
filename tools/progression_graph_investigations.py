#!/usr/bin/env python3
"""Add focused wreck-network investigation nodes and dependency edges."""

from __future__ import annotations

from typing import Any


def add_wreck_network_investigations(graph: Any, map_data: dict[str, Any], node_type: Any) -> None:
    map_id = str(map_data.get("id", ""))
    investigations = map_data.get("wreck_network_investigations", [])
    if not isinstance(investigations, list):
        return
    for item in investigations:
        if not isinstance(item, dict):
            continue
        investigation_id = str(item.get("id", ""))
        key = f"investigation:{map_id}/{investigation_id}"
        graph.add_node(
            node_type(
                key,
                str(item.get("analysis_label", investigation_id.replace("_", " ").title())),
                "investigation",
                map_id,
                mandatory=True,
                attrs={**item, "collection": "wreck_network_investigations"},
            ),
            investigation_id,
        )
        discovery_id = str(item.get("analysis_discovery_id", ""))
        discovery_key = f"discovery:{discovery_id}"
        graph.add_node(
            node_type(discovery_key, discovery_id.replace("_", " ").title(), "discovery", map_id),
            discovery_id,
        )
        graph.add_edge(f"map:{map_id}", key, "contains")
        graph.add_edge(key, f"map:{map_id}", "requires", hard=True)
        fragments = item.get("fragment_discovery_ids", [])
        required_ids = [item.get("required_discovery_id"), *(fragments if isinstance(fragments, list) else [])]
        for raw_id in required_ids:
            if raw_id:
                graph.add_edge(key, graph.resolve(str(raw_id), map_id), "requires", hard=True)
        graph.add_edge(discovery_key, key, "requires", hard=True, note="explicit night analysis")
        graph.add_edge(key, discovery_key, "unlocks")

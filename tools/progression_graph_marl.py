"""LE07 event, boat, night, and action dependencies; not runtime grants."""

from __future__ import annotations

from typing import Any

from living_expedition_07_contract import (
    ACTION_ID, ADAPTATION_ID, CONTEXT_ID, INDIVIDUAL_ID, MEMORY_ID,
    OPPORTUNITY_ID, REFUGE_ID, items, uses_living_expedition_07,
)

NIGHT_ID = "root_claws_night"


def add_marl_growth_nodes(graph: Any, payload: dict, node_type: Any) -> None:
    if not uses_living_expedition_07(payload):
        return
    map_id = str(payload.get("id", ""))
    for kind, item_id, label in (
        ("companion_night_adaptation", NIGHT_ID, "Deliberately Consolidate Root Claws At Night"),
        ("companion_action", ACTION_ID, "Ground Pin On Next Sortie"),
    ):
        graph.add_node(node_type(
            f"{kind}:{map_id}/{item_id}", f"[proposed] {label}", kind, map_id,
            attrs={"implementation_status": "proposed", "individual_id": INDIVIDUAL_ID},
        ), item_id)


def add_marl_growth_edges(graph: Any, payload: dict) -> None:
    if not uses_living_expedition_07(payload):
        return
    map_id = str(payload.get("id", ""))

    def requires(source_id: str, target_id: str, note: str) -> None:
        graph.add_edge(graph.resolve(source_id, map_id), graph.resolve(target_id, map_id),
                       "requires", hard=True, note=note)

    opportunity = next((item for item in items(payload, "creature_memory_opportunities")
                        if item.get("id") == OPPORTUNITY_ID), {})
    requires(REFUGE_ID, f"{INDIVIDUAL_ID}_active_selection", "selected Marl uses base Excavate")
    requires(OPPORTUNITY_ID, f"{INDIVIDUAL_ID}_active_selection", "same active individual")
    requires(OPPORTUNITY_ID, str(opportunity.get("hostile_id", "")), "live warning/lunge during refuge event")
    requires(MEMORY_ID, str(opportunity.get("commit_entry_id", "")), "exact-once canonical boat commitment")
    requires(NIGHT_ID, MEMORY_ID, "secured memory, deliberate night choice or defer")
    requires(ADAPTATION_ID, NIGHT_ID, "single selected adaptation slot")
    requires(ACTION_ID, ADAPTATION_ID, "next-sortie learned action")
    requires(CONTEXT_ID, ACTION_ID, "independent grounded hold; no equipment unlock")

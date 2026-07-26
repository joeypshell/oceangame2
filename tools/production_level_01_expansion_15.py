#!/usr/bin/env python3
"""Source-owned expedition planning metadata for Expansion 15."""

from __future__ import annotations

from typing import Any


EXPEDITION_LEADS = (
    (
        "regional_journeys",
        "upper_left_wreck_relay_route",
        {
            "lead_type": "regional_journey",
            "label": "Northwest Wreck Relay",
            "summary": "Use the Current Stabilizer to survey the transmitting wreck",
            "active_guidance": "Plan: Follow the archive signal northwest",
            "order": 10,
        },
    ),
    (
        "daily_conditions",
        "southwest_jellyfish_bloom",
        {
            "lead_type": "daily_condition",
            "label": "Southwest Jellyfish Bloom",
            "summary": "Risk the migration lane for an optional conductive-coil trace",
            "active_guidance": "Plan: Search the southwest migration lane",
            "order": 20,
        },
    ),
)


def author_expedition_leads(map_data: dict[str, Any]) -> dict[str, Any]:
    """Attach the two approved leads to their existing source records."""
    for collection, record_id, metadata in EXPEDITION_LEADS:
        records = map_data.get(collection)
        if not isinstance(records, list):
            raise ValueError(f"Expected {collection} to be a list.")
        matches = [
            record
            for record in records
            if isinstance(record, dict) and record.get("id") == record_id
        ]
        if len(matches) != 1:
            raise ValueError(
                f"Expected exactly one {collection} record {record_id!r}; "
                f"found {len(matches)}."
            )
        if "expedition_lead" in matches[0]:
            raise ValueError(
                f"{collection} record {record_id!r} already owns expedition_lead metadata."
            )
        matches[0]["expedition_lead"] = dict(metadata)
    return map_data

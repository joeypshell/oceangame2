"""Stable identifiers used to audit the canonical progression chain."""


CANONICAL_CHAIN_IDS = (
    "propulsion_fins_blueprint",
    "propulsion_fins",
    "survey_scanner_blueprint",
    "survey_scanner_project",
    "survey_scanner_1",
    "lower_right_anomaly_discovery",
    "salvage_cutter_project",
    "shock_prod_project",
    "shock_prod",
    "salvage_deep_right_cache",
    "eel_electrocyte",
    "shock_prod_capacitor_project",
)

CANONICAL_EXTENSION_CHAINS = (
    (
        "upper_left_wreck_relay_route",
        (
            "southeast_wreck_archive_discovery",
            "current_stabilizer_project",
            "current_stabilizer",
            "upper_left_wreck_relay_current",
            "upper_left_wreck_relay_survey",
            "upper_left_wreck_relay_discovery",
        ),
    ),
    (
        "far_west_deeper_wreck_route",
        (
            "upper_left_wreck_relay_discovery",
            "closed_circuit_rebreather_project",
            "closed_circuit_rebreather",
            "far_west_deeper_wreck_route",
            "far_west_deeper_wreck_survey",
            "far_west_deeper_wreck_discovery",
        ),
    ),
)

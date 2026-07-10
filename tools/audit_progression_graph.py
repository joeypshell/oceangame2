#!/usr/bin/env python3
"""Audit source-derived OceanGame progression and refresh deterministic review artifacts."""

from __future__ import annotations

import argparse

from progression_audit import audit_graph, render_review_doc, review_doc_failure, write_review_doc
from progression_contract import generated_contract_failure, load_contract, write_generated_contract
from progression_graph import build_progression_graph, load_production_maps


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Refresh generated runtime constants and review Markdown after a passing audit.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        contract = load_contract()
        graph = build_progression_graph(load_production_maps(), contract)
    except (OSError, ValueError) as exc:
        print(f"Progression audit FAIL:\n- {exc}")
        return 1
    result = audit_graph(graph)
    if result.failures:
        print("Progression audit FAIL:")
        for failure in result.failures:
            print(f"- {failure}")
        return 1

    review_doc = render_review_doc(graph, result)
    if args.write:
        write_generated_contract(contract)
        write_review_doc(review_doc)
    else:
        artifact_failures = [failure for failure in (generated_contract_failure(contract), review_doc_failure(review_doc)) if failure]
        if artifact_failures:
            print("Progression audit FAIL:")
            for failure in artifact_failures:
                print(f"- {failure}")
            return 1

    mandatory_count = sum(node.mandatory for node in graph.nodes.values())
    shock_stage = result.stages[graph.resolve("shock_prod")]
    cache_stage = result.stages[graph.resolve("salvage_deep_right_cache")]
    print(
        "Progression audit PASS: "
        f"nodes={len(graph.nodes)} edges={len(graph.edges)} mandatory={mandatory_count} "
        f"stages={max(result.stages.values()) + 1} shock_prod={shock_stage} guarded_cache={cache_stage} "
        f"soft_annotations={len(result.soft_annotations)}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

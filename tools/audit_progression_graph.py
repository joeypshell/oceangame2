#!/usr/bin/env python3
"""Audit source-derived OceanGame progression and refresh deterministic review artifacts."""

from __future__ import annotations

import argparse

from progression_audit import audit_graph, render_review_doc, review_doc_failure, write_review_doc
from progression_audit_views import build_view_graph, load_audit_views
from progression_contract import generated_contract_failure, load_contract, write_generated_contract


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Refresh generated runtime constants and review Markdown after a passing audit.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        contract = load_contract()
        views = load_audit_views()
        view_results = []
        for view in views:
            graph = build_view_graph(view, contract)
            view_results.append((view, graph, audit_graph(graph)))
    except (OSError, ValueError) as exc:
        print(f"Progression audit FAIL:\n- {exc}")
        return 1
    failures = [
        f"[{view.id}] {failure}"
        for view, _graph, result in view_results
        for failure in result.failures
    ]
    if failures:
        print("Progression audit FAIL:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    detailed = next(item for item in view_results if item[0].detailed_review)
    view, graph, result = detailed
    summary_lines = [
        "| View | Sources | Status | Graph |",
        "| --- | --- | --- | --- |",
        *(
            f"| `{item.id}` ({item.label}) | {item.source_paths} | **PASS** | "
            f"{len(item_graph.nodes)} nodes / {len(item_graph.edges)} edges |"
            for item, item_graph, _item_result in view_results
        ),
    ]
    review_doc = render_review_doc(
        graph,
        result,
        source_description=(
            "`config/progression_contract.json`, `config/progression_audit_views.json`, "
            "and the promoted `maps/production_level_01.greybox.json` canonical view"
        ),
        audited_view_lines=summary_lines,
    )
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
        f"views={len(view_results)} canonical={view.id} "
        f"nodes={len(graph.nodes)} edges={len(graph.edges)} mandatory={mandatory_count} "
        f"stages={max(result.stages.values()) + 1} shock_prod={shock_stage} guarded_cache={cache_stage} "
        f"soft_annotations={len(result.soft_annotations)}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

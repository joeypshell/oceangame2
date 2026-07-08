# Agent Skills

Project-local Codex skills live under `.codex/skills/`. They are source-controlled workflow instructions for future agent sessions.

## Repo Drift Evaluation

Skill path:

```text
.codex/skills/repo-drift-evaluation/SKILL.md
```

Use `$repo-drift-evaluation` when the task is to evaluate project direction rather than implement a feature.

Good triggers:

- direction audits
- drift checks after several issue batches
- stale documentation discovery
- GitHub issue/backlog mismatch checks
- validation-gap review
- source-of-truth workflow review
- AGENTS.md alignment review

Default behavior is evaluation-only. The skill should report evidence, drift findings, documentation updates needed, issue/backlog recommendations, validation results, and one next recommended action. It should not edit files, create issues, close issues, accept baselines, or change map sources unless the user explicitly asks for that follow-up work.

## Issue Resolution

Skill path:

```text
.codex/skills/resolve-github-issues/SKILL.md
```

Use `$resolve-github-issues` when the user asks to work through open GitHub issues. It should resolve one selected issue at a time, validate, commit, push, comment, and close, while leaving intentionally deferred issues such as #52/#53 open unless the selected goal changes.

## Drift Batch Resolve

Skill path:

```text
.codex/skills/drift-batch-resolve/SKILL.md
```

Use `$drift-batch-resolve` when the user wants the full maintenance loop: audit drift, ensure a scoped issue batch exists, then resolve active non-deferred GitHub issues.

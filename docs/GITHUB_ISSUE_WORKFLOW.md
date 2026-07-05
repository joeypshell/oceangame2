# GitHub Issue Workflow

Use GitHub Issues as the durable work queue for this project. Chat planning is useful, but actionable work should be captured in issues so future Codex sessions can continue without reconstructing context.

## When To Create Issues

Create or update issues when:

- a planning discussion produces concrete implementation steps
- a task is large enough to split across future sessions
- a visual or map decision needs validation later
- a bug or workflow gap is found while working
- a follow-up is useful but outside the current task

Do not create issues for vague epics, duplicate work, intentionally deferred ideas, or notes that belong in docs instead.

## Issue Shape

Each issue should include:

- summary or user story
- acceptance criteria
- relevant docs and code areas
- dependencies or blockers
- implementation notes
- verification steps

Keep issues small enough for one focused agent pass.

## Planning-To-Issue Rule

When the project identifies a sequence like:

1. build Godot greybox
2. validate map accessibility
3. generate terrain tiles
4. render terrain art from the greybox
5. capture visual baselines

create separate issues for the meaningful work items. Link the issue to the relevant docs, source maps, reference images, and validation tools.

## Map And Visual Issues

Map issues must mention:

- source map path
- preview path
- accessibility validator command
- expected reachable gameplay areas
- whether any unreachable areas are intentionally decorative/background-only

Visual issues must mention:

- art bible path
- reference standard path
- target assets
- untouched assets
- visual baseline expectations
- whether the change is a concept, production asset, or in-engine placement task

## Close-Out

Before closing an issue:

- confirm the acceptance criteria were met
- run the relevant verification steps
- push the commit
- comment with the commit hash and verification result
- leave follow-up work as separate issues instead of expanding the closed issue

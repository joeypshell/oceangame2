# Project Posture

This is an AI-assisted Godot game project. Treat this file as the living operating guide for Codex and other coding agents working in this repository.

Keep guidance practical and compact. Add rules only when they prevent repeated mistakes or preserve workflow future agents need.

## Repository Shape

- Source: Godot 4.x project using GDScript. Scenes should live in `scenes/`; scripts should live in `scripts/`.
- Current purpose: use the finished diver-expedition foundation to build OceanGame as a side-view underwater expedition-raising game centered on one bonded active companion, meaningful shared memories, and deliberate night adaptation.
- Runtime/config, once the Godot project exists: `project.godot`, `icon.svg`, Godot scenes, and GDScript files.
- GitHub Actions: `.github/workflows/godot-web-export.yml`.
- Planning docs: `docs/`; active product direction starts at `docs/planning/OCEANGAME_LIVING_EXPEDITION_ROADMAP.md`, while `OCEANGAME_PHASE_2_ROADMAP.md` remains the historical foundation roadmap.
- Project-local Codex skills: `.codex/skills/`.
- Generated files not to commit: `.godot/`, `.import/`, `*.import`, `builds/`, `exports/`, local editor state, secrets, and platform export artifacts.
- Godot 4.4+ `.uid` sidecars are source state, not cache. Commit them with their matching scripts/resources and move or delete them alongside those files.

## Development Workflow

- Read the issue, linked docs, and nearby code before editing.
- Prefer existing project patterns over new abstractions.
- Keep changes scoped to the issue.
- For gameplay/backlog work, apply the Living Expedition north-star filter: the change should create creature attachment, meaningful shared experience, expressive adaptation, ecological curiosity, pressure, remembered-place progress, meaningful route choice, or a reason to begin another day; otherwise treat it as foundation tooling/polish and keep it proportional.
- Keep current-runtime truth separate from target-game plans. Do not claim proposed creature, memory, adaptation, stable, or habitat systems exist before their implementation issues merge.
- Preserve the progression boundary: diver equipment owns predictable hard geographic access; companions change what the pair can accomplish within reachable regions and must not become unexplained gate keys.
- For map/terrain work, do not visually interpret screenshots or hand-tune Godot polygons as topology fixes. Update the machine-readable source map or converter, regenerate runtime geometry and previews, then use Godot/Playwright screenshots only as final rendering confirmation.
- For map/topology work, validate player accessibility from the spawn. All intended open areas, salvage, hazards, and return/extraction zones must be reachable unless explicitly marked decorative/background-only.
- If new work appears, create or request a follow-up issue instead of expanding the ticket.
- Do not revert unrelated user changes.
- Do not commit generated files, local caches, secrets, or build output.

## Agent-Friendly File Lengths

- Treat 500 lines as the default target and growth guard for human-authored source, docs, and config. New files should stay at or below it unless a documented exception is justified.
- The target is not a Godot runtime or architectural requirement. Do not split a file solely to satisfy the number when that would increase coupling, fragment mutable-state ownership, obscure node/signal lifecycle, or create pass-through wrappers.
- Extract only at cohesive responsibility boundaries. Keep one clear owner for mutable state, preserve public APIs and lifecycle ordering, and run the relevant behavior/parity checks after a split.
- Oversized files may remain documented cohesive-owner exceptions when that is safer than further decomposition. Avoid unnecessary growth and re-evaluate the exception when responsibilities genuinely separate.
- The file-length audit must report actionable temporary debt, cohesive-owner exceptions, and generated/data exceptions separately.

## Visual Workflow

- Treat visuals as a controlled production pipeline, not one-off scene generation.
- Lock camera, tile size, palette direction, and map format before creating final art.
- The map source of truth must be data: Godot `TileMapLayer`, LDtk, Tiled, JSON, or another machine-readable format.
- Approved assets are edited individually or replaced with named variants. Do not regenerate the whole scene to fix one asset.
- Keep baseline screenshots under `visual_baselines/` once visual implementation starts.
- Any visual revision should state the target issue, affected assets, untouched assets, and expected screenshot difference.

## GitHub Issue Workflow

Use GitHub Issues for meaningful feature, bug, workflow, tooling, and demo work.

Do not implement issue work directly on `main`. Use a focused `codex/<issue>-<slug>` branch, open a PR, wait for applicable checks, and consider the issue resolved only after merge. Comment with the merge commit and verification result.

If the primary checkout is dirty or stale, leave it untouched and use one clean dedicated resolver worktree based on `origin/main`. Reuse that worktree across a sequential issue batch instead of creating one worktree per issue, and clean only the branches/worktrees created by the current run.

Freeze each resolver run to one explicit issue-number set or committed milestone. Do not sweep the general open queue, refill immediately after closeout, or pre-batch later directional milestones.

Maintain a rolling backlog of about 10 open actionable issues. When the queue drops well below that target, expand the roadmap or planning docs first, then create scoped issues from that plan. Do not pad the queue with vague epics, duplicate work, or intentionally deferred ideas.

Evaluate that backlog target at audit/planning boundaries. A resolver may finish with no active batch after closing one milestone; the next audit selects and batches the next direction.

When a planning conversation identifies concrete next steps, create GitHub issues for them before or alongside implementation. Each issue should be independently actionable by a future agent. Prefer several small issues over one broad issue when the work spans map data, Godot implementation, art generation, validation, and documentation.

If an issue is implemented immediately, still record the issue and close it after its PR merges, with the merge commit and verification result. If work is deferred, leave the issue open with dependencies and acceptance criteria.

Issues should include:

- summary or user story
- acceptance criteria
- relevant docs and code areas
- dependencies or blockers
- implementation notes
- verification steps

Record durable decisions, blockers, commit hashes, and verification results in issue comments.

Before a gameplay milestone receives a final player-experience GO/HOLD, provide a short local playtest path tied to its exit question. Automated validation may support a technical GO, but it does not prove fun, pacing, or replay motivation without user review unless the user explicitly requests an autonomous technical closeout.

Detailed workflow: `docs/GITHUB_ISSUE_WORKFLOW.md`

## Parallel Agent Workflow

- Do not run multiple Codex agents in the same checkout.
- Use one dedicated Git worktree per active agent and reuse it across sequential issues; create a fresh feature branch for each claimed issue.
- Tie each branch to one GitHub issue and claim it with a comment naming the branch and worktree path.
- Avoid overlapping edits to `scripts/main/main.gd`, `docs/current/PROJECT_CONTEXT.md`, `tools/create_production_slice_map.py`, generated map JSON, and visual baselines unless explicitly coordinated.
- Detailed workflow: `docs/current/PARALLEL_CODEX_WORKFLOW.md`

## Current Planned Structure

These paths are part of the intended project shape and should be created when the corresponding implementation work begins:

- Current-state docs: `docs/current/`
- Current architecture: `docs/current/ARCHITECTURE.md`
- Planning docs: `docs/planning/`
- Archived plans/notes: `docs/archive/`
- Agent workflow docs: `docs/GITHUB_ISSUE_WORKFLOW.md`, `docs/AGENT_HANDOFF_TEMPLATE.md`
- GitHub Actions: `.github/workflows/godot-web-export.yml`; add `.github/workflows/godot-smoke.yml` when the smoke CI issue is implemented.
- MCP tooling: `.mcp/oceangame-context-server.mjs`, `.mcp/oceangame-context.example.json`, `docs/current/TOOLING.md`

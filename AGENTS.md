# Project Posture

This is an AI-assisted Godot game project. Treat this file as the living operating guide for Codex and other coding agents working in this repository.

Keep guidance practical and compact. Add rules only when they prevent repeated mistakes or preserve workflow future agents need.

## Repository Shape

- Source: Godot 4.x project using GDScript. Scenes should live in `scenes/`; scripts should live in `scripts/`.
- Current purpose: visual-first salvage prototype proving a stable OceanGame-style art, map, and asset workflow.
- Runtime/config, once the Godot project exists: `project.godot`, `icon.svg`, Godot scenes, and GDScript files.
- Planning docs: `docs/`.
- Project-local Codex skills: `.codex/skills/`.
- Generated files not to commit: `.godot/`, `.import/`, `*.import`, `builds/`, `exports/`, local editor state, secrets, and platform export artifacts.

## Development Workflow

- Read the issue, linked docs, and nearby code before editing.
- Prefer existing project patterns over new abstractions.
- Keep changes scoped to the issue.
- For gameplay/backlog work, apply the roadmap north-star filter: the change should create curiosity, pressure, payoff, remembered-place progress, meaningful route choice, or a reason to try another expedition; otherwise treat it as tooling/polish and keep it proportional.
- For map/terrain work, do not visually interpret screenshots or hand-tune Godot polygons as topology fixes. Update the machine-readable source map or converter, regenerate runtime geometry and previews, then use Godot/Playwright screenshots only as final rendering confirmation.
- For map/topology work, validate player accessibility from the spawn. All intended open areas, salvage, hazards, and return/extraction zones must be reachable unless explicitly marked decorative/background-only.
- If new work appears, create or request a follow-up issue instead of expanding the ticket.
- Do not revert unrelated user changes.
- Do not commit generated files, local caches, secrets, or build output.

## Visual Workflow

- Treat visuals as a controlled production pipeline, not one-off scene generation.
- Lock camera, tile size, palette direction, and map format before creating final art.
- The map source of truth must be data: Godot `TileMapLayer`, LDtk, Tiled, JSON, or another machine-readable format.
- Approved assets are edited individually or replaced with named variants. Do not regenerate the whole scene to fix one asset.
- Keep baseline screenshots under `visual_baselines/` once visual implementation starts.
- Any visual revision should state the target issue, affected assets, untouched assets, and expected screenshot difference.

## GitHub Issue Workflow

Use GitHub Issues for meaningful feature, bug, workflow, tooling, and demo work.

Maintain a rolling backlog of about 10 open actionable issues. When the queue drops well below that target, expand the roadmap or planning docs first, then create scoped issues from that plan. Do not pad the queue with vague epics, duplicate work, or intentionally deferred ideas.

When a planning conversation identifies concrete next steps, create GitHub issues for them before or alongside implementation. Each issue should be independently actionable by a future agent. Prefer several small issues over one broad issue when the work spans map data, Godot implementation, art generation, validation, and documentation.

If an issue is implemented immediately, still record the issue and close it with the commit hash and verification result. If work is deferred, leave the issue open with dependencies and acceptance criteria.

Issues should include:

- summary or user story
- acceptance criteria
- relevant docs and code areas
- dependencies or blockers
- implementation notes
- verification steps

Record durable decisions, blockers, commit hashes, and verification results in issue comments.

Detailed workflow: `docs/GITHUB_ISSUE_WORKFLOW.md`

## Current Planned Structure

These paths are part of the intended project shape and should be created when the corresponding implementation work begins:

- Current-state docs: `docs/current/`
- Current architecture: `docs/current/ARCHITECTURE.md`
- Planning docs: `docs/planning/`
- Archived plans/notes: `docs/archive/`
- Agent workflow docs: `docs/GITHUB_ISSUE_WORKFLOW.md`, `docs/AGENT_HANDOFF_TEMPLATE.md`
- GitHub Actions: `.github/workflows/godot-smoke.yml`
- MCP tooling: `.mcp/oceangame-context-server.mjs`, `.mcp/oceangame-context.example.json`, `docs/current/TOOLING.md`

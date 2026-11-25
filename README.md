# agent-swarm

A Claude Code skill that decides how big work should run, then runs it with a team built for the job. You stop managing sessions and saying "use a subagent".

For each task Claude picks one of four tiers:

0. do it inline;
1. spawn a few subagents;
2. fan out a Workflow swarm (plan, build, adversarial verify, fix loop, completeness critic, integration test);
3. propose a separate session, only for a deliverable that stands on its own.

## Swarm types (team packs)

A **pack** is a team of roles for one kind of work. Each role has a base agent type, a model tier, an optional verifier role and a short set of rules. Roles that write or build are checked by another role.

| Pack | For | Roles |
|---|---|---|
| `general` | anything (the fallback) | researcher, planner, builder, writer, data-analyst, reviewer |
| `gamedev` | Unity / Unreal / Godot / web games | engine-builder, playtester, art-maker, asset-3d, art-director, level-designer, store-writer, release-gate |
| `business` | running a small business | ops-planner, market-researcher, competitor-analyst, financial-analyst, marketing-writer, sales-drafter, support-triager, sop-writer, kpi-analyst, meeting-summarizer, fact-checker, brand-reviewer |
| `software` | apps, APIs, libraries | frontend-builder, backend-builder, test-writer, code-reviewer, security-reviewer, docs-writer, release-gate |
| `content` | video, social, blog, newsletters | scriptwriter, social-drafter, seo-writer, trend-researcher, content-planner, editor |
| `research` | sourced reports and comparisons | source-hunter, deep-reader, synthesizer, fact-checker |

`gamedev` also ships a quality bar (`packs/gamedev-quality.md`): no stand-in block characters, and correct motion from the first build.

**Which pack runs**, first match wins: `--pack <name>` in the task, then `.claude/swarm.json` in the project, then `~/.claude/swarm.json`, then the pack whose trigger words best match the task, then `general`.

### Pack commands

```
/swarm packs                                   list packs and show the active one
/swarm use business                            set the pack for this project
/swarm use gamedev --global                    set your default pack
/swarm new bakery "run my bakery: orders, suppliers, staff rota, Instagram"
/swarm new bakery "..." --project --agents     save in the project, and also write agent files
/swarm edit bakery                             change a pack
/swarm export bakery                           print it to share (checks for personal data first)
```

**Custom packs** go in `~/.claude/swarm-packs/<name>.md` (yours) or `<project>/.claude/swarm-packs/<name>.md` (committed with the project). A pack can `extends:` a built-in one and override only the roles it changes, add a `## Context` section with project paths and facts, and point `quality:` at its own quality bar. The format is in [`skills/swarm/packs/README.md`](skills/swarm/packs/README.md).

```markdown
---
name: bakery
description: Runs a small bakery.
triggers: [orders, suppliers, rota, bakery, menu]
extends: business
---

## Roles

### order-clerk
- type: operator
- model: cheap
- verifier: reviewer
- rules:
  - Draft supplier orders as files; never place them.

## Guardrails
- Never send, buy or post without the owner's OK.
```

## Agents and templates

- Six base agents with trimmed tool lists: `swarm-builder`, `swarm-scout` (read-only), `swarm-verifier` (read-only), `swarm-researcher`, `swarm-writer` and `swarm-operator`. Pack roles run on these with their rules in the brief, so no extra agent files are needed. `/swarm new ... --agents` writes dedicated agent files when you want them (they register on the next session start).
- Workflow templates in `skills/swarm/templates/`, all pack-aware through `args.roles`:
  - `swarm-build.js`: features with tasks ordered by dependency, a verifier per task (the role's paired verifier), and optional worktree isolation.
  - `swarm-sweep.js`: one instruction over hundreds of items (`pack_role`, `verify_pack_role`).
  - `swarm-review.js`: lens finders and a voting verify step, looping until no new findings (`finder_role`, `verifier_role`).

## Cost

An untrimmed agent starts with about 65k tokens of base context, so the number of agents is the main cost. The base agents carry a `tools:` allowlist to cut that down. Every template takes a `cost` profile and reports `agents_used`.

| Profile | Models (cheap / standard / strong) | Agent cap | Notes |
|---|---|---|---|
| `lean` (default) | haiku / sonnet / session model | 60 (review 40) | build: at most 8 tasks, no critic, light tasks self-checked; review: 3 lenses, 2 rounds, batched skeptics; sweep: verifies 1 chunk in 3 |
| `balanced` | haiku / session / session | 200 (review 150) | critic on, every task verified, 3 votes |
| `max` | session model for all | 1000 | everything on |

Also: plan lint before any builder runs, learnings saved to `.claude/swarm-learnings.jsonl` for the next run, clean stops at the agent cap or budget reserve, and root-cause merging of review findings.

## Safety

Agents never deploy, post, send, buy, enter credentials, force-push or permanently delete anything. A task that needs one of those stops and asks you. Packs can only add guardrails, never remove these.

## Limits

- About 16 agents run at once; one Workflow run can use up to 1000. Split bigger jobs across runs.
- Worktree isolation needs a git repo.
- Workflow swarms (tier 2) need the Workflow tool, and the app's *workflow size* setting caps how big they get.

## Install

```
/plugin marketplace add JaStaxks/agent-swarm
/plugin install agent-swarm@agent-swarm
```

## License

MIT. See [LICENSE](LICENSE).

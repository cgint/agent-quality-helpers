# Project Overview & Status Map

**Last updated:** 2026-09-22

## Current Mission
Enable quality, thoughtful, aware work across human and agentic project-native workflows. Create lightweight, fail-safe helpers and Pi integration that support the **4-Gate Deliberation Discipline** (`GATES.md` standard): turn evidence about a current state into a deliberately derived next artifact or action, then prevent advancing until the next stage's preconditions are met.

The current helper candidates support one important application—software delivery—without defining the discipline's boundary:
1. **Gate 1 & 2 Support (`gate-review.sh concept` & `grounding`)**: Validate requirement grounding, concept notes, spec consistency, and tasks.
2. **Gate 3 Support (`gate-review.sh diff` & `gate-check.sh`)**: Support clean TDD diffs, deterministic precommit checks, and worker-mode preflight.
3. **Gate 4 Support (`gate-merge.sh`)**: Replace brittle multi-command cutover recipes (`merge-base`, `precommit`, `glab update/merge`, remote squash verification, `--ff-only` reset, `--inflight` verification) with a single guarded CLI flow.

## Near-Term Pi Extension Direction

**Selected extension/package name:** `pi-deliberation-companion`

**Intent:** Package the reusable GATES deliberation discipline as `pi-deliberation-companion`, a Pi extension that helps people and agents work with quality, thoughtfulness, and awareness; model its packaging and honest tool-contract approach on `pi-subagent-herdr`.

**What it governs:** Human and agentic work begins by understanding the current state from available evidence—such as code, existing requirements, issue context, and prior decisions—then deliberately derives an appropriate next artifact or action. This applies to feature or fix delivery, but is not limited to it: it also applies to investigation, planning, knowledge work, operational changes, and decisions.

**Gates:** Gates are evidence-backed checkpoints, not workflow phases. A gate passes only when the required aspects and human decisions have been met and recorded as preconditions for beginning the next stage. Work within a stage may iterate freely; work may not cross to the next stage early. OpenSpec is one supported implementation of this pattern, not a mandatory mechanism; Jira, Linear, simple Markdown, or another project-native artifact system may carry the work instead.

**It should enable:** Humans and agents to reliably apply this discipline across projects: evidence-based gate transitions, bounded delegation where used, durable task-ledger continuity, explicit human authority at required exits, and disciplined use of existing Pi, Herdr, OpenSpec, and GitLab capabilities where a project uses them.

**Baseline:** Bundled skills are required. They carry the deliberation model, gate-specific behavior, judgment, escalation duties, and the distinction between project governance and reusable support.

**Conditional runtime surface:** Native model-callable Pi/ReAct tools are not assumed. Add one only when it supplies a real, safely constrained mechanical capability that skills and existing tools cannot provide; it must not duplicate a shell recipe, invent proof, silently grant authority, or become a competing control plane.

**Reviewed concept baseline:** [`docs/pi-deliberation-companion-concept.md`](docs/pi-deliberation-companion-concept.md) defines the portable, skills-first core: human handoff/sign-off as universal completion; durable but schema-flexible ledgers; semantic gates independent of enforcement scripts; and optional project-specific adapters.

**Authority boundary:** A consuming repository's governance artifacts—such as `AGENTS.md` and its project-level `GATES.md`—remain authoritative. This package is a reusable support and integration layer, not a replacement workflow or source of approval.

### Layer Model

```text
daily-workflow-helper/GATES.md
        │
        │  concrete, lived delivery contract
        │  + project-specific OpenSpec / Herdr / human-authority rules
        ▼
agent-quality-helpers
        │
        │  extracted reusable discipline:
        │  blueprint + template + skills + helper mechanics
        ▼
Pi extension package
        │
        │  distribution and runtime integration layer:
        │  bundled skills first; native ReAct tools only where justified
        ▼
Pi agent in a project
```

---

## Active Status & Deliverables

| Component | Target Gate | Status | Canonical Path | Description |
|---|---|---|---|---|
| **Durable Pairing Memory** | Standing | Installed | `AGENTS.md` | Standing agent stewardship contract & memory rules |
| **Delivery Gate Architecture** | All Gates | Documented | `docs/artifact-lifecycle-and-quality-loops.md` | Maps Universal Artifact Loop to Gate 1 ➔ 2 ➔ 3 ➔ 4 |
| **GATES Specification & Triad** | All Gates | Documented | `docs/gates-delivery-discipline.md` | 4-Gate lifecycle, Entry/Exit Phase Contracts, Core Contract + Adapters |
| **GATES Skill Requirements** | Skill Design | Documented | `docs/gates-skill-use-cases-and-requirements.md` | 7 LLM situational triggers, failure modes, and SKILL.md specs |
| **Session Empirical Evidence** | Analysis | Documented | `docs/real-world-session-insights.md` | Grounded friction patterns extracted from 3 real-world Pi sessions |
| **`gate-merge.sh`** | **Gate 4** | Implemented (v2) | `gate-merge.sh` | Fail-fast ancestor check, precommit, squash-merge, `--inflight` check & landing |
| **`gate-check.sh`** | **Gates 1–4** | Implemented (v2) | `gate-check.sh` | Parses fenced YAML ledger state, `--preflight` mode/gate validator, `--worktree` anchor |
| **`gate-review.sh`** | **Gates 1–4** | Implemented (v2) | `gate-review.sh` | `--concept`, `--diff`, `--grounding`, `--peer`, `--sheldon`, and `--verify-freshness` |

---

## Empirical Alignment with Real-World Sessions

Derived directly from subagent analysis of past high-volume sessions (`daily-workflow-helper*`):
- **10-Line Manual Checklist Elimination**: Fully automated in `gate-merge.sh` (ancestor, precommit, audit, un-draft, squash-merge, SHA verify, `--inflight` file survival on landing).
- **Premature Implementation Protection**: Physically blocked by `gate-check.sh --preflight <gate> <mode>` (e.g. editable blocked at Gate 2).
- **Stale Review Verdicts on Rebase**: `gate-review.sh --verify-freshness <record>` catches when branch HEAD diverges from reviewed SHA.
- **Automated Peer Review**: `gate-review.sh --sheldon <mr-iid>` replaces manual curl/note polling loops.
- **Entry Protocol Failures**: Formally addressed in `docs/gates-skill-use-cases-and-requirements.md` via Entry Contracts (mandatory companion skills, strict write boundaries).

---

## Current Focus & Next Actions

1. **Self-Contained Verification**: Test the full cycle of `gate-check.sh` $\rightarrow$ `review-gate.sh` $\rightarrow$ `safe-merge.sh` on synthetic test cases.
2. **Firstmate / Lead Ergonomics**: Provide simple 1-line recipes for human leads and Herdr prompts.

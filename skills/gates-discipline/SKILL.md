---
name: gates-discipline
description: Standing 4-Gate delivery discipline, Phase Contracts (Explore ➔ Concept ➔ Implementation ➔ Land), task ledger maintenance, and mechanical gate enforcement (gate-check, gate-review, gate-merge).
---

# GATES Discipline — The 4-Gate Quality & Delivery Protocol

## Purpose & Core Invariant

This skill teaches agents how to navigate software changes and knowledge-work through **four discrete delivery gates**.

> **The Invariant: Phases are fluid; Gates are binding.**

Within a phase, iterate, explore, spike, and test freely. At gate boundaries, work stops until exit criteria (verifiable evidence + required human confirmations) are completely fulfilled and recorded in `GATES_<task>.md`.

---

## When to Consult This Skill (The 7 Triggers)

1. **Task Inception & Cold Start:** Instantiating `GATES_<task>.md` and anchoring the worktree/branch.
2. **Before Delegating to Subagents:** Checking preflight modes (`readonly` vs `editable`) and write scopes.
3. **Approaching a Gate Boundary:** Verifying mechanical exit proofs (`gate-review.sh`) before advancing.
4. **Temptation to Code Early:** Epistemic firewall against modifying application code at Gate 1 or Gate 2.
5. **Disambiguating Terse Human Input:** Knowing what "go", "proceed", or "looks good" authorizes at each gate.
6. **Preparing for Merge & Landing:** Executing safe, verified atomic merges via `gate-merge.sh`.
7. **Discovering Spec Flaws During Coding:** Executing a deliberate gate regression back to Gate 2.

---

## The 4 Gate Contracts

```
┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐
│  GATE 1: EXPLORE   │   │  GATE 2: CONCEPT   │   │  GATE 3: IMPLEMENT │   │  GATE 4: SHIP      │
│  Explore & Scope   ├──►│  Spec & Deliberate ├──►│  TDD Implementation├──►│  Review, Merge     │
│  Requirements      │   │  (Review Bounds)   │   │  (Precommit/Tests) │   │  & Land on Main    │
└────────────────────┘   └────────────────────┘   └────────────────────┘   └────────────────────┘
   Entry: readonly          Entry: spec-writes       Entry: editable TDD      Entry: readonly
   Exit: scope confirmed    Exit: concept review 0   Exit: precommit green &  Exit: peer review clean
   & evidence recorded      + human go-ahead         test proof presented     & verified land on main
```

### Gate 1 — Explore & Understand Requirements
- **Entry Protocol:**
  - Workspace: Target branch anchored. (Optional worktree isolation check: `./gate-check.sh --worktree <target>`)
  - Mode: strictly `readonly`. Preflight: `./gate-check.sh --preflight 1 readonly`
  - Companion Skills: `openspec-explore`, `codebase-search`, `web-search` (or standard codebase scouting skills)
- **Fluid Phase:** Read code, inspect configurations, run tests in read-only mode, formulate scope and non-goals.
- **Exit Criteria:**
  - Fact-pack or research findings committed or recorded in `GATES_<task>.md`.
  - Human scope and non-goal confirmation recorded.

### Gate 2 — Specification & Concept Deliberation
- **Entry Protocol:**
  - Preconditions: Gate 1 passed in ledger.
  - Mode: strictly `readonly` for application code; write access restricted to specification folder (e.g. `openspec/changes/<name>/` or `docs/`).
  - Preflight: `./gate-check.sh --preflight 2 readonly`
  - Companion Skills: `openspec-propose`, `criticalthink`, `socratic-first-principles`
- **Fluid Phase:** Author proposal, specs, and tasks. Deliberate edge cases, failure modes, and anti-goals. Label uncertainties (`[unverified]`).
- **Exit Criteria:**
  - `./gate-review.sh concept <path/to/spec>` exits `0` (verifies explicit non-goals, bounds, epistemic markers).
  - **Human "Go-Ahead":** Explicit human permission to start coding recorded with timestamp in ledger.

### Gate 3 — Test-Driven Implementation
- **Entry Protocol:**
  - Preconditions: Gate 2 passed and human go-ahead recorded.
  - Mode: `editable`. Preflight: `./gate-check.sh --preflight 3 editable`
  - Write Scope: Narrowest directory tree required for the slice (`launch cwd = write scope`).
  - Companion Skills: `openspec-apply-change`
- **Fluid Phase:**
  - Strict TDD cycle: red test ➔ minimal green code ➔ refactor.
  - Slicing: work through task groups sequentially; verify each slice before advancing.
- **Exit Criteria (Agent DoD):**
  - All specification tasks checked `[x]` with evidence.
  - `./gate-review.sh diff HEAD` exits `0` (runs `./precommit.sh` and asserts tests were added/updated).
  - Present proof summary to human ➔ **STOP** (agents strictly forbidden from merging or ticking user sign-offs).

### Gate 4 — Review, Sign-off, & Merge to Main
- **Entry Protocol:**
  - Preconditions: Gate 3 proof accepted by human.
  - Mode: `readonly` (merge execution only).
  - Companion Skills: `gitlab-mr-workflow`
- **Fluid Phase:**
  - Branch hygiene check: `./gate-review.sh peer` (checks upstream branch and unpushed commits).
  - Automated Peer Review: `./gate-review.sh sheldon <mr-iid>` (or peer reviewer pass).
  - Review Freshness: `./gate-review.sh verify-freshness <record>` (fails if branch HEAD moved since review).
- **Exit Criteria:**
  - Human reviews proof, marks acceptance (`[User Verification]`), and commands merge.
  - Atomic Landing: `./gate-merge.sh merge <mr-iid> [--allow-dirty] [--inflight "<paths>"]`.
  - Confirm squash-merged commit on remote `main` and clean workspace switch to `main`.

---

## Tooling Execution Matrix

| Gate | Purpose | Command |
|---|---|---|
| **Any** | Verify ledger state & preflight worker mode | `./gate-check.sh --preflight <gate> <mode>` |
| **Any** | Verify current git worktree anchor | `./gate-check.sh --worktree <expected-name>` |
| **Gate 2** | Audit proposal bounds & non-goals | `./gate-review.sh concept <proposal.md>` |
| **Gate 3** | Precommit & TDD diff verification | `./gate-review.sh diff HEAD` |
| **Gate 4** | Branch hygiene & unpushed check | `./gate-review.sh peer` |
| **Gate 4** | Automated bot interaction (@ai-sheldon) | `./gate-review.sh sheldon <mr-iid>` |
| **Gate 4** | Assert review SHA matches current HEAD | `./gate-review.sh verify-freshness <record.md>` |
| **Gate 4** | Dry-run merge check (zero mutations) | `./gate-merge.sh check <mr-iid>` |
| **Gate 4** | Atomic squash-merge & workspace reset | `./gate-merge.sh merge <mr-iid> --inflight "<files>"` |

---

## Task Ledger Maintenance (`GATES_<task>.md`)

Every task maintains a living ledger at the repository root. The machine state lives under `## Machine State`:

````markdown
## Machine State
```yaml
current_gate: 2
gate_states:
  gate_1: { status: PASSED, date: "2026-09-22", evidence: "docs/findings.md" }
  gate_2: { status: IN_PROGRESS, human_go_ahead: null, artifacts: "openspec/changes/feat-xyz" }
  gate_3: { status: BLOCKED, reason: "gate_2 not passed" }
  gate_4: { status: BLOCKED, reason: "gate_3 not passed" }
```
````

Agents must update this block upon passing each gate. Never invent intermediate gate numbers.

---

## Runtime Bindings

### A. Herdr Multi-Agent Runtime (`sub-agent-herdr-supervisor` + `sub-agent-handoff`)
When operating with a Herdr / tmux control plane:
1. Run `./gate-check.sh --preflight <gate> <mode>` before calling `herdr-start-subagent.sh`.
2. Enforce **`launch cwd = write scope`**: Launch workers in the narrowest directory containing all their authorized writes and report path.
3. Supervisor retains mandatory responsibility for child pane cleanup upon worker completion.
4. Workers never execute `gate-merge.sh` or tick human acceptance boxes.

### B. Solo / Direct Session Runtime
When working as a single agent in a direct terminal or non-Herdr environment:
1. Honor phase modes internally: treat Gate 1 and Gate 2 as read-only / spec-only.
2. Run `./gate-review.sh` commands directly in the repository root.
3. Stop at Gate 3 and Gate 4 exit boundaries for explicit human instructions.

---

## Deliberate Regression Protocol

If an unexpected finding during Gate 3 or Gate 4 invalidates a specification or architectural assumption:
1. **STOP coding immediately.** Do not patch requirement gaps with ad-hoc code hacks.
2. Update the ledger: set `current_gate: 2` and state the regression reason.
3. Amend the specification document.
4. Run `./gate-review.sh concept <spec>` until green.
5. Re-acquire explicit human "go-ahead" before resuming Gate 3 implementation.

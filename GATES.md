# GATES.md — Delivery Gate Discipline (Universal Blueprint)

## Purpose

Every change moves through **four discrete gates**. No gate is skipped; a gate passes on **evidence, not self-report**.

This file is the **canonical blueprint**. An active task instantiates it as `GATES_<task-name>.md` at the repository root, recording task-specific facts: gate states with timestamps and evidence pointers, worker registry, decisions, and external blockers.

---

## The Core Invariant

> **Phases are fluid; Gates are binding.**

The work is organized in **phases** (continuous work: exploring, authoring, implementing, reviewing) and **gates** (discrete pass/fail checkpoints at phase boundaries).

**ABSOLUTELY FORBIDDEN: moving to a subsequent gate before the current gate's exit criteria are fulfilled.**
Every exit criterion — verifiable evidence *and* required human confirmations — must exist and be recorded in the task ledger before any work of the next gate begins. This binds the lead agent and every subagent. There are no soft transitions, no carrying work across a gate "to finish later", and no worker may start later-gate work "in parallel".

Within a phase, iterate freely (review ➔ fix ➔ re-validate; slice ➔ test ➔ re-slice). Transitions forward are criteria-gated; the only way backward is a **deliberate gate regression**, reopening the earlier gate and its evidence.

---

## Gate Chain at a Glance

```
┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐
│  GATE 1: EXPLORE   │   │  GATE 2: CONCEPT   │   │  GATE 3: IMPLEMENT │   │  GATE 4: SHIP      │
│  Explore & Scope   ├──►│  Spec & Deliberate ├──►│  TDD Implementation├──►│  Review, Merge     │
│  Requirements      │   │  (Review Bounds)   │   │  (Precommit/Tests) │   │  & Land on Main    │
└────────────────────┘   └────────────────────┘   └────────────────────┘   └────────────────────┘
   Mode: readonly           Mode: spec-writes only   Mode: editable           Mode: readonly
   Enforce:                 Enforce:                 Enforce:                 Enforce:
   gate-check --preflight   gate-review concept      gate-review diff         gate-review sheldon/peer
                            gate-check --preflight   precommit / tests        gate-merge check/merge
```

---

## Phase Contracts (Entry, Fluid Work, Exit)

### Gate 1 — Explore & Understand Requirements
- **Goal:** Understand existing behavior, locate relevant code/docs, formulate scope, identify constraints and non-goals.
- **Worktree Isolation (Optional):** If operating in parallel worktrees, verify directory anchor via `./gate-check.sh --worktree <target>`. In standard single-worktree setups, branch verification is sufficient.
  - **Mode:** strictly `readonly`. Preflight: `./gate-check.sh --preflight 1 readonly`.
  - **Recommended Skills (Agnostic / OpenSpec):** `openspec-explore`, `codebase-search`, `web-search`, or standard codebase scouting.
- **Fluid Phase:**
  - Read code, execute read-only commands (`colgrep`, `rg`, tests in read-only mode).
  - Draft fact-pack, investigate ambiguities.
- **Exit Criteria:**
  - Fact-pack / research findings committed or recorded in ledger.
  - Scope and explicit non-goals confirmed with the human.

### Gate 2 — Specification & Concept Deliberation
- **Goal:** Author the change specification, deliberate architecture, test boundaries, and design before writing production code.
- **Entry Protocol:**
  - Preconditions: Gate 1 passed with human confirmation recorded in ledger.
  - Mode: `readonly` for application code; write permissions restricted strictly to specification directory (e.g. `openspec/changes/<name>/` or `docs/proposals/`).
  - Preflight: `./gate-check.sh --preflight 2 readonly` (or spec-restricted).
  - Recommended Skills: `openspec-propose`, `criticalthink`, `socratic-first-principles`.
- **Fluid Phase:**
  - Author specification artifacts: `proposal.md`, `specs/`, `tasks.md`.
  - Deliberate edge cases, error conditions, trade-offs, and epistemic uncertainties (`[unverified]`).
- **Exit Criteria:**
  - `./gate-review.sh concept <spec-file>` exits `0` (checks explicit non-goals, bounds, epistemic honesty).
  - **Explicit Human "Go-Ahead":** Human reviews proposal and grants permission to start coding. Recorded with timestamp in ledger.

### Gate 3 — Test-Driven Implementation
- **Goal:** Implement the change in small, verified slices using Test-Driven Development (TDD).
- **Entry Protocol:**
  - Preconditions: Gate 2 passed and explicit human go-ahead recorded in ledger.
  - Mode: `editable`. Preflight: `./gate-check.sh --preflight 3 editable`.
  - Write Scope: Narrowest directory tree required for the active slice (`launch cwd = write scope`).
  - Recommended Skills: `openspec-apply-change`.
- **Fluid Phase:**
  - Strict TDD cycle: failing test (red) ➔ minimal implementation (green) ➔ refactor.
  - Slicing: one task group or slice per worker/cycle; verify each slice before advancing.
  - Run linters and unit test suites continuously.
- **Exit Criteria (Agent's Definition of Done):**
  - All tasks in specification marked done with verifiable evidence.
  - `./gate-review.sh diff HEAD` exits `0` (runs `./precommit.sh` and verifies tests were added/updated).
  - Proof summary presented to the human ➔ **STOP** (agents strictly forbidden from merging or ticking user sign-offs).

### Gate 4 — Review, Sign-off, & Merge to Main
- **Goal:** Independent verification, automated peer review, human acceptance, and atomic merge into target branch.
- **Entry Protocol:**
  - Preconditions: Gate 3 exit proof verified and accepted by human.
  - Mode: `readonly` (merge execution only).
  - Recommended Skills: `gitlab-mr-workflow` (or platform equivalent).
- **Fluid Phase:**
  - Branch hygiene check: `./gate-review.sh peer` (ensures branch is pushed, upstream tracking exists, working tree clean).
  - Automated Peer Review: `./gate-review.sh sheldon <mr-iid>` (or peer reviewer pass).
  - Review Freshness: `./gate-review.sh verify-freshness <record>` (ensures branch HEAD has not moved since review verdict).
- **Exit Criteria:**
  - Human reviews proof, marks acceptance (`[User Verification]`), and commands merge.
  - Atomic Landing: `./gate-merge.sh merge <mr-iid> [--allow-dirty] [--inflight "<paths>"]`.
  - Remote verification: Confirm squash-merged commit SHA exists on remote `main`, and clean workspace switch to `main` completed.

---

## Standing Delegation & Subagent Rules

When delegating work to subagents or worker panes:
1. **Mode by Purpose:**
   - Scouts & Reviewers: strictly `readonly` (terminal report only; no write scope).
   - Mechanics & Implementers: bounded `editable` at Gate 3 only.
2. **Launch Directory = Write Scope:**
   - The worker must be launched with its `cwd` set to the narrowest directory containing all authorized writes and its report path.
3. **Mandatory Preflight:**
   - Run `./gate-check.sh --preflight <gate> <mode>` before opening any worker pane.
4. **Mandatory Teardown:**
   - The supervisor owns the lifecycle of every pane it creates. Capture evidence and close panes immediately after task completion.
5. **Absolute Invariants for Workers:**
   - Workers never commit to `main`, never merge, never force-push, and never tick human acceptance checkboxes.
   - Workers must escalate immediately upon encountering contradictions, missing prerequisites, or scope breach.

---

## Deliberate Regression Protocol

If an unexpected finding during Gate 3 or Gate 4 invalidates a **requirement or architectural assumption**:
1. **STOP coding immediately.** Do not patch requirement gaps with ad-hoc code hacks.
2. **Reopen Gate 2 in the task ledger:** Update `current_gate: 2` and state the regression reason.
3. **Amend the specification** in the proposal or change directory.
4. **Re-run Gate 2 review:** `./gate-review.sh concept <spec-file>` must pass.
5. **Re-acquire human go-ahead** before resuming implementation at Gate 3.

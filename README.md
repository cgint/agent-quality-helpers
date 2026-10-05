# Agent Quality Helpers & Delivery Gate Toolkit

> **A quality-first operating system for AI-assisted development: guiding work from raw requirements to verified merge through four non-negotiable gates.**

---

## Universal Lifecycle Architecture

When delivering software with AI agents (or human pairs), work is organized into **fluid phases** protected by **binding gates**:

- **Phases are fluid**: Inside a phase, you iterate, explore, spike, and draft freely.
- **Gates are binding**: Boundaries are discrete, criteria-gated checkpoints. No work of a subsequent phase begins until the current gate's exit criteria and human confirmations are fulfilled.

```
┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐
│  GATE 1: EXPLORE   │   │  GATE 2: CONCEPT   │   │  GATE 3: IMPLEMENT │   │  GATE 4: SHIP      │
│  Explore & Scope   ├──►│  Spec & Deliberate ├──►│  TDD Implementation├──►│  Review, Merge     │
│  Requirements      │   │  (Review Bounds)   │   │  (Precommit/Tests) │   │  & Land on Main    │
└────────────────────┘   └────────────────────┘   └────────────────────┘   └────────────────────┘
   Mode: readonly           Mode: spec-writes only   Mode: editable           Mode: readonly
   Exit: scope grounded &   Exit: concept review 0   Exit: precommit green &  Exit: peer review clean
   evidence recorded        + human go-ahead         test proof presented     & verified land on main

   Supporting Tool:         Supporting Tool:         Supporting Tool:         Supporting Tool:
   gate-check.sh            gate-review.sh concept   gate-review.sh diff      gate-review.sh peer
   (preflight readonly)     gate-check.sh            precommit.sh / pytest    gate-merge.sh
```

---

## Why This Matters (The Real Problems Solved)

1. **Premature Implementation**: LLMs frequently start writing code before requirements, bounds, or non-goals are agreed upon. Gate 1 and 2 physically enforce read-only/spec-only modes.
2. **Error-Prone Manual Merge Rituals**: Safely merging an MR requires verifying remote ancestors, running tests, checking hygiene, squashing, confirming the remote SHA, and preserving uncommitted in-flight files. `gate-merge.sh` turns this into a single atomic transaction.
3. **Stale Review Verdicts**: A rebase or amend changes the commit SHA, but agents assume a prior review still holds. `gate-review.sh verify-freshness` detects rebase invalidation immediately.
4. **Subagent Drift**: Workers launched without strict boundaries wander outside their scope. The GATES discipline enforces `launch cwd = write scope` and preflight verification.

---

## The Delivery Journey (Stage by Stage)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       TOOLKIT LIFECYCLE MAPPING                             │
├──────────────────────────┬──────────────────────────┬───────────────────────┤
│ 1. gate-check.sh         │ 2. gate-review.sh        │ 3. gate-merge.sh      │
├──────────────────────────┼──────────────────────────┼───────────────────────┤
│ • Gates 1–4              │ • Gates 2–4              │ • Gate 4              │
│ • Task ledger validator  │ • Deliberation & audits  │ • Atomic squash-merge │
│ • Mode preflight guard   │ • Linters, diffs & bots  │ • Landing & workspace │
│                          │                          │   reset               │
└──────────────────────────┴──────────────────────────┴───────────────────────┘
```

### Stage 1: Explore & Ground Requirements (Gate 1)
* **Goal**: Understand the problem, locate relevant code, formulate scope, and identify non-goals.
* **Invariant**: Strictly `readonly`. No code edits or file mutations.
```bash
# Verify process is operating in the intended directory/worktree
./gate-check.sh --worktree my-feature

# Preflight check: confirm task ledger is at Gate 1 and mode is readonly
./gate-check.sh --preflight 1 readonly
```

### Stage 2: Specify & Deliberate Architecture (Gate 2)
* **Goal**: Author proposals, design specifications, and test contracts.
* **Invariant**: Production code remains locked; write access is restricted to spec folders (e.g. `openspec/changes/<name>/` or `docs/`).
```bash
# Audit proposal for explicit non-goals, scope bounds, and epistemic honesty
./gate-review.sh concept docs/proposals/feat-xyz.md

# Preflight: editable mode remains blocked until human go-ahead is recorded
./gate-check.sh --preflight 2 readonly
```

### Stage 3: Test-Driven Implementation (Gate 3)
* **Goal**: Implement behavior in small, verifiable slices following strict TDD.
* **Invariant**: Editable mode unlocked. Work follows failing test ➔ green code ➔ refactor.
```bash
# Verify implementation slice: asserts linters pass and tests were added/updated
./gate-review.sh diff HEAD
```
* **Stopping Rule**: When all tasks are complete and checks are green, the agent presents the proof summary and **stops**. Agents never merge or tick human sign-offs.

### Stage 4: Peer Review, Merge & Land (Gate 4)
* **Goal**: External peer review, human acceptance, and atomic merge into `main`.
* **Invariant**: Read-only during review; landing verifies upstream continuity and preserves uncommitted in-flight files.
```bash
# 1. Branch hygiene check (verifies branch is pushed and tracking upstream)
./gate-review.sh peer

# 2. Automated peer reviewer pass (trigger and poll @ai-sheldon or peer bot)
./gate-review.sh sheldon <mr-iid>

# 3. Freshness check: fails if branch HEAD moved since review sign-off
./gate-review.sh verify-freshness docs/review-record.md

# 4. Dry-run preflight check (zero git mutations)
./gate-merge.sh check <mr-iid>

# 5. Atomic merge & land: squash-merge, verify remote SHA, preserve in-flight files, switch to main
./gate-merge.sh merge <mr-iid> [--allow-dirty] [--inflight "notes.md patch.diff"]
```

---

## 🚀 Quick Start & Installation

Install the helper tools and companion skill into your local environment:

```bash
# 1. Symlink helper tools into your local PATH (e.g. ~/.local/bin)
ln -sf "$(pwd)/gate-check.sh" ~/.local/bin/gate-check.sh
ln -sf "$(pwd)/gate-review.sh" ~/.local/bin/gate-review.sh
ln -sf "$(pwd)/gate-merge.sh" ~/.local/bin/gate-merge.sh

# 2. Symlink the GATES discipline skill into your Pi agent profile
ln -sfn "$(pwd)/skills/gates-discipline" ~/.pi/profiles/minimal/agent/skills/gates-discipline
```

---

## Canonical Blueprint & Artifacts

- **`GATES.md`**: The universal 4-Gate blueprint and delivery discipline rules.
- **`GATES_TEMPLATE.md`**: Starter task ledger with the machine-readable `## Machine State` YAML block.
- **`gate-check.sh`**: Task ledger parser, gate validator, and worker mode preflight.
- **`gate-review.sh`**: Multi-phase review harness (`concept`, `diff`, `grounding`, `peer`, `sheldon`, `verify-freshness`).
- **`gate-merge.sh`**: Atomic pre-flight check, squash-merge, remote verification, and workspace reset tool.
- **`skills/gates-discipline/SKILL.md`**: Companion Pi skill teaching agents when to stop, what to verify, and how to command the tools.

---

## Further Reading

- [`docs/gates-delivery-discipline.md`](docs/gates-delivery-discipline.md) — The complete GATES specification, Phase Contracts, and living ledger schema.
- [`docs/gates-skill-use-cases-and-requirements.md`](docs/gates-skill-use-cases-and-requirements.md) — Operational triggers and LLM behavioral requirements.
- [`docs/review-gate-contracts.md`](docs/review-gate-contracts.md) — CLI exit codes, strict modes, and JSON payloads for review tools.
- [`docs/real-world-session-insights.md`](docs/real-world-session-insights.md) — Empirical evidence and friction patterns extracted from real-world agent sessions.
- [`docs/artifact-lifecycle-and-quality-loops.md`](docs/artifact-lifecycle-and-quality-loops.md) — Universal recursive artifact loop architecture.

# Delivery Gate Discipline & Living Ledger

This document defines the canonical specification for the **4-Gate Delivery Discipline** and the living task ledger format (`GATES_<task>.md`).

---

## 1. Core Principles

1. **Phases vs. Gates vs. Entry Protocols**:
   - **Entry Protocols** govern preconditions, mandatory companion skills, and write scope boundaries (*inputs*).
   - **Phases** are fluid working regions where work is conducted freely within bounds.
   - **Gates** are discrete, non-negotiable pass/fail checkpoints at phase boundaries (*exit verification*).
2. **Phase Contracts (Inputs + Fluid Work + Exit Proof)**:
   - Work is organized around **4 discrete Gates**. Rather than creating 10 bureaucratic micro-steps, each Gate defines a complete **Phase Contract**:
     - *Entry Protocol*: Preconditions, mode (`readonly` vs `editable`), write boundaries, and mandatory skills.
     - *Fluid Phase*: Creative problem solving, spikes, iterations, and drafting.
     - *Exit Gate*: Deterministic mechanical verification (`gate-*.sh`) and explicit human confirmation.
3. **The Invariant Rule**:
   - It is **strictly forbidden** to begin work on a subsequent gate until the current gate's exit criteria (evidence and human sign-off) are completely fulfilled and recorded in the task ledger.
4. **Evidence-Based Transitions**:
   - Gates pass on verifiable filesystem artifacts, test outcomes, and recorded human decisions—never on self-reported completion.
5. **Deliberate Regression**:
   - Reopening an earlier gate (e.g. if implementation reveals a flaw in the specification) requires an explicit, recorded gate regression in the ledger.

---

## 2. The 4 Delivery Gate Contracts

```
┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐
│  GATE 1: EXPLORE   │   │  GATE 2: CONCEPT   │   │  GATE 3: IMPLEMENT │   │  GATE 4: SHIP      │
│  Explore & Scope   ├──►│  Spec & Deliberate ├──►│  TDD Implementation├──►│  Review, Merge     │
│  Requirements      │   │  (Review Bounds)   │   │  (Precommit/Tests) │   │  & Land on Main    │
└────────────────────┘   └────────────────────┘   └────────────────────┘   └────────────────────┘
   Entry: readonly          Entry: spec-only         Entry: editable TDD      Entry: readonly
   Skill: openspec-explore  Skill: openspec-propose  Skill: openspec-apply    Skill: gitlab-mr-workflow
   Exit: scope grounded &   Exit: concept review 0   Exit: precommit green &  Exit: peer review clean
   evidence recorded        + human go-ahead         test proof presented     & verified land on main
```

---

## 3. Living Task Ledger Specification (`GATES_<task>.md`)

Every active task instantiates an instance ledger at the repository root.

### Canonical Header & Fenced Machine State
To maintain clean visual rendering in markdown viewers while enabling reliable parsing by shell and Python scripts, the machine-checkable state is placed under an explicit `## Machine State` section inside a fenced code block:

````markdown
# GATES_<task-id> — <Descriptive Title>

## Machine State

```yaml
current_gate: 2
gate_states:
  gate_1: { status: PASSED, date: "YYYY-MM-DD", evidence: "<path-or-summary>" }
  gate_2: { status: IN_PROGRESS, human_go_ahead: null, artifacts: "<git-ref>", review: "pending" }
  gate_3: { status: BLOCKED, reason: "gate_2 not passed" }
  gate_4: { status: BLOCKED, reason: "gate_3 not passed" }
```
````

### Body Structure
1. **Metadata**: Task id, branch name, change folder, blueprint reference, active subagent registry.
2. **Gate Sections (1–4)**: Detailed dated evidence, key decisions, review findings, and sign-offs.
3. **Subagent Registry**: Tracking pane IDs, assigned gates, modes (`readonly` vs `editable`), and closure evidence.
4. **External Prerequisites**: External blockers (credentials, cloud consoles, third-party approvals).
5. **Open Loops**: Active questions, uncertainties, and next steps.

---

## 4. The GATES Triad: Specification, Enforcement, & Skill

GATES is structured as a three-part system so that methodology and physical mechanics evolve together in one repository:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THE GATES TRIAD SYSTEM                          │
├──────────────────────┬─────────────────────────┬───────────────────────┤
│ 1. SPECIFICATION     │ 2. ENFORCEMENT          │ 3. AGENT STEERING     │
│    (GATES.md)        │    (gate-*.sh)          │    (skills/gates/...) │
├──────────────────────┼─────────────────────────┼───────────────────────┤
│ • The 4 Gates rule   │ • Deterministic checks  │ • Teaches agents when │
│ • Exit criteria      │ • Physical preflights   │   and how to run each │
│ • State definitions  │ • Zero-mutation guards  │   gate tool           │
│ • "Phases are fluid; │ • Automated Sheldon     │ • Strict boundary &   │
│   gates are binding" │ • Atomic landing        │   escalation protocol │
└──────────────────────┴─────────────────────────┴───────────────────────┘
```

---

## 5. Architectural Contract: Core Lifecycle + Reference Adapters

To prevent locking GATES into a specific execution environment (such as tmux or Herdr) while avoiding vague abstract instructions, the architecture uses a **Core Contract + Reference Adapters** pattern:

### A. Core Lifecycle Contract (Framework Agnostic)
The core rules apply universally across single-agent sessions, paired human work, CI pipelines, and multi-agent harnesses:
- **Phase Invariant**: Phases are fluid; gates are strictly binding.
- **Preflight Enforceability**: Worker modes cannot exceed gate allowance (`readonly` at Gate 1 & 2; `editable` only at Gate 3).
- **Zero Self-Certification**: Transitions require deterministic filesystem, git, or human evidence.
- **Freshness Invariant**: Code changes after review verdict immediately invalidate approval (`gate-review.sh verify-freshness`).

### B. Reference Adapters (Execution Runtime Bindings)
The companion skill (`skills/gates-discipline/SKILL.md`) routes execution to specific harnesses without baking runner assumptions into the lifecycle definition:

1. **Herdr Multi-Agent Adapter (`sub-agent-herdr-supervisor` + `sub-agent-handoff`)**:
   - Used when tmux/Herdr control plane is present.
   - Enforces: `launch directory = write scope`, mandatory child pane cleanup, timeout budgets, and distinct identity chains (`Horst -> Judith -> Benjamin`).
   - Bounded launches guarded via `./gate-check.sh --preflight <gate> <mode>`.
2. **Solo / Direct Session Adapter**:
   - Used in standard single-pane coding sessions or environments without Herdr.
   - The lead agent executes commands (`gate-check.sh`, `gate-review.sh`) directly in the workspace, respecting phase mode restrictions strictly via self-discipline and tool exit codes.
3. **CI / Outer Automation Adapter**:
   - Executes `./gate-check.sh` and `./gate-review.sh` in headless pipelines to gate pull/merge requests.

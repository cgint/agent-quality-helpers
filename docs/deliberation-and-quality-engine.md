# Architecture: Generic Deliberation & Quality Control Engine

## 1. Intent & Scope

Knowledge work and software engineering are iterative, assumption-heavy activities. Left unguided, agents and developers rush to implementation, invent ungrounded requirements, allow silent spec drift, or cross phase boundaries prematurely.

This engine provides a **generic, lightweight, framework-agnostic quality-control and deliberation framework**. It serves:
1. **The Primary (Human-Facing / Firstmate) Session**: Maintaining strategic clarity, enforcing phase boundaries, orchestrating reviews, and demanding human deliberation where required.
2. **Subagents / Workers**: Equipping delegated workers with bounded preflights, self-audits, discrepancy checks, and structured verification tools before returning their work reports.

---

## 2. Foundational Pillars

```
                                  ┌────────────────────────────────┐
                                  │   THE HUMAN / LEAD SESSION     │
                                  └───────────────┬────────────────┘
                                                  │
                                                  ▼
                  ┌───────────────────────────────────────────────────────────────┐
                  │                 LIVING TASK LEDGER (GATES_*.md)               │
                  │   Fenced Machine State  +  Human Decisions  +  Evidence Audit │
                  └───────────────────────────────┬───────────────────────────────┘
                                                  │
                 ┌────────────────────────────────┴────────────────────────────────┐
                 ▼                                                                 ▼
┌─────────────────────────────────┐                             ┌─────────────────────────────────┐
│     MECHANICAL ENFORCEMENT      │                             │    DELIBERATION & REVIEW GATES  │
│  (Zero-LLM, Deterministic)      │                             │    (Crosscheck, Multi-Perspective)
├─────────────────────────────────┤                             ├─────────────────────────────────┤
│ • gate-check: Validate state    │                             │ • gate-review: Multi-perspective│
│   transitions & worker modes    │                             │   critical review pass          │
│ • openspec-audit: Drift & shell │                             │ • discrepancy-check: Trace      │
│   hygiene                       │                             │   spec vs diff drift            │
│ • gate-merge: Ancestor & landing│                             │ • claims-audit: Grounding audit │
│   safety                        │                             │   (evidence vs invention)       │
└─────────────────────────────────┘                             └─────────────────────────────────┘
```

### Pillar A: Deliberation & Grounding (Evidence before Invention)
- **Deliberation vs Rush**: Any significant architectural choice, feature boundary, or behavior change must pass an explicit deliberation checkpoint before code is written.
- **The Grounding Rule**: Every claim in a proposal, spec, or review must cite verifiable source evidence (code lines, user transcripts, git history). Unsubstantiated claims are labeled `[unverified]` or flagged as hallucinations.

### Pillar B: Gate-Oriented Boundaries (Phases are Fluid; Gates are Binding)
- Work within a phase can iterate freely.
- Moving across a gate boundary is strictly one-way and requires:
  1. Complete exit evidence.
  2. Recorded human go-ahead (where specified).
  3. Machine state update in the living ledger.
- Regressions (moving backward) must be explicit, documented events.

### Pillar C: Multi-Perspective & Buddy Review
- A generator should not be its own sole evaluator.
- Review passes are decoupled:
  - **Critical Stance**: Looks for edge cases, security holes, performance traps, and unnecessary complexity.
  - **Fidelity Stance**: Verifies that the implementation does exactly what the specification intended—nothing more, nothing less.
  - **Grounding Stance**: Audits that all factual statements match codebase reality.

---

## 3. Toolkit Specification

The toolkit consists of lightweight, dependency-free shell and Python tools that can be invoked directly from the CLI by either the human lead or an agent:

| Tool | Role | Function |
|---|---|---|
| **`gate-check.sh`** | Gatekeeper | Parses `## Machine State` in `GATES_*.md`. Validates if an action or worker launch matches current gate rules and permissions. |
| **`gate-review.sh`** | Deliberation & Review | Runs multi-perspective reviews (mechanical linters + AI peer passes + discrepancy detection). |
| **`gate-merge.sh`** | Final Merge & Land | Atomic pre-flight check, ancestor verification, squash-merge, and workspace reset. |
| **`openspec-audit.sh`** | Hygiene & Drift | Classifies active change directories and prevents drift against living inventories. |

---

## 4. Machine State Contract (`GATES_<task>.md`)

Every task ledger encapsulates its machine state inside a fenced block:

````markdown
## Machine State

```yaml
task_id: "TASK-1234"
current_gate: 2
gate_states:
  gate_1:
    name: "Explore & Scope"
    status: "PASSED"
    evidence: "agent/tmp/scope-model.md"
  gate_2:
    name: "Specification & Concept Review"
    status: "IN_PROGRESS"
    human_go_ahead: null
  gate_3:
    name: "Implementation (TDD)"
    status: "BLOCKED"
  gate_4:
    name: "Review & Cutover"
    status: "BLOCKED"
```
````

This structure guarantees that any agent, subagent launcher, or CI script can instantly determine what operations are authorized in under 10 milliseconds without parsing natural language prose.

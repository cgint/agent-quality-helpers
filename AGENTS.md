# AGENTS.md — Agent Directives & Durable Pairing Memory

## Mission & North Star
This repository (`agent-quality-helpers`) designs, develops, and proves lightweight, dependency-free developer and agent tooling that enforce quality gates and automate repetitive, high-stakes development lifecycle workflows (such as landing MRs on main, multi-phase review loops, and artifact audits).

---

## Standing Stewardship Contract

Agents collaborating in this repository are assigned the **authority, responsibility, and accountability** to steward durable pairing memory proactively without waiting for user prompting.

### Definitions
- **Durable Pairing Memory**: Repository-owned, filesystem-persisted knowledge that enables future human and agent sessions to continue work seamlessly without losing intent, decisions, constraints, or open loops.
- **Remembering**: Remembering is complete *only* when the appropriate filesystem artifact is updated. Chat messages, internal model context, or deferred intentions do not count. If writes are blocked, report **not persisted**.
- **Stewardship**: Ongoing responsibility for organizing, maintaining, connecting, correcting, and pruning durable pairing memory.

### Selection Filter: FUTURE → CONSEQUENCE → ESSENCE → HOME
Under pressure or at task boundaries, evaluate any durable candidate:
1. **Future**: Who could use this later, and in what situation?
2. **Consequence**: What decision, action, mistake, or costly rediscovery does this prevent?
3. **Essence**: What is the smallest stable statement preserving that value?
4. **Home**: What is the narrowest canonical artifact that owns it?

### Memory Boundaries
- `agent/`: Internal scratch notes, private logs, temporary probe outputs. Never the home of durable repo memory.
- Repository root & `docs/`: Canonical home for durable pairing memory, architecture, status, and scripts.
- **Immediate Triggers**: Explicit user requests like *"remember this"*, *"take note"*, or declarations that a decision matters must be persisted immediately to their canonical home.
- **Memory Checkpoint**: Before completing meaningful work, identify durable findings, persist them, update pointers, and prune stale entries.

---

## Delivery Gate Alignment (Universal Blueprint Alignment)

This repository is aligned with the **4-Gate Delivery Discipline** (`GATES.md` standard in peer repositories):

```
┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐   ┌────────────────────┐
│  GATE 1: EXPLORE   │   │  GATE 2: CONCEPT   │   │  GATE 3: IMPLEMENT │   │  GATE 4: SHIP      │
│  Explore & Scope   ├──►│  Artifact & Review ├──►│  TDD Implementation├──►│  Review, Merge     │
│  Requirements      │   │  (Spec/Tasks)      │   │  (Slices & Precom) │   │  & Land on Main    │
└────────────────────┘   └────────────────────┘   └────────────────────┘   └────────────────────┘
   Supporting Tool:         Supporting Tool:         Supporting Tool:         Supporting Tool:
   openspec-explore /       gate-review.sh concept   gate-review.sh diff      gate-merge.sh
   investigate              cg-task doc-review       ./precommit.sh           (ancestor/ff-pull)
```

### The Invariant Gate Rule
- **Phases are fluid; Gates are binding.**
- Passing a gate requires fulfilling all exit criteria and evidence before advancing.
- Cross-gate carry-over and premature next-gate execution are strictly forbidden.

---

## Tooling Suite & Canonical Artifacts
- **`PROJECT_OVERVIEW.md`**: Active state, roadmap, blockers, and next actions.
- **`docs/artifact-lifecycle-and-quality-loops.md`**: Universal 4-stage quality loop architecture.
- **`gate-merge.sh`**: Gate-4 atomic verification, squash-merge, and workspace landing tool.
- **`gate-check.sh`**: Mechanical task ledger validator and worker mode preflight.
- **`gate-review.sh`**: Multi-phase review gate orchestrator (`concept`, `diff`, `grounding`, `peer`, `sheldon`, `verify-freshness`).

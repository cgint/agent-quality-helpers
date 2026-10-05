# GATES_<task> — <Task Title or Jira Key>

## Machine State

```yaml
current_gate: 1
gate_states:
  gate_1: { status: IN_PROGRESS, date: "YYYY-MM-DD", evidence: null }
  gate_2: { status: BLOCKED, reason: "gate_1 not passed", human_go_ahead: null }
  gate_3: { status: BLOCKED, reason: "gate_2 not passed" }
  gate_4: { status: BLOCKED, reason: "gate_3 not passed" }
```

---

## Task Metadata
- **Task ID:** `<TASK-ID>`
- **Branch:** `<feature-branch-name>`
- **Worktree:** `<path-to-worktree>`
- **Specification / Change Path:** `<path-to-spec-or-change-folder>`
- **Lead / Controller:** `<lead-agent-identity>`

---

## Gate Records & Evidence

### Gate 1 — Explore & Understand Requirements
- **Status:** IN_PROGRESS
- **Evidence Pointers:** `<path-to-findings-or-doc>`
- **Scope Confirmation:** `<human confirmation timestamp>`

### Gate 2 — Specification & Concept Deliberation
- **Status:** BLOCKED
- **Specification Review Verdict:** `pending` (target: `./gate-review.sh concept <path>`)
- **Explicit Human Go-Ahead:** `pending` (timestamp & confirmation required to advance)

### Gate 3 — Test-Driven Implementation
- **Status:** BLOCKED
- **Implementation Slices:**
  - Slice 1: `<description>` — Worker: `<name>`, Status: `pending`
- **Diff & Precommit Verdict:** `pending` (target: `./gate-review.sh diff HEAD`)
- **Human Proof Presented:** `pending`

### Gate 4 — Review, Sign-off, & Merge to Main
- **Status:** BLOCKED
- **MR / PR ID:** `<iid>`
- **Peer Review / Sheldon Verdict:** `pending` (target: `./gate-review.sh sheldon <iid>`)
- **Review Freshness Check:** `pending` (target: `./gate-review.sh verify-freshness <record>`)
- **Human Final Verification:** `pending`
- **Merge & Land Command:** `pending` (target: `./gate-merge.sh merge <iid>`)

---

## Subagent / Worker Registry
| Name | Role | Pane / Session | Mode | Assigned Scope | Status | Closure Evidence |
|---|---|---|---|---|---|---|
| (example) Bob | Scout | %1 | readonly | docs/ | closed | Pane clean, findings recorded |

---

## External Prerequisites
- [ ] `<external blocker, credential, or API dependency>`

---

## Decisions & Open Loops
- **Decisions:**
  - `<YYYY-MM-DD>`: `<Decision text>` (Owner: `<name>`)
- **Open Loops:**
  - `[unverified]` `<open question or uncertainty>`

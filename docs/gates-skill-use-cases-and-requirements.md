# GATES Skill — Use Cases, LLM Triggers, & Requirements

This document captures the situational triggers, concrete use cases, and derived requirements for the **`gates-discipline`** skill, written from the direct operational perspective of an LLM agent operating inside a coding workspace.

---

## 1. The Core Purpose of the Skill

An LLM coding agent frequently suffers from:
1. **Premature implementation** (editing application code before requirements or architecture are grounded).
2. **Context and worktree drift** (working in the wrong branch, wrong directory, or detached HEAD).
3. **Failing at entry** (not knowing which companion skills to load or which write paths are permitted).
4. **Self-certification bias** (marking tasks done or merging without deterministic verification).

The `gates-discipline` skill exists to provide the **cognitive and behavioral operating manual** for the 4-Gate lifecycle, teaching the LLM when to stop, what to verify, and how to command the physical gate tools (`gate-check.sh`, `gate-review.sh`, `gate-merge.sh`).

---

## 2. LLM Situational Triggers (When to Consult the Skill)

An LLM must consult this skill in the following seven concrete situations:

### Scenario 1: Task Inception & Cold Start
* **Trigger:** The user assigns a new Jira issue, task name, feature request, or bug.
* **Why consult:** To learn how to anchor the workspace:
  - Run `./gate-check.sh --worktree <target>` to confirm directory grounding.
  - Instantiate `GATES_<task>.md` with the fenced `## Machine State` YAML block.
  - Initialize at `current_gate: 1` in `readonly` mode before modifying any files.

### Scenario 2: Before Delegating to a Subagent / Worker
* **Trigger:** The lead decides to split work, launch a worker pane (via Herdr, CMUX, or CLI), or run an asynchronous task.
* **Why consult:** To verify delegation constraints:
  - Run `./gate-check.sh --preflight <gate> <mode>` before opening a worker pane.
  - Enforce `launch directory = write scope` (e.g. spec directory at Gate 2, implementation directory at Gate 3).
  - Inject the identity chain (`Alice -> Bob`), required subagent skills, and explicit return path.

### Scenario 3: Approaching a Gate Boundary (Exit Verification)
* **Trigger:** An exploration phase is complete, a specification is drafted, or implementation tasks are marked done.
* **Why consult:** To learn the non-negotiable exit criteria:
  - Gate 1 Exit: Scope confirmed, research recorded in ledger.
  - Gate 2 Exit: `./gate-review.sh concept <doc>` exits `0` + explicit human go-ahead.
  - Gate 3 Exit: `./gate-review.sh diff HEAD` exits `0` (linters green, tests added) + proof summary presented.
  - Gate 4 Exit: External peer review passed + `./gate-merge.sh merge <iid>`.

### Scenario 4: Epistemic Firewall (Temptation to Code Early)
* **Trigger:** While researching or drafting a proposal, the LLM feels the urge to "just quickly test/edit an application file" or create prototypes in production directories.
* **Why consult:** Acts as an epistemic firewall reminding the agent:
  - *Gate 1 and Gate 2 are strictly read-only or spec-restricted.*
  - Touching application code at Gate 1 or 2 is a fatal process breach. Spikes must be isolated or conducted via read-only tools.

### Scenario 5: Disambiguating Terse User Input ("go", "ok", "proceed")
* **Trigger:** The human says "go", "looks good", "continue", or "proceed".
* **Why consult:** Terse human input must be mapped to the current gate state:
  - If at Gate 2: "go" authorises transitioning to Gate 3 (start TDD implementation) and unlocks editable mode.
  - If at Gate 3: "go" does NOT authorize merging to main; it triggers Gate 4 peer review.
  - If at Gate 4: "go" authorizes executing `./gate-merge.sh merge <iid>`.

### Scenario 6: Preparing for Merge & Cutover
* **Trigger:** All code tasks are done and the LLM is ready to deliver the work to `main`.
* **Why consult:** Prevents catastrophic unverified merges:
  - Agents are strictly forbidden from ticking `[User Verification]` or running manual `git merge`.
  - Must run `./gate-review.sh verify-freshness <record>` to catch rebase invalidations.
  - Must execute through `./gate-merge.sh merge <iid>` to guarantee ancestor continuity, remote verification, and in-flight file preservation.

### Scenario 7: Discovering a Specification Flaw During Coding (Gate Regression)
* **Trigger:** While coding at Gate 3, the LLM discovers that the architecture or requirements from Gate 2 are flawed, incomplete, or impossible.
* **Why consult:** To prevent hacking around the spec in code:
  - The canonical rule of deliberate regression: stop coding immediately.
  - Record a formal regression back to Gate 2 in `GATES_<task>.md`.
  - Update the specification, run `./gate-review.sh concept`, re-acquire human sign-off, and then return to Gate 3.

---

## 3. Derived Requirements for the `gates-discipline` Skill

Based on these triggers, the skill must satisfy the following architectural requirements:

### Requirement 1: Entry Contract + Exit Proof Structure (Phase Contracts)
Avoid creating 10 bureaucratic micro-steps. Keep the **4 Gates**, but define each gate with:
1. **Entry Protocol (Inputs):** Preconditions, permitted write paths, required mode (`readonly` vs `editable`), and mandatory companion skills to load (e.g. `openspec-explore`, `openspec-propose`, `openspec-apply-change`).
2. **Fluid Phase (Work):** Free iteration and problem-solving within the boundary.
3. **Exit Proof (Outputs):** Mechanical CLI verification (`gate-*.sh`) and explicit human confirmation.

### Requirement 2: Separation of Lifecycle from Execution Runner
The core skill must be engine-agnostic (working identically for solo agents, pair programming, or CI). It must provide an explicit **Runtime Binding** section:
- **Reference Binding (Herdr):** How to delegate via `sub-agent-herdr-supervisor` and `sub-agent-handoff`, enforcing `launch cwd = write scope` and mandatory pane cleanup.
- **Direct Binding (Solo Session):** How a single lead agent executes checks directly without worker panes.

### Requirement 3: Exact CLI Invocations (No Guessing)
The skill must document the exact commands to run at every gate:
- Preflight: `./gate-check.sh --preflight <gate> <mode>`
- Concept audit: `./gate-review.sh concept <file>`
- Implementation proof: `./gate-review.sh diff [range]`
- Freshness check: `./gate-review.sh verify-freshness <record>`
- Atomic merge: `./gate-merge.sh merge <iid>`

### Requirement 4: Living Ledger Contract (`GATES_<task>.md`)
The skill must teach the agent how to read and maintain the `## Machine State` YAML block so that `gate-check.sh` can always parse the ground truth.

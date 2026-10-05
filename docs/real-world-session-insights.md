# Real-World Pi Session Analysis & Friction Patterns

**Source Corpus:** Past high-volume sessions across `daily-workflow-helper*` workspaces:
- `daily-workflow-helper/session_sep02_16M.md`: Dashboard & InfoHub redesign (~1049 user turns).
- `daily-workflow-helper/session_investigate.md`: Multi-agent redesign review, MR !45 & !46, branch surgery.
- `daily-workflow-helper-openspec-hygiene/session_hygiene.md`: Directory cleanup, audit script creation, MR !46 cutover.

---

## 1. Top Recurring Friction Patterns

### A. The 10-Line Manual Cutover & Merge Ritual
* **Observed Reality**: The user had to hand-compose and paste a 6–10 line numbered checklist to authorize every merge (~5 times across sessions):
  > `(1) git fetch smec-origin main; (2) check merge-base --is-ancestor; (3) run ./precommit.sh; (4) run ./openspec-audit.sh; (5) glab mr update --ready-for-review; (6) glab mr merge --squash --remove-source-branch; (7) verify squash SHA; (8) check in-flight uncommitted files survived intact.`
* **Failure Risk**: In one session, remote `main` moved during work, invalidating a prior review and requiring manual rebase + re-verification before merge could proceed.

### B. Premature Implementation & Missing Deliberation
* **Observed Reality**: The user repeatedly had to stop agents from jumping straight into code before the spec/design was agreed upon:
  - *"NO ONE SAID ANYTHING ABOUT IMPLEMENTING YET"*
  - *"update OpenSpec artifacts first then implement"* (repeated multiple times).
* **Cross-workstream Contamination**: In the investigate session, a hygiene commit (`cdf1cb7`) was accidentally stacked underneath another agent's 5 implementation commits, requiring complex git surgery (cherry-picks, reflog recovery, force-push).

### C. Review Verdict Staleness & Reviewer Friction
* **The `@ai-sheldon` Loop**: Every MR required re-inventing the same polling sequence: post note $\rightarrow$ wait 60s $\rightarrow$ poll every 10s $\rightarrow$ reconcile in same thread.
* **Verdict Staleness**: When a branch was rebased onto `main`, the commit SHA changed. The user had to intervene: *"re-confirm Sheldon on the NEW head... the prior PASS was for the old head."*

### D. Worktree Drift & Anchor Confusion
* **Observed Reality**: In multi-worktree setups, agents frequently lost context on *which* worktree they were operating in (e.g. running commands in `daily-workflow-helper` instead of `daily-workflow-helper-openspec-hygiene`), requiring several user turns to re-anchor.

---

## 2. Direct Architectural Requirements for the Toolkit

Based on these real-world failure modes, the quality helpers must enforce:

| Tool | Real-World Failure Mode | Concrete Requirement |
|---|---|---|
| **`safe-merge.sh`** | Brittle 10-line prompt; lost in-flight files. | 1. Auto-ancestor check with remote `main`.<br>2. Support `--inflight <paths...>` to verify concurrent files survived.<br>3. Fail-fast with zero git mutation if diverged. |
| **`gate-check.sh`** | *"No one said anything about implementing yet"* (Premature Gate 3 jump). | 1. `work_gate == ledger.current_gate` check.<br>2. Block `editable` worker launches unless Gate 2 has recorded human go-ahead.<br>3. Worktree anchor check (`git rev-parse --show-toplevel`). |
| **`review-gate.sh`** | Verdict staleness after rebase; manual Sheldon polling. | 1. Record HEAD commit SHA alongside review verdicts.<br>2. Invalidate review if branch HEAD diverges from reviewed SHA.<br>3. Automated, bounded Sheldon thread interaction. |

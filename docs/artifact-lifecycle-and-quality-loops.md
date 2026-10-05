# Recursive Artifact Lifecycle & Quality Gates

## Context & Intent

Software delivery frameworks (such as OpenSpec, PR reviews, and TDD) often get entangled with specific directory conventions, tooling names, or file formats.

The underlying mechanism that makes these systems work is not the tool or format, but an **iterative, evidence-grounded quality loop**. Each loop advances a work stream by refining an ambiguous question into concrete, audited artifacts.

Whether producing an initial problem statement, an architecture diagram, a formal spec, a test suite, or production code, the loop structure remains invariant.

---

## The 4-Stage Universal Loop

Every artifact or bundle of artifacts undergoes a 4-phase transformation:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       THE UNIVERSAL ARTIFACT LOOP                       │
├────────────────────┬───────────────────┬────────────────┬───────────────┤
│ 1. DEFINE & SCOPE  │ 2. EXPLORE        │ 3. DERIVE      │ 4. AUDIT &    │
│                    │                   │    ARTIFACT    │    CROSSCHECK │
├────────────────────┼───────────────────┼────────────────┼───────────────┤
│ • What must be     │ • Codebase & data │ • Synthesize   │ • Evidence-to-│
│   answered or      │   investigation   │   new artifact │   claim audit │
│   built?           │ • Live probes     │   (notes, spec,│ • Review gate │
│ • Explicit bounds  │ • User/transcript │   tests, code, │ • Grounding   │
│   and assumptions  │   grounding       │   diagrams)    │   verification│
└────────────────────┴───────────────────┴────────────────┴───────────────┘
```

### Stage 1: Define & Scope
* **Objective:** Define what needs to be found out or created (new feature idea, bug reproduction, architectural spike, refactoring constraint).
* **Boundary:** State explicitly what is out of scope and identify known constraints before searching.

### Stage 2: Explore
* **Objective:** Gather evidence without committing to a solution.
* **Activities:** Code search, reading existing runtime implementations, reproducing issues, probing APIs, inspecting logs or meeting transcripts.
* **Discipline:** Observe first. Avoid jumping directly to conclusion or code edits.

### Stage 3: Derive Artifact
* **Objective:** Transform gathered facts into a concrete, scoped output.
* **Form Agnostic:** The artifact can take any appropriate form:
  - Text exploration note or decision brief.
  - Architecture/data-flow diagram (`.d2`, `.svg`).
  - Spec requirement or functional contract.
  - Failing test suite (TDD specification).
  - Implementation code diff.

### Stage 4: Audit & Crosscheck (Review Gate)
* **Objective:** Validate fidelity before declaring the loop complete.
* **Crosscheck Protocol (inspired by `meeting-summary` & code review):**
  - **Evidence before Fluency:** Is every claim in the artifact traceable to verified code/data/transcripts, or is it an invented assumption?
  - **Discrepancy Check:** Does the new artifact introduce drift or contradictions against existing upstream baseline artifacts?
  - **Independent Review:** Mechanical checks (linters, precommit, tests) combined with targeted AI reviewer passes (`cg-task.sh`, peer bots, diff review).

---

## Cascading Iterations Across the Lifecycle

Quality emerges because each stage's *audited artifact* becomes the *source truth* for the next loop:

```
[Loop 1: Problem / Concept]
   Define Question ➔ Explore Code/Domain ➔ Derive Concept Brief ➔ Crosscheck & Review
                                                                         │ (approved)
                                                                         ▼
[Loop 2: Specification / Contract]
   Define Scope ➔ Explore System Invariants ➔ Derive Spec/Diagram ➔ Crosscheck vs Concept
                                                                         │ (approved)
                                                                         ▼
[Loop 3: Test / Behavior Harness]
   Define Acceptance ➔ Explore Edge Cases ➔ Derive Executable Tests ➔ Verify Failure
                                                                         │ (green harness)
                                                                         ▼
[Loop 4: Implementation]
   Define Minimal Diff ➔ Code ➔ Derive Working Solution ➔ Crosscheck vs Tests & Spec
```

---

## Tooling & Automation Interface (`review.sh` concept)

Rather than tying workflows strictly to specific tool names (e.g. OpenSpec vs. non-OpenSpec), quality gates can be mechanically invoked per phase:

```bash
# 1. Concept / Exploration phase check
./review.sh --concept       # Audits concept notes, checks for unsupported claims & scope bounds

# 2. Spec / Architecture phase check
./review.sh --spec          # Discrepancy-checks spec against upstream concept & repo architecture

# 3. Code / Diff phase check
./review.sh --diff          # Deterministic precommit + AI diff review against approved spec

# 4. Peer Review / Gate handoff
./review.sh --peer          # Pre-flight check (pushed state) + trigger external reviewer / bot
```

## Key Invariants

1. **Format independence:** File formats and directory locations can change; the requirement to ground claims and audit artifacts before advancing remains permanent.
2. **Never promote unverified claims:** Unaudited outputs remain hypotheses. They are only elevated to source truth once they pass Stage 4 crosschecking.

# Review Gate Contracts & Machine-Readable Output

## Purpose

`gate-review.sh` provides a predictable, phase-aligned quality harness for software development and knowledge work. It is designed to be invoked both interactively by humans and programmatically by primary agents or delegated subagents.

---

## 1. Supported Review Modes & Invariants

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            GATE-REVIEW PHASES                               │
├────────────────────┬───────────────────┬───────────────────┬────────────────┤
│ concept            │ diff              │ grounding         │ peer           │
├────────────────────┼───────────────────┼───────────────────┼────────────────┤
│ Target: Proposal / │ Target: Git range │ Target: Research  │ Target: Active │
│ Concept Markdown   │ or working diff   │ or meeting notes  │ feature branch │
│                    │                   │                   │                │
│ Checks:            │ Checks:           │ Checks:           │ Checks:        │
│ • Scope bounds     │ • Deterministic   │ • Grounded claims │ • No main push │
│ • Explicit non-    │   linters/tests   │ • Superlative &   │ • Unpushed     │
│   goals            │ • TDD test change │   hallucination   │   commit count │
│ • Epistemic markers│   presence        │   checks          │ • Clean tree   │
│   ([unverified])   │ • AI diff review  │ • Evidence trace  │ • Handoff note │
└────────────────────┴───────────────────┴───────────────────┴────────────────┘
```

---

## 2. Invocation Contract

```bash
# Concept Gate (Pre-Implementation)
./gate-review.sh concept [path/to/proposal.md] [--strict] [--json]

# Implementation Gate (TDD & Diff Verification)
./gate-review.sh diff [git-revision-range] [--strict] [--json]

# Grounding Gate (Knowledge & Synthesis Verification)
./gate-review.sh grounding <path/to/artifact.md> [--strict] [--json]

# Peer Handoff Gate (External Reviewer & Branch Hygiene)
./gate-review.sh peer [--strict] [--json]

# Automated Peer Bot Interaction
./gate-review.sh sheldon <mr-iid>

# Verdict Freshness Verification (Catches Rebase Invalidation)
./gate-review.sh verify-freshness <path/to/record.md>
```

*(Note: Modes also accept leading `--`, e.g. `--concept`, `--diff`.)*

---

## 3. Exit Code Semantics

| Exit Code | Meaning | Agent Action |
|---|---|---|
| **`0`** | **PASS** | Authorized to proceed to the next step. |
| **`1`** | **BLOCK** | Do NOT proceed. Address failing gate criteria. |
| **`2`** | **USAGE / CONFIG ERROR** | Missing required files, invalid arguments, or not inside git repository. |

---

## 4. Machine-Readable Summary Standard

When invoked with `--json`, `gate-review.sh` outputs a deterministic, unescaped JSON verdict payload suitable for supervisor or subagent parsing:

```json
{
  "mode": "concept",
  "verdict": "PASS",
  "target": "docs/artifact-lifecycle-and-quality-loops.md",
  "head_sha": "50ab88371196302fc9ce962401bb97ecadb4d9ba",
  "timestamp": "2026-09-22T12:40:52Z"
}
```

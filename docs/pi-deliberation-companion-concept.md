# `pi-deliberation-companion` — Concept Specification

**Status:** Gate-2 conceptual artifact; reviewed as a portable, skills-first direction.
**Purpose:** Define the reusable deliberation contract for the future Pi package before package scaffolding or native-tool implementation begins.

## 1. Promise and non-goals

### Promise

`pi-deliberation-companion` helps people and agents conduct quality, thoughtful, aware work by:

1. understanding the current situation from evidence;
2. deliberately deriving the next appropriate artifact or action;
3. recording the evidence and required human decisions that justify a transition; and
4. stopping rather than silently advancing when that justification is absent.

It applies to delivery, investigation, planning, operations, writing, research, and decisions—not only software development.

### Non-goals

The package is **not** a delivery platform, approval authority, merge tool, task tracker, or universal enforcement engine. It does not replace a consuming project's `AGENTS.md`, `GATES.md`, issue tracker, artifact system, or human judgment.

OpenSpec, Herdr, GitLab, Jira, Linear, shell helpers, tests, CI, and review bots are possible integrations. None is part of the universal contract.

## 2. Decision legend

- **Invariant** — a condition the companion must not weaken.
- **Working Decision** — the current package direction, revisable only through recorded deliberation.
- **Recommendation** — evidence-backed guidance a consuming project may adapt.
- **Deferred** — intentionally unresolved; it must not be silently implemented as a default.

## 3. Universal deliberation contract

### 3.1 Core invariant

> **Phases are fluid; gates are binding.**

**Invariant.** A gate passes on recorded, inspectable evidence and required human confirmation—not self-report. Work may iterate freely within a gate, but later-gate work must not begin until the current gate's exit conditions are met and recorded.

**Invariant.** A gate contract is semantic and remains binding whether or not a project installs mechanical enforcement. Tooling can strengthen a contract; it does not create the underlying obligation.

### 3.2 Four semantic gates

The package carries the following portable meanings. A consuming project may use different names, artifacts, and mechanics if it preserves the meaning and authority boundaries.

| Gate | Portable purpose | Minimum exit evidence | Human boundary |
|---|---|---|---|
| 1 — Explore | Establish the current state, scope, constraints, and explicit non-goals. | A fact pack or research record, plus scope and non-goals in the ledger. | Scope/non-goals confirmed before concept work begins. |
| 2 — Concept | Deliberate the proposed next change or action: bounds, alternatives, risks, and verification approach. | A concept/specification artifact; explicit bounds and non-goals; uncertainties and rejected alternatives recorded. | Explicit go-ahead before implementation or other consequential execution. |
| 3 — Execute and verify | Perform the approved bounded work and establish that it meets its stated criteria. | Domain-appropriate verification and an evidence-backed proof summary. | Present proof and **stop**; agents do not self-sign-off or self-land outcomes. |
| 4 — Handoff and acceptance | Independently review the result and place it under the human's acceptance decision. | Review evidence and a human handoff/acceptance record. | Human acceptance is the universal completion point. Verified landing, deployment, publishing, or merge is a project-specific adapter concern. |

**Working Decision.** Gate 3 verification is domain-appropriate: tests and TDD are strong software examples, but research may use reproducible probes, operations may use observed run evidence, and a decision may use a reviewable rationale. The invariant is verified, evidence-backed progress—not a named test framework.

**Invariant.** Every gate-pass claim must point to evidence a human can inspect without relying on an agent's assertion. The ledger stores a pointer or reference, not an unreviewable copied claim.

### 3.3 Work modes and bounded writes

**Invariant.** The semantic boundaries are: exploration is read-only; concept work is limited to approved planning artifacts; execution uses the narrowest declared write scope; final acceptance remains human-governed.

**Working Decision.** A worker's write scope must be explicitly declared and bounded. Runtime mechanisms such as Pi/Herdr cwd pinning, sandboxes, or repository allowlists may help enforce it, but none is a universal guarantee or package requirement.

## 4. Authority, stops, and regression

**Invariant.** The consuming project's governance artifacts are authoritative. Where `AGENTS.md`, project-level `GATES.md`, or an accepted project policy conflicts with companion defaults, project policy wins. The companion reports the conflict; it does not select a permissive interpretation.

**Invariant.** On missing evidence, scope expansion, a conflicting policy, or a material contradiction:

> **Stop. Change nothing. Escalate. Do not proceed on assumed policy or route around the conflict.**

The consuming project decides which artifact or gate must be reopened.

**Invariant.** A discovered requirement or architectural invalidation triggers deliberate regression: record the reason and reopened gate in the ledger, amend the affected artifact, re-establish the required evidence, and re-acquire any required human confirmation before resuming.

**Recommendation.** For consequential decisions, use a judgment pair: Firstmate forms an evidence-backed view; Secondmate independently challenges assumptions, gaps, and premature conclusions; Firstmate records the reconciliation as **Adopted**, **Contested**, **Deferred**, or **No Contribution**. This supports, but never replaces, the human's authority.

## 5. Ledger contract

**Invariant.** Every task using the discipline has a durable, discoverable, human-maintained ledger. It records at least: current or completed gate state, evidence references, relevant timestamps, decisions, and required human go-aheads. It is the durable basis for "evidence, not self-report."

**Working Decision.** Ledger location and schema are project-defined. Markdown, frontmatter, OpenSpec artifacts, Jira, Linear, or another project-native system may carry the record if it remains durable, discoverable, and reviewable. A repository-root `GATES_<task>.md`, a fenced YAML `## Machine State` block, and a four-gate `current_gate` field are valid adapter choices, not universal requirements.

**Deferred.** Whether the package should recommend a minimal machine-readable subset for projects that want automation remains open. It must not be inferred from the existing YAML-based helper scripts.

## 6. Skills-first topology

**Invariant.** Skills are the package's primary runtime surface. They convey deliberation behavior, gate-specific judgment, evidence expectations, escalation duties, and the distinction between support and authority.

**Working Decision.** The minimal bundled skill set should cover:

1. **Deliberation discipline** — the universal gate meanings, evidence and ledger duties, regression, and stop rule.
2. **Lead/controller practice** — outcome ownership, bounded delegation, judgment-pair reconciliation, and independent acceptance.

**Recommendation.** Keep the required set this small. Skills for OpenSpec, Herdr, GitLab/MR workflows, Sheldon, or other ecosystems should be optional adapters selected by the consuming project.

**Deferred.** Exact skill names, package precedence/collision behavior, and the adapter skill catalogue require a later package-layout decision.

## 7. Adapters and native tools

### 7.1 Adapter boundary

**Invariant.** Adapters are optional, project-specific, and consumer-owned. They may integrate the discipline with a chosen artifact system or runtime, but they cannot redefine the universal authority boundaries.

**Working Decision.** `gate-check.sh`, `gate-review.sh`, and `gate-merge.sh` from `agent-quality-helpers` are optional delivery-specific examples/adapters—not package prerequisites or universal bundled mechanics. Their YAML/four-gate, shell, GitLab, MR, and merge assumptions are not portable defaults.

**Invariant.** An adapter must either perform its declared check or clearly report that a required dependency is absent. It must not silently claim equivalent assurance after skipping a required check.

### 7.2 Native ReAct tool rule

**Invariant.** No native ReAct tool is added merely to wrap a shell command, make a checklist look authoritative, or create a second control plane.

A proposed tool must document why all four answers are **no**:

1. Does it duplicate a skill, existing script, or ordinary agent capability?
2. Does it invent, simulate, or overstate evidence?
3. Does it grant authority or infer consent without recorded human confirmation?
4. Does it compete with the project's ledger or governance as the apparent source of truth?

**Working Decision.** If a tool is later justified, its default shape is a constrained, read-only fact surface: it reports observed state and cannot merge, approve, write policy, or advance a gate.

**Deferred.** A portable ledger-state reader is only a candidate. It requires demonstrated friction that skills and project-provided mechanics cannot address safely.

## 8. Adoption and operation flow

1. A project retains or establishes its own governance and ledger location.
2. The package's skills help the human and agents interpret the project context, make evidence needs explicit, and derive the next justified action.
3. The project optionally connects adapters for its own tools and platforms.
4. At each gate boundary, the responsible lead verifies the recorded evidence and required human decision before later-gate work starts.
5. On uncertainty or conflict, work stops and returns to the project's authority process rather than inventing a shortcut.

**Working Decision.** This flow is runtime-neutral: a person working alone, a direct Pi session, or a Pi/Herdr controller-led team may use it. Specific pane lifecycle, cwd, sandbox, and write-guard mechanisms belong to runtime adapters.

## 9. Open questions and explicit non-decisions

- **Deferred:** whether to recommend a minimal machine-readable ledger subset.
- **Deferred:** the exact names and precedence behavior of bundled and adapter skills.
- **Deferred:** whether optional adapter examples live in the package or are linked externally.
- **Deferred:** a concrete native-tool proposal; no tool is authorized by this concept.
- **Deferred:** a canonical regression wording for the future in-package `GATES.md`; it must preserve deliberate reopening and re-acquired human confirmation without binding users to YAML or a repository root.

## 10. Concept acceptance criteria

This concept is ready to guide a package proposal only if reviewers can confirm that it:

- does not require a Git repository, OpenSpec, Herdr, GitLab, Jira, Linear, shell tooling, TDD, or a fixed ledger schema; any references to delivery scripts are non-normative examples only;
- preserves evidence-led gates, human authority, durable ledger records, and deliberate regression;
- separates semantic boundaries from optional enforcement mechanics;
- keeps skills primary and native tools deferred unless justified by evidence; and
- leaves consuming-project governance authoritative.

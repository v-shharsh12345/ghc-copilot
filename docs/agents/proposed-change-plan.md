# Proposed Change Plan for Agent System

## Objective

Move to a scalable, orchestrator-first architecture with clear specialist boundaries, repeatable workflows, and quality guardrails.

## Target State

- One orchestrator agent (`orchestrator`)
- Two active specialist subagents:
  - `chief-of-staff`
  - `fabric-devops`
- Semantic model testing handled as a repeatable workflow under `fabric-devops`
- `semantic-model-comparator` retained only as deprecated compatibility shim

## Why This Change

- Eliminates overlapping responsibilities between Fabric engineering and Fabric testing
- Improves consistency with custom-agent best practices (coordinator + workers)
- Reduces tool sprawl by enforcing least-privilege tool scopes
- Makes adding future agents easier (clear routing contracts)

## Phase Plan

### Phase 1: Architecture and Routing (Completed)

- Add orchestrator agent with explicit delegation policy
- Refactor specialist agents as orchestrator-managed subagents
- Add semantic model testing module to Fabric skill routing

### Phase 2: Workflow Consolidation (Completed)

- Integrate semantic comparison route into `fabric-devops`
- Keep compare-semantic-models assets as reusable references
- Mark semantic standalone agent as deprecated

### Phase 3: Governance and Quality (Next)

- Add hook-based guardrails for risky tool usage and end-of-run validation
- Introduce eval datasets for:
  - intent routing accuracy
  - workflow output quality
  - regression checks per agent update
- Add release checklist for agent/skill changes

### Phase 4: Scale-Out Pattern (Next)

- Define template for new specialist agents:
  - minimal tools
  - clear mission boundary
  - deterministic routing triggers
- Add onboarding doc for adding new skills and binding them to routes

## Quality Criteria

1. **Intent Clarity**: every request maps to a single preferred subagent.
2. **Tool Discipline**: each subagent has only tools required for its role.
3. **Workflow Reuse**: repeatable procedures are implemented as skills/modules, not duplicated across agents.
4. **Backward Compatibility**: legacy entrypoints remain available with migration guidance.
5. **Auditability**: outputs include route, actions, findings, and next step.

# Orchestrator Agent

> **File:** `.github/agents/orchestrator.agent.md`
> **Version:** 1.3 (Feb 2026)

## Overview

The **Orchestrator** is the single entrypoint for this repository's agent system. It delegates work to specialist subagents and returns a unified result.

## Delegation Model

| Intent Domain | Subagent |
| --- | --- |
| PM operations, M365 triage, ADO work-item management, communications | `chief-of-staff` |
| Fabric development, operations, diagnostics, release, semantic model testing | `fabric-devops` |

## Fabric DevOps Skill Handoffs

The orchestrator provides direct handoff labels for each Fabric capability skill:

| Label | Skill Activated |
| --- | --- |
| Fabric — Develop | `fabric-devops-develop` |
| Fabric — Monitor | `fabric-devops-operate-monitor` |
| Fabric — Lakehouse Diagnostics | `fabric-devops-lakehouse-diagnostics` |
| Fabric — Validate | `fabric-devops-validate` |
| Fabric — Semantic Model Testing | `fabric-devops-semantic-model-testing` |
| Fabric — Lineage | `fabric-devops-analyze-lineage` |
| Fabric — Promote | `fabric-devops-release-promote` |

## Multi-Agent Behavior

- Uses coordinator/worker pattern
- Runs subagents in parallel when tasks are independent
- Synthesizes one final answer with outcomes, risks, and next actions
- The `fabric-devops` agent resolves which capability skill to activate based on each skill's self-declared intent triggers

## Why This Structure

- Reduces context bloat in specialist agents
- Skills are focused, structured, and deterministic
- Each skill declares its own intent — no centralized routing bottleneck
- Makes tool governance easier by enforcing least-privilege toolsets per subagent

## Related Files

- `.github/agents/chief-of-staff.agent.md`
- `.github/agents/fabric-devops.agent.md`
- `.github/skills/fabric-devops/SKILL.md`
- `.github/skills/fabric-devops-*/SKILL.md`

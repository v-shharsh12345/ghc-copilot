# Orchestrator Agent

> **File:** `.github/agents/orchestrator.agent.md`
> **Version:** 1.0 (Feb 2026)

## Overview

The **Orchestrator** is the single entrypoint for this repository's agent system. It delegates work to specialist subagents and returns a unified result.

## Delegation Model

| Intent Domain | Subagent |
| --- | --- |
| PM operations, M365 triage, ADO work-item management, communications | `chief-of-staff` |
| Fabric development, operations, diagnostics, release, semantic model testing | `fabric-devops` |

## Multi-Agent Behavior

- Uses coordinator/worker pattern
- Runs subagents in parallel when tasks are independent
- Synthesizes one final answer with outcomes, risks, and next actions

## Why This Structure

- Reduces context bloat in specialist agents
- Improves role clarity and scalability
- Makes tool governance easier by enforcing least-privilege toolsets per subagent

## Related Files

- `.github/agents/chief-of-staff.agent.md`
- `.github/agents/fabric-devops.agent.md`
- `.github/skills/fabric-devops/modules/semantic-model-testing.md`

<!--
This is the canonical constitution location referenced by Spec Kit phases
(/speckit.specify, /speckit.plan, /speckit.tasks, /speckit.checklist,
/speckit.analyze, /speckit.implement) and by the Constitution Check gate
in the plan-template.

The authoritative source is the repo root constitution.md. This file is
kept byte-identical so Spec Kit's lookup at .specify/memory/constitution.md
resolves correctly without requiring a symlink (which doesn't survive on
Windows + Azure DevOps Git on all clients).

If you edit one, edit BOTH in the same PR.
  - Root:   constitution.md
  - Mirror: .specify/memory/constitution.md
The PR checklist (checklist-template.md) enforces this.
-->

# MSSales Platform Constitution — Mirror

> **See `constitution.md` at the repo root for the authoritative version.**
> Version: 1.2.0 · Ratified: 2026-05-26 · Last Amended: 2026-05-29

The canonical text lives at [`/constitution.md`](../../constitution.md).
This mirror exists so Spec Kit's default `.specify/memory/constitution.md`
lookup resolves without modification. Keep the two in sync on every
amendment (see the **Amendment procedure** section of the authoritative
file).

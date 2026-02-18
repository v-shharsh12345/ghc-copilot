# Capability Matrix

## Route Coverage

| Lifecycle Event | Preferred Route | Secondary Route | Guidance Fallback |
| --- | --- | --- | --- |
| Create/Update notebooks and pipelines | Fabric API | Fabric CLI | Context7 |
| Workspace inventory and status checks | Fabric API | Fabric CLI | Context7 |
| Inventory export and automation-heavy ops | Fabric CLI | Fabric API | Context7 |
| Lakehouse dependency and load diagnostics | Fabric API | Fabric SemPy | Context7 |
| Semantic model and metric parity validation | Fabric SemPy | Fabric API | Context7 |
| Report definition comparison | Fabric API | Fabric SemPy | Context7 |
| Data lineage analysis (table/column/report) | Fabric SemPy | Fabric API | Context7 |
| Heavy metadata generation (PBIR + semantic model objects) | Fabric SemPy (semantic-link-labs) | Fabric API | Context7 |
| Deployment promotion workflows | Fabric API | Fabric CLI | Context7 |

## Engine Notes

- **Fabric API**: Best default for direct control-plane operations.
- **Fabric CLI**: Best for repeatable scripted flows and CI/CD command workflows.
- **Fabric SemPy**: Best for semantic model analysis, metrics, notebook-driven validation, and semantic-link-labs metadata extraction.
- **Context7**: Use for implementation guidance when action engines are unavailable or uncertain.

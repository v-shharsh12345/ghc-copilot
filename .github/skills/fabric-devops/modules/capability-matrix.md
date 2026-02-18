# Capability Matrix

## Route Coverage

| Lifecycle Event | Primary Skill | Preferred Route | Secondary Route | Guidance Fallback |
| --- | --- | --- | --- | --- |
| Create/Update notebooks and pipelines | fabric-devops-develop | Fabric API | Fabric CLI | Context7 |
| Workspace inventory and status checks | fabric-devops-operate-monitor | Fabric API | Fabric CLI | Context7 |
| Inventory export and automation-heavy ops | fabric-devops-operate-monitor | Fabric CLI | Fabric API | Context7 |
| Lakehouse dependency and load diagnostics | fabric-devops-lakehouse-diagnostics | Fabric API | Fabric SemPy | Context7 |
| Semantic model and metric parity validation | fabric-devops-validate | Fabric SemPy | Fabric API | Context7 |
| Semantic model testing (schema/row count/metrics/freshness) | fabric-devops-semantic-model-testing | Power BI Remote | Fabric SemPy | Context7 |
| Report definition comparison | fabric-devops-validate | Fabric API | Fabric SemPy | Context7 |
| Data lineage analysis (table/column/report) | fabric-devops-analyze-lineage | Fabric SemPy | Fabric API | Context7 |
| Heavy metadata generation (PBIR + semantic model objects) | fabric-devops-analyze-lineage | Fabric SemPy (semantic-link-labs) | Fabric API | Context7 |
| Deployment promotion workflows | fabric-devops-release-promote | Fabric API | Fabric CLI | Context7 |

## Engine Notes

- **Fabric API**: Best default for direct control-plane operations.
- **Fabric CLI**: Best for repeatable scripted flows and CI/CD command workflows.
- **Fabric SemPy**: Best for semantic model analysis, metrics, notebook-driven validation, and semantic-link-labs metadata extraction.
- **Context7**: Use for implementation guidance when action engines are unavailable or uncertain.

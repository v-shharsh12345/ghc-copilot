# Chief of Staff 2.0 — Agent Architecture

## System Overview

```mermaid
flowchart LR
    subgraph SRC["📡 M365 DATA SOURCES"]
        direction TB
        MAIL["📧 Outlook"]
        TEAMS["💬 Teams"]
        CAL["📅 Calendar"]
        ADO["🔧 ADO"]
        M365["🔍 M365 Search"]
        PBI["📊 Power BI"]
    end

    subgraph FILTER["🎯 PRIORITY FILTER"]
        direction TB
        F1["ABS AI Pod\n+ EASA Projects"]
        F2["10 Key\nStakeholders"]
        F3["Non-Blocking\nRule"]
    end

    subgraph ENGINE["🧠 INTELLIGENCE ENGINE"]
        direction TB
        E1["① Triage\n& Ingest"]
        E2["② Connect\nthe Dots"]
        E3["③ Extract &\nSynthesize"]
        E4["④ Format &\nDeliver"]
        E1 --> E2 --> E3 --> E4
    end

    subgraph OUT["📤 OUTPUTS"]
        direction TB
        O1["☀️ Morning Pack"]
        O2["📝 Status Email"]
        O3["🤝 Meeting Prep"]
        O4["🔄 Delta Summary"]
        O5["✉️ Comms Drafts"]
    end

    SRC --> FILTER --> ENGINE --> OUT

    classDef src fill:#1a1a2e,stroke:#0078d4,stroke-width:2px,color:#fff
    classDef flt fill:#16213e,stroke:#f5a623,stroke-width:2px,color:#fff
    classDef eng fill:#0f3460,stroke:#00d2ff,stroke-width:2px,color:#fff
    classDef out fill:#1a1a2e,stroke:#00c853,stroke-width:2px,color:#fff

    class MAIL,TEAMS,CAL,ADO,M365,PBI src
    class F1,F2,F3 flt
    class E1,E2,E3,E4 eng
    class O1,O2,O3,O4,O5 out
```

## Detailed Intelligence Pipeline

```mermaid
flowchart TB
    subgraph INGEST["① TRIAGE & INGEST"]
        direction LR
        I1["Pull last 12-24h signals"]
        I2["Rank by priority hierarchy"]
        I3["Filter noise"]
        I1 --> I2 --> I3
    end

    subgraph XREF["② CONNECT THE DOTS"]
        direction LR
        X1["Mail ↔ Teams"]
        X2["ADO ↔ Calendar"]
        X3["Detect discrepancies"]
        X1 --> X3
        X2 --> X3
    end

    subgraph SYNTH["③ EXTRACT & SYNTHESIZE"]
        direction LR
        S1["Decisions"]
        S2["Action Items"]
        S3["Risks & Blockers"]
        S4["Dependencies"]
    end

    subgraph DELIVER["④ FORMAT & DELIVER"]
        direction LR
        D1["Match template"]
        D2["Apply standards"]
        D3["Label assumptions"]
        D1 --> D2 --> D3
    end

    INGEST --> XREF --> SYNTH --> DELIVER

    classDef stage fill:#0f3460,stroke:#00d2ff,stroke-width:2px,color:#fff
    class I1,I2,I3,X1,X2,X3,S1,S2,S3,S4,D1,D2,D3 stage
```

## Tracking & Feedback Loop

```mermaid
flowchart LR
    ENGINE["🧠 Intelligence\nEngine"] --> OUT["📤 Outputs"]
    ENGINE --> TRACK["📋 Tracking"]

    subgraph TRACK_DETAIL["📋 PERSISTENT TRACKING"]
        direction TB
        A["Action Register\nTask · Owner · Due · Status"]
        R["Risk/Issue Log\nSeverity · Impact · Mitigation"]
    end

    TRACK --> TRACK_DETAIL
    OUT -. "User corrections" .-> ENGINE
    TRACK_DETAIL -. "Weekly review" .-> ENGINE

    classDef eng fill:#0f3460,stroke:#00d2ff,stroke-width:2px,color:#fff
    classDef out fill:#1a1a2e,stroke:#00c853,stroke-width:2px,color:#fff
    classDef trk fill:#1a1a2e,stroke:#ff6f61,stroke-width:2px,color:#fff

    class ENGINE eng
    class OUT out
    class A,R,TRACK trk
```

---

## Architecture Summary

| Layer | Role | Key Behavior |
|-------|------|-------------|
| **Data Sources** | Raw signal ingestion from 6 M365 tool categories | Mail, Teams, Calendar, ADO, M365 Search, Power BI |
| **Priority Filter** | Focus lens — only high-value signals pass | 2 projects + 10 stakeholders + non-blocking rule |
| **Intelligence Engine** | 4-stage pipeline: Triage → Connect → Extract → Format | Cross-references sources, detects discrepancies, evidence-links claims |
| **Outputs** | Ready-to-use deliverables | Morning Pack, Status Mail, Meeting Prep/MoM, Delta Summaries, Drafts |
| **Tracking** | Persistent registers for actions & risks | Action Register + Risk/Issue Log with weekly review loop |

### Data Flow

1. **Ingest** — Tools pull last 12-24h signals from Outlook, Teams, Calendar, ADO, M365 Search, Power BI
2. **Filter** — Priority hierarchy: key chats → project channels → ADO items → stakeholder emails
3. **Connect** — Cross-reference engine links mail ↔ Teams ↔ ADO ↔ meeting outcomes
4. **Extract** — Decisions, action items, risks, dependencies pulled with evidence citations
5. **Format** — Output shaped to template (status mail, morning pack, MoM, etc.)
6. **Deliver** — Copy-paste-ready output; feedback loop refines next iteration

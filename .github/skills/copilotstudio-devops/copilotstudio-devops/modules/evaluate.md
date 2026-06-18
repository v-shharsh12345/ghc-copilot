# Evaluate — Procedure Module

## Overview

This module defines the canonical procedure for evaluating Copilot Studio agents programmatically. Two execution paths are supported: **Semantic Kernel CopilotStudioAgent** (recommended) and **Direct Line API** (for performance testing).

---

## Path 1: Semantic Kernel CopilotStudioAgent (Primary)

### Prerequisites Check

```bash
pip install semantic-kernel[copilotstudio]
```

Verify environment variables are set:
```
COPILOT_STUDIO_AGENT_APP_CLIENT_ID
COPILOT_STUDIO_AGENT_TENANT_ID
COPILOT_STUDIO_AGENT_ENVIRONMENT_ID
COPILOT_STUDIO_AGENT_AGENT_IDENTIFIER
COPILOT_STUDIO_AGENT_AUTH_MODE=interactive
```

### Step 1: Create Evaluation Script

Generate a Python script that:

```python
import asyncio
import time
import json
from semantic_kernel.agents import CopilotStudioAgent, CopilotStudioAgentThread

async def evaluate_agent(test_cases: list[dict]) -> list[dict]:
    """
    test_cases: [{"utterance": "...", "expected_topic": "...", "expected_pattern": "..."}]
    """
    agent = CopilotStudioAgent(
        name="EvalAgent",
        instructions="You are being evaluated. Respond naturally.",
    )

    results = []
    thread: CopilotStudioAgentThread | None = None

    for i, tc in enumerate(test_cases):
        start = time.time()
        response = await agent.get_response(messages=tc["utterance"], thread=thread)
        latency_ms = (time.time() - start) * 1000

        result = {
            "index": i,
            "utterance": tc["utterance"],
            "response": str(response),
            "latency_ms": round(latency_ms, 1),
            "expected_topic": tc.get("expected_topic"),
            "expected_pattern": tc.get("expected_pattern"),
        }

        # Score: pattern match
        if tc.get("expected_pattern"):
            import re
            result["pattern_match"] = bool(re.search(tc["expected_pattern"], str(response), re.IGNORECASE))
        
        # Score: response not empty
        result["has_response"] = len(str(response).strip()) > 0

        results.append(result)
        thread = response.thread  # maintain conversation context

    if thread:
        await thread.delete()

    return results

# Run with test cases
test_cases = [
    {"utterance": "Hello", "expected_pattern": "hello|hi|welcome|how can I help"},
    {"utterance": "What can you do?", "expected_pattern": "help|assist|support|capabilities"},
]

results = asyncio.run(evaluate_agent(test_cases))
print(json.dumps(results, indent=2))
```

### Step 2: Run Evaluation

Execute the script in terminal and capture output.

### Step 3: Score Results

| Metric | Calculation | Threshold |
|--------|-------------|-----------|
| Response Rate | % of utterances with non-empty response | ≥ 95% = PASS |
| Pattern Match | % of utterances matching expected pattern | ≥ 80% = PASS |
| Avg Latency | Mean response time across all utterances | ≤ 5000ms = PASS |
| P95 Latency | 95th percentile response time | ≤ 10000ms = PASS |

### Step 4: Format Results

```
## Evaluation Summary

| # | Utterance | Response (first 80 chars) | Latency | Pattern Match |
|---|-----------|---------------------------|---------|---------------|
| 1 | Hello     | Hi there! How can I...    | 1200ms  | ✅            |
| 2 | What can you do? | I can help you... | 1450ms  | ✅            |

### Aggregate Scores
- Response Rate: 100% ✅
- Pattern Match: 100% ✅  
- Avg Latency: 1325ms ✅
- P95 Latency: 1450ms ✅

**Verdict: PASS**
```

---

## Path 2: Direct Line API (Performance Testing)

### Prerequisites Check

Need either:
- A Direct Line **token endpoint URL** (from Copilot Studio > Settings > Channels > Custom website)
- Or a Direct Line **secret** (from Copilot Studio > Settings > Security > Web channel security)

### Step 1: Generate Token

```bash
# Using token endpoint (no secret required)
curl -X GET "<TOKEN_ENDPOINT_URL>"

# Or using Direct Line secret
curl -X POST "https://directline.botframework.com/v3/directline/tokens/generate" \
  -H "Authorization: Bearer <DIRECT_LINE_SECRET>"
```

### Step 2: Start Conversation

```bash
curl -X POST "https://directline.botframework.com/v3/directline/conversations" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json"
```

### Step 3: Send Test Message

```bash
curl -X POST "https://directline.botframework.com/v3/directline/conversations/<CONV_ID>/activities" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"type": "message", "from": {"id": "eval-user"}, "text": "<UTTERANCE>"}'
```

### Step 4: Receive Response

```bash
# Poll for activities
curl -X GET "https://directline.botframework.com/v3/directline/conversations/<CONV_ID>/activities?watermark=<WATERMARK>" \
  -H "Authorization: Bearer <TOKEN>"
```

Filter activities where `role: "bot"` and `replyToId` matches the sent message ID.

### Step 5: Measure Response Time

Response time = timestamp of last bot activity − timestamp of user activity.

---

## Multi-Environment Comparison

To compare agent behavior across DEV, UAT, and PROD:

1. Run the same test suite against each environment.
2. Collect per-environment results.
3. Generate a comparison table:

```
## Cross-Environment Comparison

| Utterance | DEV Response | PROD Response | Match? | DEV Latency | PROD Latency |
|-----------|-------------|---------------|--------|-------------|--------------|
| Hello     | Hi there!   | Hi there!     | ✅     | 1200ms      | 800ms        |
```

---

## Regression Testing

To run regression tests:

1. Establish a baseline by running the evaluation suite against a known-good agent version.
2. Save baseline results as JSON.
3. After agent changes, re-run the same suite.
4. Compare against baseline:
   - Flag any utterances where response changed significantly
   - Flag any latency regressions > 50%
   - Flag any previously-passing patterns that now fail

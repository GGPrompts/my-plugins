---
description: "Get multiple AI perspectives on architecture decisions. Fans out the same prompt to Opus, gpt5.2-codex, and Gemini 3, then compares their responses."
---

# Council Command

Fan out a prompt to multiple AI models and compare their perspectives.

## Usage

```
/council "your architecture or planning question"
```

## Why Use Council

Different models have different training data, biases, and strengths:

| Model | Tends To |
|-------|----------|
| **Claude Opus** | Thorough analysis, edge cases, safety considerations |
| **GPT-5.2 Codex** | Practical implementation, code-first thinking |
| **Gemini 3** | Google ecosystem, different architectural patterns |

When they **agree** = high confidence in that approach
When they **differ** = worth investigating further

## Running the Council

When this command is invoked with a prompt:

### Step 1: Fan out to all models in parallel

```bash
PROMPT="$*"
TMPDIR=$(mktemp -d)

# Run all three in parallel
copilot --model claude-opus-4.5 -p "$PROMPT" -s --yolo > "$TMPDIR/opus.md" 2>&1 &
PID_OPUS=$!

copilot --model gpt-5.2-codex -p "$PROMPT" -s --yolo > "$TMPDIR/codex.md" 2>&1 &
PID_CODEX=$!

copilot --model gemini-3-pro-preview -p "$PROMPT" -s --yolo > "$TMPDIR/gemini.md" 2>&1 &
PID_GEMINI=$!

# Wait for all to complete
wait $PID_OPUS $PID_CODEX $PID_GEMINI
```

### Step 2: Collate and compare responses

Read all three response files and present a comparison:

```markdown
## Council Results

### Prompt
> {original prompt}

---

### Claude Opus 4.5
{opus response}

---

### GPT-5.2 Codex
{codex response}

---

### Gemini 3 Pro
{gemini response}

---

### Analysis

**Points of Agreement:**
- {where all three models agree}

**Points of Divergence:**
- {where they differ and why that matters}

**Recommendation:**
{synthesis of the best ideas from each}
```

### Step 3: Optionally save to file

```bash
# Combine into a council report
cat > "$TMPDIR/council-report.md" << EOF
# Council Report: $(date +%Y-%m-%d)

## Prompt
$PROMPT

## Responses

### Claude Opus 4.5
$(cat "$TMPDIR/opus.md")

### GPT-5.2 Codex
$(cat "$TMPDIR/codex.md")

### Gemini 3 Pro
$(cat "$TMPDIR/gemini.md")
EOF

echo "Council report saved to: $TMPDIR/council-report.md"
```

## Example

```bash
/council "Should we use PostgreSQL full-text search or Elasticsearch for a veteran resource directory with ~10k records?"
```

**Opus might say:** "PostgreSQL FTS is sufficient for 10k records, simpler ops, but consider pg_trgm for fuzzy matching..."

**Codex might say:** "Here's the implementation - CREATE INDEX ... USING gin(to_tsvector(...)), query like this..."

**Gemini might say:** "Consider Cloud SQL with built-in FTS, or if on GCP, Vertex AI Search..."

You get three different lenses on the same problem.

## Cost Notes

- **Opus**: Uses your Claude Max quota
- **Codex**: Uses your Codex subscription
- **Gemini**: Uses your Copilot subscription

All run in parallel, so wall-clock time is ~same as slowest model.

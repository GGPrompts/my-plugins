---
description: "Swarm consensus — 10 haiku agents think in parallel, then vote on the best answer"
argument-hint: <question or task>
allowed-tools: [Agent, Read, Grep, Glob]
---

# Swarm Consensus Protocol

You are orchestrating a swarm of 10 haiku agents to solve a problem through parallel reasoning and democratic voting.

The user's question/task: $ARGUMENTS

## Phase 1: THINK (10 agents in parallel)

Launch exactly 10 `haiku-swarm-skills` agents **in parallel** (all in one message). Each gets the same prompt:

```
THINK about the following question. Reason deeply — challenge your own assumptions, consider alternative angles, and commit to your best answer.

Question: [the user's question/task, verbatim]

Output ONLY this format:

ANSWER: [your concise best answer]
CONFIDENCE: [1-5]
KEY_INSIGHT: [the single strongest reasoning step that got you here]

Do not explain your process. Do not hedge. Commit to your best answer.
```

If the task references code or files, include relevant file paths or context snippets so each agent can read what it needs.

Wait for all 10 to return. Collect their ANSWER, CONFIDENCE, and KEY_INSIGHT.

## Phase 2: Present Candidates

Display all 10 answers to the user in a numbered table:

| # | Answer (summary) | Confidence | Key Insight |
|---|-----------------|------------|-------------|
| 1 | ... | 3 | ... |
| 2 | ... | 5 | ... |
| ... | | | |

## Phase 3: VOTE (10 agents evaluate all candidates)

Build a candidates list from Phase 1 results. Launch exactly 10 `haiku-swarm-skills` agents **in parallel** with:

```
VOTE: Given these candidate answers to the question "[original question]":

1. [Answer 1 — full text]
2. [Answer 2 — full text]
...
10. [Answer 10 — full text]

Pick the single best answer. Output ONLY this format:

PICK: [number of the candidate, e.g. 3]
REASON: [one sentence why]
```

## Phase 4: Tally and Report

Count the votes. Report:

**Winner**: Candidate #N with X/10 votes
**Answer**: [the winning answer in full]
**Vote distribution**: #1: 2 votes, #3: 5 votes, #7: 3 votes, etc.
**Consensus strength**: Strong (7+), moderate (5-6), split (≤4)

If there's a tie, present the tied candidates and your brief synthesis of the best elements from each.

## Rules

- Always launch all 10 agents in a single message (parallel, not sequential)
- Use `subagent_type: "haiku-swarm-skills"` for all agent launches
- Do not inject your own opinion — let the swarm decide
- If the question is about code, include enough context (file paths, relevant snippets) for agents to work with
- Keep your own commentary minimal — the swarm's output is the star

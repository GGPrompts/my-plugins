# Swarm Plugin

Swarm consensus — 10 haiku agents think in parallel, then vote on the best answer.

## Overview

Uses parallel haiku agents as independent reasoning units. Each agent thinks about the question independently, then all agents vote on the best answer. Democratic consensus emerges from diverse parallel reasoning.

## Usage

```
/swarm What is the best approach to implement caching in this service?
```

## How It Works

1. **THINK** — 10 haiku agents reason independently in parallel
2. **Present** — All answers displayed in a table
3. **VOTE** — 10 agents evaluate all candidates and pick the best
4. **Report** — Winner announced with vote distribution and consensus strength

## Components

- `commands/swarm.md` — The `/swarm` slash command (orchestrator)
- `agents/haiku-swarm-skills.md` — The haiku reasoning unit agent

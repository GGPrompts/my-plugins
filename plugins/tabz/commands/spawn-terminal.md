---
name: spawn-terminal
description: "Spawn a new TabzChrome terminal via /api/spawn"
---

# Spawn Terminal

Create a new terminal tab in TabzChrome via the REST API.

## Usage

```
/tabz:spawn-terminal [name] [workingDir] [command]
```

## Basic Spawn

```bash
TOKEN=$(cat /tmp/tabz-auth-token)
curl -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d '{"name": "Worker", "workingDir": "~/projects"}'
```

## Spawn with Command

```bash
TOKEN=$(cat /tmp/tabz-auth-token)
curl -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d '{
    "name": "Build Worker",
    "workingDir": "~/projects/myapp",
    "command": "npm run build"
  }'
```

## Spawn Claude Worker

```bash
TOKEN=$(cat /tmp/tabz-auth-token)
curl -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d '{
    "name": "Claude Worker",
    "workingDir": "~/projects",
    "command": "claude --dangerously-skip-permissions"
  }'
```

## Parameters

| Param | Required | Default | Description |
|-------|----------|---------|-------------|
| `name` | No | "Claude Terminal" | Display name in tab |
| `workingDir` | No | $HOME | Starting directory |
| `command` | No | - | Command to auto-execute |

## Response

```json
{
  "success": true,
  "terminalId": "ctt-BuildWorker-abc123"
}
```

## List Active Terminals

```bash
curl http://localhost:8129/api/agents
```

## Kill Terminal

```bash
curl -X DELETE http://localhost:8129/api/agents/ctt-BuildWorker-abc123
```

## Prerequisites

- TabzChrome backend running (`./scripts/dev.sh`)
- Auth token file exists at `/tmp/tabz-auth-token`

## Troubleshooting

**Auth error:** Check token with `cat /tmp/tabz-auth-token`

**Backend not running:** `curl http://localhost:8129/api/health`

---
name: automating-browser
description: "Controls Chrome browser: takes screenshots, clicks buttons, fills forms, downloads images, inspects pages, captures network requests, checks console errors, debugs API issues. Use when: 'screenshot', 'click', 'fill form', 'download image', 'check browser', 'look at screen', 'capture page', 'check for errors', 'debug network', 'API failing', 'console errors'. Provides MCP tool discovery for 70 tabz_* browser automation tools."
---

# Tabz MCP - Browser Automation

## Overview

Control Chrome browser programmatically via the Tabz MCP server. 70 tools for screenshots, interaction, network debugging, and more.

## Tool Discovery (Claude Code)

Use MCPSearch to load tools before calling them:

```
# Search for tools
MCPSearch with query: "screenshot"

# Load specific tool
MCPSearch with query: "select:mcp__tabz__tabz_screenshot"

# Then call it
mcp__tabz__tabz_screenshot
```

## Browser Debugging (Common Issues)

### Check Console Errors

```
MCPSearch: select:mcp__tabz__tabz_get_console_logs
mcp__tabz__tabz_get_console_logs with level="error"
```

### Debug Network/API Issues

```
# 1. Enable capture BEFORE triggering the action
MCPSearch: select:mcp__tabz__tabz_enable_network_capture
mcp__tabz__tabz_enable_network_capture

# 2. Trigger the action (click button, navigate, etc.)

# 3. Get failed requests
MCPSearch: select:mcp__tabz__tabz_get_network_requests
mcp__tabz__tabz_get_network_requests with statusFilter="error"

# Or filter by URL pattern
mcp__tabz__tabz_get_network_requests with filter="api.example.com"
```

### Screenshot for Visual QA

```
MCPSearch: select:mcp__tabz__tabz_screenshot
mcp__tabz__tabz_screenshot
# Returns file path - use Read tool to view
```

### Check Page State

```
MCPSearch: select:mcp__tabz__tabz_get_page_info
mcp__tabz__tabz_get_page_info
# Returns URL, title, loading state

MCPSearch: select:mcp__tabz__tabz_get_element
mcp__tabz__tabz_get_element with selector="#error-message" includeStyles=true
```

## Tool Categories

Use `MCPSearch with query: "tabz"` to discover all available tools. Categories:

| Category | Tools | Purpose |
|----------|-------|---------|
| Tab Management | `list_tabs`, `switch_tab`, `rename_tab`, `open_url` | Navigate tabs |
| Tab Groups | `create_group`, `add_to_group`, `ungroup_tabs` | Organize tabs |
| Windows | `list_windows`, `create_window`, `tile_windows` | Window management |
| Audio | `speak`, `list_voices`, `play_audio` | TTS notifications |
| Page Info | `get_page_info`, `get_element`, `get_dom_tree` | Inspect content |
| Interaction | `click`, `fill` | Click/type |
| Screenshots | `screenshot`, `screenshot_full` | Capture visuals |
| Downloads | `download_image`, `download_file` | Save files |
| Network | `enable_network_capture`, `get_network_requests` | Debug APIs |
| Console | `get_console_logs`, `execute_script` | Debug JS |
| Emulation | `emulate_device`, `emulate_geolocation` | Responsive testing |

## Tab Groups (Parallel Workers)

When multiple Claude workers run in parallel, each MUST create their own named group:

```
# Create unique group for this worker
MCPSearch: select:mcp__tabz__tabz_create_group
mcp__tabz__tabz_create_group with tabIds=[123,456] title="ISSUE-ID: Research" color="blue"

# Add more tabs later
mcp__tabz__tabz_add_to_group with groupId=12345 tabIds=[789]

# Cleanup when done
mcp__tabz__tabz_ungroup_tabs with tabIds=[123,456,789]
```

**Group colors:** grey, blue, red, yellow, green, pink, purple, cyan

## Quick Patterns

**Screenshot:**
```
mcp__tabz__tabz_screenshot
```

**Click:**
```
mcp__tabz__tabz_click with selector="button.submit"
```

**Fill form:**
```
mcp__tabz__tabz_fill with selector="#email" value="test@example.com"
```

**Switch tab:**
```
mcp__tabz__tabz_list_tabs  # Get tab IDs (large integers like 1762556601)
mcp__tabz__tabz_switch_tab with tabId=1762556601
```

**TTS notification:**
```
mcp__tabz__tabz_speak with text="Done!" priority="high"
```

## Important Notes

1. **Tab IDs**: Chrome tab IDs are large integers (e.g., `1762556601`), not 1, 2, 3
2. **Always load tools first**: Use MCPSearch before calling any mcp__tabz__ tool
3. **Network capture**: Enable BEFORE the page makes requests
4. **Screenshots**: Return file paths - use Read tool to view
5. **Selectors**: CSS selectors - `#id`, `.class`, `button[type="submit"]`

## Resources

See `references/workflows.md` for more patterns.

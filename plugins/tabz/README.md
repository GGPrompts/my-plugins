# Tabz Plugin

Browser automation and terminal spawning via TabzChrome extension.

## Overview

The Tabz plugin provides 70 MCP tools for browser automation:
- **Screenshots** - Viewport and full-page captures
- **Interaction** - Clicks, form fills, script execution
- **Tab Management** - Groups, windows, isolation for parallel workers
- **Network** - Request capture and analysis
- **Audio/TTS** - Text-to-speech and audio playback
- **Terminal Spawning** - Create new terminal tabs via REST API

## Installation

```bash
# Requires TabzChrome extension running on localhost:8129
# Copy to Claude plugins
cp -r my-plugins/plugins/tabz ~/.claude/plugins/
```

## Skills

| Skill | Purpose |
|-------|---------|
| `tabz-integration` | Full TabzChrome integration guide with MCP setup |
| `browser-control` | Browser interaction patterns (clicks, fills, screenshots) |
| `screenshot` | Screenshot capture workflows |
| `spawn-terminal` | Terminal spawning via REST API |
| `mcp-discovery` | Discover and inspect available MCP tools |

## Agents

| Agent | Purpose |
|-------|---------|
| `tabz-expert` | Opus-powered browser automation specialist with access to all 70 MCP tools |

## Tool Categories (70 Tools)

| Category | Count | Examples |
|----------|-------|----------|
| Tab Management | 5 | list_tabs, switch_tab, open_url |
| Tab Groups | 7 | create_group, add_to_group, claude_group_* |
| Windows | 7 | list_windows, create_window, tile_windows |
| Screenshots | 2 | screenshot, screenshot_full |
| Interaction | 4 | click, fill, get_element, execute_script |
| DOM/Debug | 4 | get_dom_tree, get_console_logs, profile_performance |
| Network | 3 | enable_network_capture, get_network_requests |
| Downloads | 5 | download_image, download_file, save_page |
| Bookmarks | 6 | get_bookmark_tree, save_bookmark |
| Audio/TTS | 3 | speak, list_voices, play_audio |
| History | 5 | history_search, history_recent |
| Sessions | 3 | sessions_recently_closed, sessions_restore |
| Cookies | 5 | cookies_get, cookies_set, cookies_audit |
| Emulation | 6 | emulate_device, emulate_geolocation, emulate_vision |
| Notifications | 4 | notification_show, notification_update |

## Quick Start

```bash
# Always check schema first
mcp-cli info tabz/tabz_screenshot

# Create isolated tab group (required for parallel workers)
mcp-cli call tabz/tabz_create_group '{"title": "Claude-123", "color": "purple"}'

# Open URL in your group
mcp-cli call tabz/tabz_open_url '{"url": "https://example.com", "newTab": true, "groupId": 123}'

# Screenshot with explicit tabId
mcp-cli call tabz/tabz_screenshot '{"tabId": 1762561083}'
```

## Requirements

- TabzChrome extension (provides MCP server on localhost:8129)
- Claude Code with MCP support

## License

MIT License

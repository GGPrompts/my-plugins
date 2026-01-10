---
name: mcp-discovery
description: "Discover available tabz_* MCP tools"
---

# MCP Discovery

Discover and inspect available TabzChrome MCP tools.

## Usage

```
/tabz:mcp-discovery
```

## List All Tabz Tools

```bash
mcp-cli tools tabz
```

## Search Tools

```bash
mcp-cli grep "screenshot"
mcp-cli grep "download"
mcp-cli grep "audio"
```

## Inspect Tool Schema

**Always check schema before using a tool:**

```bash
mcp-cli info tabz/tabz_screenshot
mcp-cli info tabz/tabz_click
mcp-cli info tabz/tabz_speak
```

## Tool Categories (46 Tools)

### Tabs & Navigation
- `tabz_list_tabs` - List all open tabs
- `tabz_switch_tab` - Switch to specific tab
- `tabz_rename_tab` - Set custom display name
- `tabz_get_page_info` - Get page URL and title
- `tabz_open_url` - Open URL in browser

### Tab Groups
- `tabz_list_groups` - List all tab groups
- `tabz_create_group` - Create group with title/color
- `tabz_update_group` - Update group properties
- `tabz_add_to_group` - Add tabs to group
- `tabz_ungroup_tabs` - Remove tabs from groups
- `tabz_claude_group_add` - Add to "Claude Active" group
- `tabz_claude_group_remove` - Remove from Claude group

### Windows & Displays
- `tabz_list_windows` - List browser windows
- `tabz_create_window` - Create new window
- `tabz_update_window` - Update window state
- `tabz_close_window` - Close window
- `tabz_get_displays` - Get display info
- `tabz_tile_windows` - Tile across displays
- `tabz_popout_terminal` - Pop out terminal

### Screenshots
- `tabz_screenshot` - Capture viewport
- `tabz_screenshot_full` - Capture full page

### Interaction
- `tabz_click` - Click element
- `tabz_fill` - Fill input field
- `tabz_get_element` - Get element details
- `tabz_execute_script` - Run JavaScript

### DOM & Debugging
- `tabz_get_dom_tree` - Full DOM tree
- `tabz_get_console_logs` - Console output
- `tabz_profile_performance` - Performance metrics
- `tabz_get_coverage` - Code coverage

### Network
- `tabz_enable_network_capture` - Start capture
- `tabz_get_network_requests` - Get requests
- `tabz_clear_network_requests` - Clear requests

### Downloads
- `tabz_download_image` - Download image
- `tabz_download_file` - Download file
- `tabz_get_downloads` - List downloads
- `tabz_cancel_download` - Cancel download
- `tabz_save_page` - Save as HTML/MHTML

### Bookmarks
- `tabz_get_bookmark_tree` - Full tree
- `tabz_search_bookmarks` - Search bookmarks
- `tabz_save_bookmark` - Create bookmark
- `tabz_create_folder` - Create folder
- `tabz_move_bookmark` - Move bookmark
- `tabz_delete_bookmark` - Delete bookmark

### Audio/TTS
- `tabz_speak` - Text-to-speech
- `tabz_list_voices` - Available voices
- `tabz_play_audio` - Play audio file

### History
- `tabz_history_search` - Search history
- `tabz_history_visits` - Get visits
- `tabz_history_recent` - Recent history

### Emulation
- `tabz_emulate_device` - Device emulation
- `tabz_emulate_network` - Network throttling
- `tabz_emulate_geolocation` - Fake location

## Prerequisites

- TabzChrome MCP server configured in `.mcp.json`
- TabzChrome backend running
- Chrome with TabzChrome extension

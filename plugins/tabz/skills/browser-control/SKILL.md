---
name: browser-control
description: "Control browser via tabz MCP tools - click, fill, navigate"
---

# Browser Control

Control Chrome browser via TabzChrome MCP tools.

## Usage

```
/tabz:browser-control
```

## CRITICAL: Always Use Tab Groups

**NEVER operate on the user's current tab.** Always create your own tab group first to prevent conflicts with the user and other Claude sessions.

```bash
# 1. Create your own group FIRST
mcp-cli call tabz/tabz_create_group '{"title": "Claude Working", "color": "purple"}'
# Returns: {"groupId": 123}

# 2. Open URLs INTO your group
mcp-cli call tabz/tabz_open_url '{"url": "https://example.com", "newTab": true, "groupId": 123}'

# 3. Always use explicit tabId from YOUR tabs
mcp-cli call tabz/tabz_screenshot '{"tabId": <your_tab_id>}'
```

**Why this is mandatory:**
- User can switch tabs at any time - active tab is unreliable
- Multiple Claude sessions may run simultaneously
- Your operations target YOUR tabs, not the user's browsing
- Purple group shows user which tabs you're working on

## Always Check Schema First

```bash
mcp-cli info tabz/<tool_name>
```

## Tab Targeting

**Chrome tab IDs are large numbers** (e.g., `1762561083`), NOT indices like 1, 2, 3.

After creating your group and opening tabs, list tabs to get IDs:

```bash
mcp-cli call tabz/tabz_list_tabs '{}'
```

Always use explicit tabId from YOUR group:

```bash
mcp-cli call tabz/tabz_screenshot '{"tabId": 1762561083}'
```

## Navigation

### Open URL (Always Specify groupId)

```bash
mcp-cli call tabz/tabz_open_url '{"url": "https://example.com", "newTab": true, "groupId": 123}'
```

### Switch Tab

```bash
mcp-cli call tabz/tabz_switch_tab '{"tabId": 1762561083}'
```

### Get Page Info

```bash
mcp-cli call tabz/tabz_get_page_info '{}'
```

## Interaction

### Click Element

```bash
mcp-cli call tabz/tabz_click '{"selector": "button[type=submit]"}'
```

### Fill Input

```bash
mcp-cli call tabz/tabz_fill '{"selector": "#email", "value": "test@example.com"}'
```

### Get Element

```bash
mcp-cli call tabz/tabz_get_element '{"selector": ".my-element"}'
```

### Execute JavaScript

```bash
mcp-cli call tabz/tabz_execute_script '{"script": "document.title"}'
```

## Form Workflow

```bash
# Fill form fields
mcp-cli call tabz/tabz_fill '{"selector": "#username", "value": "user@example.com"}'
mcp-cli call tabz/tabz_fill '{"selector": "#password", "value": "secret"}'

# Submit
mcp-cli call tabz/tabz_click '{"selector": "button[type=submit]"}'
```

## Visual Feedback

Elements glow when interacted with:
- Green glow on `tabz_click`
- Blue glow on `tabz_fill`
- Purple glow on `tabz_get_element`

## Getting CSS Selectors

Right-click any element on a page -> "Send Element to Chat" to get unique selectors.

## Limitations

- Some sites block automated clicks/fills (CORS, CSP)
- Extension must be active in Chrome
- Some tools require tab to be in foreground

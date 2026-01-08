---
name: TabzArtist
description: Generate images via DALL-E and videos via Sora using browser automation. This skill should be used when a project needs visual assets like hero images, team photos, feature icons, or product demo videos. Spawnable as a conductor agent during bd-swarm-auto for parallel asset generation.
---

# TabzArtist - AI Asset Generation via Browser Automation

Generate images (DALL-E) and videos (Sora) for projects using TabzChrome MCP tools.

## When to Use

- Building landing pages, apps, or websites that need visual assets
- Creating hero images, team photos, feature icons, product screenshots
- Generating product demo videos or background ambient videos
- Running as parallel asset generation during bd-swarm-auto builds

## Quick Start

```
Generate assets for a [industry] landing page:
- Hero image: [description]
- Team photos: [description]
- Feature icons: [description]
- Product video: [description]
```

## Workflow Overview

```
1. Plan assets based on project description
2. Generate images via DALL-E (batch if possible)
3. Generate videos via Sora
4. Wait for generation (poll with screenshots)
5. Download all assets to project folder
6. Return list of downloaded files
```

## DALL-E Image Generation

### URLs
| Page | URL |
|------|-----|
| DALL-E 3 GPT | `https://chatgpt.com/g/g-iLoR8U3iA-dall-e3` |
| Images Gallery | `https://chatgpt.com/images` |

### Workflow

```bash
# 1. Open DALL-E
mcp-cli call tabz/tabz_open_url '{"url": "https://chatgpt.com/g/g-iLoR8U3iA-dall-e3"}'

# 2. Fill prompt (wait 2-3s for page load)
mcp-cli call tabz/tabz_fill '{"selector": "#prompt-textarea", "value": "PROMPT_HERE"}'

# 3. Submit
mcp-cli call tabz/tabz_click '{"selector": "#composer-submit-button"}'

# 4. Wait 15-30s, poll with screenshots until image appears
mcp-cli call tabz/tabz_screenshot '{}'

# 5. Extract image URL
mcp-cli call tabz/tabz_get_element '{"selector": "img[alt=\"Generated image\"]", "includeStyles": false, "response_format": "json"}'
# Look for: attributes.src

# 6. Download
mcp-cli call tabz/tabz_download_file '{"url": "IMAGE_SRC_URL", "filename": "public/images/hero.png"}'
```

### Batch Download from /images Page

```bash
# Go to gallery
mcp-cli call tabz/tabz_open_url '{"url": "https://chatgpt.com/images"}'

# Click download button (hover bottom-left of each image)
# nth-of-type(1) = first in grid, nth-of-type(2) = second, etc.
mcp-cli call tabz/tabz_click '{"selector": "div.flex.w-full > div.flex:nth-of-type(1) > span > button.flex.items-center"}'
```

### Key Selectors
| Element | Selector |
|---------|----------|
| Prompt input | `#prompt-textarea` |
| Submit button | `#composer-submit-button` |
| Generated image | `img[alt="Generated image"]` |
| Download btn (/images) | `div.flex.w-full > div.flex:nth-of-type(n) > span > button.flex.items-center` |

## Sora Video Generation

### URL
| Page | URL |
|------|-----|
| Drafts | `https://sora.chatgpt.com/drafts` |

### Workflow

```bash
# 1. Open Sora drafts
mcp-cli call tabz/tabz_open_url '{"url": "https://sora.chatgpt.com/drafts"}'

# 2. Fill prompt (wait 2-3s for page load)
mcp-cli call tabz/tabz_fill '{"selector": "textarea", "value": "PROMPT_HERE"}'

# 3. Submit
mcp-cli call tabz/tabz_click '{"selector": "div.flex.items-center.justify-between > div:last-child > button:last-child"}'

# 4. Wait 60-120s, poll with screenshots until video thumbnail appears
mcp-cli call tabz/tabz_screenshot '{}'

# 5. Click video to open detail view
mcp-cli call tabz/tabz_click '{"selector": "video"}'

# 6. Extract video URL
mcp-cli call tabz/tabz_get_element '{"selector": "video", "includeStyles": false, "response_format": "json"}'
# Look for: attributes.src

# 7. Download
mcp-cli call tabz/tabz_download_file '{"url": "VIDEO_SRC_URL", "filename": "public/videos/demo.mp4"}'
```

### Key Selectors
| Element | Selector |
|---------|----------|
| Prompt textarea | `textarea` |
| Create video button | `div.flex.items-center.justify-between > div:last-child > button:last-child` |
| Video thumbnail | `video` |
| Video src | `attributes.src` via tabz_get_element |

## Asset Planning

When given a project description, plan assets like:

| Asset Type | DALL-E Prompt Structure |
|------------|------------------------|
| Hero image | "[Subject] in [setting], [style], [mood lighting], [composition]" |
| Team photos | "Professional headshot grid, [n] diverse people, modern office, candid warm lighting" |
| Feature icons | "Minimal line icon set, [n] icons for: [list], consistent stroke weight, [color]" |
| Product shot | "[Product] on [surface], [lighting setup], commercial photography style" |

| Asset Type | Sora Prompt Structure |
|------------|----------------------|
| Product demo | "[Style]. [Device/screen] showing [UI]. [Camera movement]. [Specific actions with timing]. [Lighting + palette]." |
| Background | "[Aesthetic]. [Scene description]. [Camera movement]. [Duration]. [Palette]." |

## Output Structure

Save assets to project directories:
```
public/
├── images/
│   ├── hero.png
│   ├── team.png
│   └── icons/
│       ├── feature-1.png
│       └── feature-2.png
└── videos/
    └── demo.mp4
```

## Completion

Return a summary of generated assets:
```
## Generated Assets

### Images (DALL-E)
- public/images/hero.png - Hero image for landing page
- public/images/team.png - Team photo grid

### Videos (Sora)
- public/videos/demo.mp4 - Product demo video (10s)

All assets downloaded and ready for use.
```

## Tips

1. **Batch images** - Submit multiple DALL-E prompts, then download from /images page
2. **Poll patiently** - DALL-E: 15-30s, Sora: 60-120s
3. **Screenshot first** - Verify generation complete before extracting URLs
4. **Use tabz_download_file** - Not tabz_download_image (service worker limitation)
5. **Concrete prompts** - Specific details > vague descriptions

## Reference Prompts

For detailed prompt guidance, see:
- `.prompts/images/dalle3.prompty` - DALL-E prompt structure and examples
- `.prompts/video/sora.prompty` - Sora prompt structure and examples

## Related Skills

For non-AI-generated visuals, consider:
- `/canvas-design` - Programmatic poster/document design (canvas-based PDFs, posters)
- `/mermaidjs-v11` - Diagrams, flowcharts, architecture visualizations

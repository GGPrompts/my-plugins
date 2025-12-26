---
description: Search Pixabay for royalty-free images and videos
---

# Pixabay Search

Search and download royalty-free media from Pixabay.

## Usage

```
/pixabay <search query> [options]
```

## Options

| Option | Values | Default |
|--------|--------|---------|
| `--type` | `photo`, `illustration`, `vector`, `video` | `photo` |
| `--orientation` | `horizontal`, `vertical`, `all` | `all` |
| `--category` | nature, people, animals, food, travel, buildings, business, music, science, education, health, sports, transportation, fashion, feelings, religion, backgrounds, industry, computer, places | - |
| `--color` | grayscale, transparent, red, orange, yellow, green, turquoise, blue, lilac, pink, white, gray, black, brown | - |
| `--count` | 3-20 | 5 |
| `--editors-choice` | flag for curated content | - |
| `--download` | download first result | - |

## Examples

```
/pixabay sunset over mountains
/pixabay cats --type=photo --count=10
/pixabay abstract patterns --type=vector --color=blue
/pixabay cooking tutorial --type=video --category=food
/pixabay landscape --orientation=horizontal --editors-choice --download
```

## Execution

1. Parse the search query and options from user input
2. Use the **pixabay skill** to execute the API call with parsed parameters
3. Display results in a table format:
   - Thumbnail preview URL
   - Resolution
   - Tags
   - Downloads/likes count
   - Direct link

4. If `--download` flag is set, download the first result's large image/video

## Output Format

```
## Pixabay Results: "{query}"

| # | Preview | Size | Tags | Stats |
|---|---------|------|------|-------|
| 1 | [thumb] | 1920x1080 | sunset, mountain | 5.2k downloads |
| 2 | ... | ... | ... | ... |

**Download URLs:**
1. [Large] https://...
2. [Large] https://...

Total: X results found (showing top Y)
```

## API Key

The pixabay skill reads the API key from `~/.config/pixabay/api_key`. Set it up with:

```bash
mkdir -p ~/.config/pixabay
echo "YOUR_API_KEY" > ~/.config/pixabay/api_key
chmod 600 ~/.config/pixabay/api_key
```

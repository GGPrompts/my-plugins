---
name: remotion
description: Remotion video creation in React - compositions, animations, timing, audio/video, captions, 3D. Use when creating programmatic videos, animations, or working with Remotion code.
---

# Remotion Best Practices

Create videos programmatically using React. Use this skill when working with Remotion code for domain-specific knowledge.

## Quick Start

```bash
npx create-video@latest
```

## Core Concepts

| Concept | Reference |
|---------|-----------|
| Compositions & structure | @references/compositions.md |
| Animation fundamentals | @references/animations.md |
| Timing & interpolation | @references/timing.md |
| Sequencing patterns | @references/sequencing.md |
| Transitions | @references/transitions.md |
| Trimming | @references/trimming.md |

## Media

| Topic | Reference |
|-------|-----------|
| Videos | @references/videos.md |
| Audio & sound | @references/audio.md |
| Images | @references/images.md |
| GIFs | @references/gifs.md |
| Assets (importing) | @references/assets.md |
| Fonts | @references/fonts.md |

## Captions & Text

| Topic | Reference |
|-------|-----------|
| Display captions | @references/display-captions.md |
| Import SRT files | @references/import-srt-captions.md |
| Transcribe audio | @references/transcribe-captions.md |
| Text animations | @references/text-animations.md |
| Measuring text | @references/measuring-text.md |

## Advanced

| Topic | Reference |
|-------|-----------|
| 3D with Three.js | @references/3d.md |
| Charts & data viz | @references/charts.md |
| Lottie animations | @references/lottie.md |
| Maps (Mapbox) | @references/maps.md |
| Parameters (Zod) | @references/parameters.md |
| Calculate metadata | @references/calculate-metadata.md |
| TailwindCSS | @references/tailwind.md |

## Utilities

| Topic | Reference |
|-------|-----------|
| Get video duration | @references/get-video-duration.md |
| Get video dimensions | @references/get-video-dimensions.md |
| Get audio duration | @references/get-audio-duration.md |
| Extract frames | @references/extract-frames.md |
| Check decode support | @references/can-decode.md |
| Measure DOM nodes | @references/measuring-dom-nodes.md |

## Key Rules

1. **No self-animating content** - All animations must be driven by `useCurrentFrame()`
2. **Never use `useFrame()`** - React Three Fiber's hook causes flickering during render
3. **Sequence layout** - Use `layout="none"` on `<Sequence>` inside `<ThreeCanvas>`
4. **Declarative animations** - Write animations in markup, not imperative loops

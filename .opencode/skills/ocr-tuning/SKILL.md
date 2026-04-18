---
name: ocr-tuning
description: Tune OCR workflows for Vietnamese and mixed UI text in AHK2
compatibility: opencode
metadata:
  domain: ahk2
  area: vision
---

## What I do
- Improve OCR preprocessing and text normalization
- Select the right region, scale, and fallback pass
- Handle noisy or mixed-language UI labels

## Checklist
1. Crop the smallest useful region.
2. Normalize whitespace and punctuation.
3. Add fallback templates for unreadable screens.

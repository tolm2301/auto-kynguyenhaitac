---
name: ocr-imagesearch
description: Combine ImageSearch and OCR for AHK2 UI detection and text parsing
compatibility: opencode
metadata:
  domain: ahk2
  area: vision
---

## What I do
- Search image templates inside a small region
- OCR text, normalize it, and make decision logic robust
- Retry with bounded attempts and fallback paths

## Pattern
```autohotkey
NormalizeScoreText(rawText) {
    text := Trim(rawText)
    text := RegExReplace(text, "\s+", "")
    text := RegExReplace(text, "[^0-9]", "")
    return text
}
```

## Checklist
1. Use the smallest possible region.
2. Normalize OCR output before parsing.
3. Keep retry count bounded.

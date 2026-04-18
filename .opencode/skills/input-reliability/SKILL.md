---
name: input-reliability
description: Make AHK2 input actions reliable with focus checks and safe timing
compatibility: opencode
metadata:
  domain: ahk2
  area: input
---

## What I do
- Stabilize `SendInput`, `Click`, and `CoordMode`
- Reduce missed keystrokes and focus loss
- Add minimal delays only where needed

## Checklist
1. Confirm `CoordMode`.
2. Avoid blind clicks when controls exist.
3. Re-activate window before critical input.

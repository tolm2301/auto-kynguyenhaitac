---
name: feature-architecture
description: Split AHK2 work into feature, config, utils, and GUI binding layers
compatibility: opencode
metadata:
  domain: ahk2
  area: architecture
---

## What I do
- Shape a feature into small modules
- Separate config from runtime logic
- Keep GUI binding isolated from business flow

## Pattern
```text
main.ahk
gui/
features/
utils/
lib/
resources/
```

## Checklist
1. One feature, one entry point.
2. Put constants in config objects.
3. Keep helpers reusable.

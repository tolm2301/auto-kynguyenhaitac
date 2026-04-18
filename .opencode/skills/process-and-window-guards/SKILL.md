---
name: process-and-window-guards
description: Verify HWND, PID, title, and active state before automation steps
compatibility: opencode
metadata:
  domain: ahk2
  area: guards
---

## What I do
- Check the correct window before acting
- Guard against stale handles and wrong focus
- Confirm process state before sending input

## Checklist
1. Verify window exists.
2. Verify process still runs.
3. Re-check active window after activation.

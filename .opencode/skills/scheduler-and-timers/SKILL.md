---
name: scheduler-and-timers
description: Trigger AHK2 jobs with SetTimer, polling, and time-based scheduling
compatibility: opencode
metadata:
  domain: ahk2
  area: scheduling
---

## What I do
- Use timers for background checks
- Convert time windows into repeatable triggers
- Keep scheduler logic separate from feature logic

## Checklist
1. Never create an unbounded busy loop.
2. Track last-run state.
3. Log every trigger decision.

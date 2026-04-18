---
name: gui-state-machine
description: Model AHK2 GUI flows as states and transitions to keep automation deterministic
compatibility: opencode
metadata:
  domain: ahk2
  area: gui
---

## What I do
- Turn long GUI flows into explicit states
- Separate idle, running, retry, and done states
- Prevent accidental re-entry and duplicate actions

## Pattern
```autohotkey
state := "idle"

SetState(nextState) {
    global state
    state := nextState
}
```

## Checklist
1. Define states before coding the flow.
2. Make transitions explicit.
3. Log every state change.

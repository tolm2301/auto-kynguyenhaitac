---
name: debug-and-stability
description: Add logging, retry, timeout, and fail-safe patterns for AHK2 automation
compatibility: opencode
metadata:
  domain: ahk2
  area: reliability
---

## What I do
- Add structured logs with timestamps
- Wrap critical flows with retry and timeout guards
- Capture failure points for fast debugging

## Pattern
```autohotkey
Retry(actionFn, maxTry := 3, delayMs := 500) {
    loop maxTry {
        try {
            if actionFn.Call()
                return true
        } catch as err {
            ; log err here
        }
        Sleep(delayMs)
    }
    return false
}
```

## Checklist
1. Log inputs that affect the run.
2. Fail fast on missing state.
3. Keep retry loops bounded.

---
name: windows-api-and-control
description: Prefer WinAPI and control-level automation before pixel clicking in AHK2
compatibility: opencode
metadata:
  domain: ahk2
  area: windows
---

## What I do
- Prefer `ControlClick`, `ControlSend`, `PostMessage`, `SendMessage`
- Verify target window before sending input
- Escalate to `SendInput` and click coordinates only if needed

## Pattern
```autohotkey
ActivateAndClick(winTitle, controlName) {
    if !WinExist(winTitle)
        throw Error("Window not found: " winTitle)

    WinActivate(winTitle)
    if !WinWaitActive(winTitle, , 2)
        throw Error("Cannot activate: " winTitle)

    ControlClick(controlName, winTitle)
}
```

## Checklist
1. Verify title and PID when the target is unstable.
2. Add timeout to every wait.
3. Log exact failing control or window name.

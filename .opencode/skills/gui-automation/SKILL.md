---
name: gui-automation
description: Build stable AHK2 GUIs and bind automation features cleanly
compatibility: opencode
metadata:
  domain: ahk2
  area: gui
---

## What I do
- Build the main GUI shell
- Bind buttons to `_feature_*` entry points
- Keep UI responsive with timers and guarded state

## Pattern
```autohotkey
BuildMainGui() {
    guiMain := Gui("+Resize", "AHK2 Automation")
    guiMain.SetFont("s10", "Segoe UI")

    statusText := guiMain.AddText("x20 y20 w400 h20", "Status: Ready")
    runBtn := guiMain.AddButton("x20 y55 w180 h30", "Run Feature")
    runBtn.OnEvent("Click", (*) => RunFeatureSafely())

    guiMain.Show("w460 h320")
}
```

## Checklist
1. Use one clear entry function per feature.
2. Keep callbacks thin.
3. Guard against double click and long block.

# GUI Automation Skill (AHK2)

## Mục tiêu
Tạo GUI ổn định, dễ nối feature, và không block toàn bộ app khi chạy automation.

## Pattern khung GUI

```autohotkey
#Requires AutoHotkey v2.0

global g_statusText := 0
global g_isRunning := false

BuildMainGui() {
    guiMain := Gui("+Resize", "AHK2 Automation")
    guiMain.SetFont("s10", "Segoe UI")

    tab := guiMain.AddTab3("x10 y10 w460 h300", ["Main", "Tools"])
    tab.UseTab("Main")

    g_statusText := guiMain.AddText("x25 y55 w420 h20", "Status: Ready")
    btnRun := guiMain.AddButton("x25 y85 w200 h30", "Run Feature")
    btnRun.OnEvent("Click", (*) => RunFeatureSafely())

    guiMain.OnEvent("Close", (*) => ExitApp())
    guiMain.Show("w480 h330")
}
```

## Pattern chạy feature an toàn

```autohotkey
RunFeatureSafely() {
    global g_isRunning, g_statusText
    if g_isRunning {
        g_statusText.Value := "Status: Busy"
        return
    }

    g_isRunning := true
    g_statusText.Value := "Status: Running"
    try {
        _feature_my_task()
        g_statusText.Value := "Status: Done"
    } catch as err {
        g_statusText.Value := "Status: Error - " err.Message
    } finally {
        g_isRunning := false
    }
}
```

## Binding feature vào GUI

```autohotkey
; gui/gui_main.ahk
btnDailyTask := guiMain.AddButton("x25 y125 w200 h30", "Daily Task Point 4")
btnDailyTask.OnEvent("Click", (*) => _feature_daily_task_point4_simple())
```

## Checklist nhanh
1. Có cờ `g_isRunning` để chống double-click.
2. Có status text để user biết đang chạy gì.
3. Mỗi button gọi 1 entry function rõ ràng (`_feature_*`).
4. Bọc `try/catch/finally` ở layer GUI event.
5. Không hard-code logic vào callback; tách ra file `features/`.

#Requires AutoHotkey v2.0
#SingleInstance Off

#Include ..\utils\window_for_multiple_win.ahk
#Include ..\utils\post_message.ahk
#Include ..\utils\log_file.ahk
#Include daily.ahk

global g_featureText := {text: ""}

_feature_reset_running_status() {
    global g_featureText
    if (IsSet(g_featureText))
        g_featureText.text := "Tính năng đang chạy: Chưa có"
}

if (A_Args.Length < 1)
    ExitApp(1)

hwnd := Integer(A_Args[1])
stopFile := (A_Args.Length >= 2) ? A_Args[2] : ""

_feature_daily_worker_entry(hwnd, stopFile)
ExitApp(0)

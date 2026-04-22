#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon

#include ..\utils\paddle_ocr.ahk
#include ..\utils\date.ahk
#include ..\utils\post_message.ahk
#include ..\utils\log_file.ahk
#include ..\utils\window.ahk
#Include boss.ahk


global g_featureText := {text: ""}

_feature_reset_running_status() {
    global g_featureText
    if (IsSet(g_featureText))
        g_featureText.text := "Tính năng đang chạy: Chưa có"
}

if (A_Args.Length < 2)
    ExitApp(1)

mode := A_Args[1]
hwnd := Integer(A_Args[2])

_boss_worker_entry(mode, hwnd)
ExitApp(0)

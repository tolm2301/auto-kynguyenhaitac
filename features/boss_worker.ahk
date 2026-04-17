#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon

#Include ..\utils\post_message.ahk
#Include ..\utils\log_file.ahk
#Include boss.ahk

if (A_Args.Length < 2)
    ExitApp(1)

mode := A_Args[1]
hwnd := Integer(A_Args[2])

_boss_worker_entry(mode, hwnd)
ExitApp(0)

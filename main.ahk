#Requires AutoHotkey v2.0

_log_startup_error(msg) {
    logPath := A_ScriptDir . "\logs\startup_error.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    FileAppend("[" . timestamp . "] " . msg . "`n", logPath)
}

#Include gui\gui_main.ahk
_gui_init()

#include utils\window.ahk
#include utils\post_message.ahk
#include utils\date.ahk
#include utils\OCR.ahk

#include features\enhance.ahk
#include features\rakhoi.ahk
#include features\stop.ahk
#include features\test.ahk
#include features\boss.ahk
#include features\nammoiphattai.ahk
#include features\daily.ahk
#include features\anhhon.ahk
#include features\tanconghaiquan.ahk
#include features\hoidapcothuong.ahk
#include features\giftcode.ahk

F3:: {
    _win_resize_game()
    hwnd := _win_get_game()
    _click_post(hwnd, 135, 177)
    Sleep 500
    _click_post(hwnd, 838, 520)
    Sleep 500
    _post_with_vk_string(hwnd, "Esc")
    Sleep 500
    _post_with_vk_string(hwnd, "Esc")
    Sleep 500
    _post_with_vk_string(hwnd, "Esc")
}
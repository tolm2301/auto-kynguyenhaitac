#Requires AutoHotkey v2.0
#NoTrayIcon

_log_startup_error(msg) {
    logPath := A_ScriptDir . "\logs\startup_error.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    _log_append(logPath, "[" . timestamp . "] " . msg . "`n")
}

#Include gui\gui_main.ahk

#include utils\window.ahk
#include utils\post_message.ahk
#include utils\date.ahk
#include utils\log_file.ahk
#include utils\OCR.ahk
#include utils\scheduler.ahk

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
#include features\haitacthongthai.ahk
#include features\giftcode.ahk
#include features\register_event.ahk
#include features\daily_task_auto.ahk

OnExit(_app_on_exit)

_app_on_exit(*) {
    try _feature_stop()
}

if (A_Args.Length >= 2 and A_Args[1] = "--daily-worker") {
    hwnd := Integer(A_Args[2])
    stopFile := (A_Args.Length >= 3) ? A_Args[3] : ""
    _feature_daily_worker_entry(hwnd, stopFile)
    ExitApp()
}

if (A_Args.Length >= 3 and A_Args[1] = "--boss-worker") {
    mode := A_Args[2]
    hwnd := Integer(A_Args[3])
    _boss_worker_entry(mode, hwnd)
    ExitApp()
}

_gui_init()

; Pre-load vocab cache for Q&A features
_hoidap_load_vocab_cache()
_httt_load_vocab_cache()

F3:: {
    hwnds := _win_get_list()
    _click_post(hwnds[1], 615, 508)
    ; _win_resize_game()
    ; hwnd := _win_get_game()
    ; _click_post(hwnd, 135, 177)
    ; Sleep 500
    ; _click_post(hwnd, 838, 520)
    ; Sleep 500
    ; _post_with_vk_string(hwnd, "Esc")
    ; Sleep 500
    ; _post_with_vk_string(hwnd, "Esc")
    ; Sleep 500
    ; _post_with_vk_string(hwnd, "Esc")
}

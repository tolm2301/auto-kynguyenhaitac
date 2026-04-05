#Requires AutoHotkey v2.0

#Include gui\gui_main.ahk
_gui_init()

#Include utils\window.ahk
#Include utils\post_message.ahk
#Include utils\date.ahk
#Include utils\OCR.ahk

#Include features\enhance.ahk
#Include features\rakhoi.ahk
#Include features\stop.ahk
#Include features\test.ahk
#Include features\boss.ahk
#Include features\nammoiphattai.ahk
#Include features\daily.ahk
#Include features\anhhon.ahk
#Include features\tanconghaiquan.ahk
#Include features\hoidapcothuong.ahk
#Include features\giftcode.ahk

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
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

F4::{
    _feature_lich_su_kien()
}

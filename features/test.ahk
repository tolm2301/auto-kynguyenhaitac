_feature_test() {
    _win_resize_game()
    hwnd := _win_get_game()
    global isRunning
    isRunning := true

    ; _drag_mouse(hwnd, 418, 331, 767, 301)
    Sleep 2000
    _post_with_vk_string(hwnd, "1")
}

_feature_change_win() {

    if hwnd := WinExist("Kỷ Nguyên Hải Tặc")
    {
        title := WinGetTitle("ahk_id " hwnd)

        if title = "Kỷ Nguyên Hải Tặc" {
            WinSetTitle "Kỷ Nguyên Hải Tặc 1", "ahk_id " hwnd
        } else {
            WinSetTitle "Kỷ Nguyên Hải Tặc", "ahk_id " hwnd
        }

    }

}

_feature_click() {
    hwnd := _win_get_game()
    global isRunning
    isRunning := true

    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game"
        return
    }


}

_feature_lich_su_kien() {
      MsgBox "T2: Công xưởng smile(18h30-19h00)`n"
      . "T3: Hải tặc thông thái (11h55),  Uta world(19h), Closseum(19h45), Tranh bá trên biển(20h15).`n"
      . "T4: Công xưởng smile(18h30-19h00), Chiến trường(19h45).`n"
      . "T5: Hải tặc thông thái (11h55),  Uta world(19h), Closseum(19h45), Tranh bá trên biển(20h15).`n"
      . "T6: Công xưởng smile(18h30-19h00), Wano(19h45).`n"
      . "T7: Chiến trường(19h45).`n"
      . "Daily: Punk, Kraken, Kaido, Tầm bảo chiến.`n"
      , "Sự Kiện Kỷ Nguyên Hải Tặc"
}
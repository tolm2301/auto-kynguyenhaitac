_feature_test() {
    _win_resize_game()
    hwnd := _win_get_game()
    global isRunning
    isRunning := true

    ; _drag_mouse(hwnd, 418, 331, 767, 301)
    g_featureText.text := "abc"
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
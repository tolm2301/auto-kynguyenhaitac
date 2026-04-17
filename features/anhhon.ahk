_feature_anhhon(count) {
    _win_resize_game()
    g_featureText.text := "Tính năng đang chạy: Ảnh hồn"
    hwnd := _win_get_game()
    global isRunning
    isRunning := true

    try {
        if !hwnd {
            MsgBox "Không tìm thấy cửa sổ game"
            return
        }

        Loop Integer(count) {
            if !isRunning
                return

            _click_post(hwnd, 739, 626)
            Sleep 4000
            _click_post(hwnd, 1170, 184)
            Sleep 3000
            _click_post(hwnd, 627, 634)
            Sleep 3000
        }
    } finally {
        _feature_reset_running_status()
    }
}

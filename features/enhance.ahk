_feature_enhance(count) {
    _win_resize_game()
    g_featureText.text := "Tính năng đang chạy: Cường hoá"
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

            _click_post(hwnd, 930, 530)

            Sleep 300
        }
    } finally {
        _feature_reset_running_status()
    }
}

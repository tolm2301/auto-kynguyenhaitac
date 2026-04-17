_feature_nammoiphattai(count) {
    _win_resize_game()
    g_featureText.text := "Tính năng đang chạy: Năm mới phát tài"
    VK_ESC := 0x1B      

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

            _click_post(hwnd, 716, 443)
            Sleep 500
            _post_key(hwnd, VK_ESC)
            Sleep 1000
        }
    } finally {
        _feature_reset_running_status()
    }
}

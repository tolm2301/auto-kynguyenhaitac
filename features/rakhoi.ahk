_feature_rakhoi(count) {
    _win_resize_game()
    g_featureText.text := "Tính năng đang chạy: Ra khơi"
    hwnd := _win_get_game()
    global isRunning
    isRunning := true

    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game"
        return
    }

    Loop Integer(count) {
        if !isRunning
            return

        _click_post(hwnd, 820, 231)

        Sleep 200

        _click_post(hwnd, 820, 281)

        Sleep 200

        _click_post(hwnd, 413, 481)

        Sleep 200
    }
}

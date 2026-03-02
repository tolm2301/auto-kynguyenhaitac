_feature_tanconghaiquan() {
    _win_resize_game()
    g_featureText.text := "Tính năng đang chạy: Tấn công hải quân"
    hwnd := _win_get_game()
    global isRunning
    isRunning := true

    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game"
        return
    }

    While true {
        if !isRunning
            return
        
        _post_with_vk_string(hwnd, "1")
        Sleep 300
        _click_post(hwnd, 114, 318)
        Sleep 1000
        _post_with_vk_string(hwnd, "2")
        Sleep 300
        _click_post(hwnd, 114, 377)
        Sleep 1000
        _post_with_vk_string(hwnd, "3")
        Sleep 300
        _click_post(hwnd, 114, 426)
        Sleep 1000
        _post_with_vk_string(hwnd, "4")
        Sleep 300
        _click_post(hwnd, 114, 485)
        Sleep 1000
        _post_with_vk_string(hwnd, "5")
        Sleep 300
        _click_post(hwnd, 114, 538)
        Sleep 1000
    }
}
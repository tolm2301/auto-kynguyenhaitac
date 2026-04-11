_feature_register_uta() {
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Register Event"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    Sleep 3000

    for hwnd in hwnds {
       _click_post(hwnd, 729, 35)
        Sleep 3000
        _click_post(hwnd, 414, 523)
        Sleep 2000
        _click_post(hwnd, 338, 200)
        Sleep 2000
        _click_post(hwnd, 746, 556)
        Sleep 1000
        _post_with_vk_string(hwnd, "ESC")
    }
}
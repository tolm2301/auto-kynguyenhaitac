global hoat_dong_button := [662, 39]

_feature_register_uta() {
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Register Event"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    try {
        Sleep 3000

        for hwnd in hwnds {
            _click_post(hwnd, hoat_dong_button[1], hoat_dong_button[2])
            Sleep 3000
            _click_post(hwnd, 414, 523)
            Sleep 2000
            _click_post(hwnd, 338, 200)
            Sleep 2000
            _click_post(hwnd, 746, 556)
            Sleep 1000
            _post_with_vk_string(hwnd, "ESC")
        }
    } finally {
        _feature_reset_running_status()
    }
}

_feature__uta() {
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Uta World"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    try {
        Sleep 5000

        for hwnd in hwnds {
            _click_post(hwnd, 1217, 541)
        }

        Sleep 15000

        for hwnd in hwnds {
            _click_post(hwnd, 219, 64)
        }

        while true {
        if (getHour() = 19 and getMinute() = 30) {
            Sleep 5000
            
            for hwnd in hwnds {
                _click_post(hwnd, 653, 530)
                sleep 1000
                _click_post(hwnd, 1209, 630)
            }

            return
        }
    }

    } finally {
        _feature_reset_running_status()
    }
}


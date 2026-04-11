_now_hour() {
    return Integer(A_Hour)
}

_now_minute() {
    return Integer(A_Min)
}

_feature_punk() {
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Rồng punk"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    Sleep 3000

    for hwnd in hwnds {
        _click_post(hwnd, 729, 35)
        Sleep 3000
        _click_post(hwnd, 339, 200)
        Sleep 1000
        _click_post(hwnd, 893, 558)
        Sleep 2000
        _click_post(hwnd, 680, 73)
        Sleep 1000
    }

    for hwnd in hwnds {
        _multi_click_post(hwnd, 582, 145, 10)
        Sleep 1000
    }

    endTick := A_TickCount + 15 * 60 * 1000
    while true {
        if !isRunning
            return
        if (A_TickCount >= endTick) {
            Sleep 5000
            for hwnd in hwnds {
                _post_with_vk_string(hwnd, "ESC")
            }

            return
        }

        for hwnd in hwnds {
            _click_post(hwnd, 748, 156)
        }
        Sleep 2000
    }
}

_feature_kraken() {
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Kraken"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    Sleep 3000

    for hwnd in hwnds {
        _click_post(hwnd, 729, 35)
        Sleep 3000
        _click_post(hwnd, 402, 259)
        Sleep 1000
        _click_post(hwnd, 893, 558)
        Sleep 2000
        _click_post(hwnd, 680, 73)
        Sleep 1000
    }

    for hwnd in hwnds {
        _multi_click_post(hwnd, 582, 145, 10)
        Sleep 1000
    }

    endTick := A_TickCount + 15 * 60 * 1000
    while true {
        if !isRunning
            return
        if (A_TickCount >= endTick) {
            Sleep 5000
            for hwnd in hwnds {
                _post_with_vk_string(hwnd, "ESC")
            }

            return
        }

        for hwnd in hwnds {
            _click_post(hwnd, 748, 156)
        }
        Sleep 2000
    }
}

_feature_kaido() {
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Kraken"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    Sleep 3000

    for hwnd in hwnds {
        if !isRunning
            return
        _click_post(hwnd, 1125, 541)
        Sleep 5000
        _click_post(hwnd, 1129, 122)
        Sleep 1000
        _click_post(hwnd, 1129, 173)
        Sleep 1000
    }

    return
}
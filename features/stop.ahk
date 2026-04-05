_feature_stop() {
    g_featureText.text := "Tính năng đang chạy: Chưa có"
    global isRunning
    isRunning := false
}

_feature_tam_bao_chien() {

    global FEATUE_SLEEP := 4000
    global LOAD_SLEEP := 1500
    global TBC_SLEEP := 60 * 30 + 10

    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Tầm bảo chiến"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    count := 0

    for hwnd in hwnds {
        _click_post(hwnd, 1218, 538)
    }
    Sleep 20000
    for hwnd in hwnds {
        _click_post(hwnd, 1213, 52)
    }
    Sleep FEATUE_SLEEP

    while true {
        if !isRunning
            return

        if Integer(count) >= Integer(TBC_SLEEP) or Integer(count) = Integer(0) {
            for hwnd in hwnds {
                _click_post(hwnd, 1218, 538)
                Sleep FEATUE_SLEEP
                _click_post(hwnd, 1142, 52)
                Sleep LOAD_SLEEP
                _click_post(hwnd, 615, 507)
                Sleep LOAD_SLEEP
                _click_post(hwnd, 790, 490)
                Sleep LOAD_SLEEP
                _post_with_vk_string(hwnd, "enter")
                Sleep LOAD_SLEEP
                _multi_click_post(hwnd, 918, 181, 3, 700)
                Sleep LOAD_SLEEP
            }

            for hwnd in hwnds {

                _click_post(hwnd, 632, 587)
                Sleep LOAD_SLEEP
                _click_post(hwnd, 1213, 52)
                Sleep LOAD_SLEEP
            }

            count := 1
        }

        count := count + 1
        Sleep 1000
    }
}
_feature_reset_running_status() {
    global g_featureText
    if (IsSet(g_featureText))
        g_featureText.text := "Tính năng đang chạy: Chưa có"
}

_feature_stop() {
    global g_dailyStopFile, g_dailyWorkerPids, g_bossWorkerPids

    _feature_reset_running_status()

    global isRunning
    isRunning := false

    if (IsSet(g_dailyStopFile) and g_dailyStopFile != "")
        _daily_signal_stop(g_dailyStopFile)

    if (IsSet(g_dailyWorkerPids))
        _daily_stop_worker_processes(g_dailyWorkerPids)

    if (IsSet(g_bossWorkerPids))
        _boss_stop_worker_processes(g_bossWorkerPids)

    g_dailyWorkerPids := []
    g_dailyStopFile := ""
    g_bossWorkerPids := []
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

    try {
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

            if (Integer(getHour()) = Integer(15)) {
                _feature_reset_running_status()
                return
            }

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
    } finally {
        _feature_reset_running_status()
    }
}

_feature_punk() {
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Rồng punk"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    while true {
        if !isRunning
            return

        if getHour() = 15 and getMinute() = 30 {
            Sleep 3000

            for hwnd in hwnds {
                _click_post(hwnd, 729, 35)
                Sleep 2000
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

            while true {
                if !isRunning
                    return

                if getHour() = 15 and getMinute() = 45 {
                    return
                }

                for hwnd in hwnds {
                    _click_post(hwnd, 748, 156)
                }
                Sleep 2000
            }

            return
        }

        if getHour() = 15 and getMinute() > 30 {
            while true {
                if !isRunning
                    return

                if getHour() = 15 and getMinute() = 45 {
                    return
                }
                for hwnd in hwnds {
                    _click_post(hwnd, 748, 156)
                }
                Sleep 2000
            }

            return
        }


        Sleep 1000
    }
}

_feature_kraken() {
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Kraken"
    hwnds := _win_get_list()
    global isRunning
    isRunning := true

    while true {
        if !isRunning
            return

        if getHour() = 21 and getMinute() = 00 {
            Sleep 3000

            for hwnd in hwnds {
                _click_post(hwnd, 729, 35)
                Sleep 1000
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

            while true {
                if !isRunning
                    return
                if getHour() = 21 and getMinute() = 15 {
                    return
                }
                for hwnd in hwnds {
                    _click_post(hwnd, 748, 156)
                }
                Sleep 2000
            }

            return
        }

        if getHour() = 21 and getMinute() > 00 {

            while true {
                if !isRunning
                    return
                if getHour() = 21 and getMinute() = 15 {
                    return
                }
                for hwnd in hwnds {
                    _click_post(hwnd, 748, 156)
                }
                Sleep 2000
            }

            return
        }

        Sleep 1000
    }
}
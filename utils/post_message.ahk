_click_post(hwnd, x, y) {

    lParam := (y << 16) | (x & 0xFFFF)

    ; WM_LBUTTONDOWN
    PostMessage 0x201, 1, lParam, , hwnd
    Sleep 30
    ; WM_LBUTTONUP
    PostMessage 0x202, 0, lParam, , hwnd
}

_multi_click_post(hwnd, x, y, count, sleepTime := 500) {
    Loop Integer(count) {
        _click_post(hwnd, x, y)
        Sleep sleepTime
    }
}

_drag_mouse(hwnd, x1, y1, x2, y2) {
    global isRunning
    if !isRunning
        return

    if !hwnd {
        MsgBox("Không tìm thấy cửa sổ game.")
        return
    }

    lParam1 := (y1 << 16) | (x1 & 0xFFFF)
    lParam2 := (y2 << 16) | (x2 & 0xFFFF)

    PostMessage 0x201, 0, lParam1, , hwnd
    Sleep 200

    steps := 25
    Loop steps {
        if !isRunning
            return

        intermediateX := x1 + ((x2 - x1) * A_Index) / steps
        intermediateY := y1 + ((y2 - y1) * A_Index) / steps

        lParamMove := (Integer(intermediateY) << 16) | (Integer(intermediateX) & 0xFFFF)

        PostMessage 0x200, 0, lParamMove, , hwnd
        Sleep 10
    }

    PostMessage 0x201, 0, lParam2, , hwnd
    Sleep 100
    PostMessage 0x202, 0, lParam2, , hwnd
}

_post_key(hwnd, vkCode) {
    WM_KEYDOWN := 0x100
    WM_KEYUP := 0x101

    sc := GetKeySC(Format("vk{:x}", vkCode))

    lParamDown := (sc << 16) | 1
    lParamUp := (sc << 16) | 0xC0000001

    PostMessage(WM_KEYDOWN, vkCode, lParamDown, , hwnd)
    Sleep(10)
    PostMessage(WM_KEYUP, vkCode, lParamUp, , hwnd)
}

_post_with_vk_string(hwnd, vk_string) {
    vk := GetKeyVK(vk_string)
    vk_code := Format("0x{:X}", vk)
    _post_key(hwnd, vk_code)
}
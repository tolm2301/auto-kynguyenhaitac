_feature_giftcode(codes) {
    global isRunning
    isRunning := true

    if !codes or Trim(codes) = "" {
        MsgBox "Vui lòng nhập gift code!"
        return
    }

    hwnd := _win_get_game()
    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game!"
        return
    }

    codeList := StrSplit(codes, "`n", "`r")
    Loop codeList.Length {
        if !isRunning
            return

        code := Trim(codeList[A_Index])
        if code = ""
            continue

        _feature_giftcode_input(hwnd, code)
        Sleep 300
    }
}

_feature_giftcode_pattern(prefix, count) {
    global isRunning
    isRunning := true

    if !prefix or Trim(prefix) = "" {
        MsgBox "Vui lòng nhập prefix!"
        return
    }

    hwnd := _win_get_game()
    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game!"
        return
    }

    Loop count {
        if !isRunning
            return

        code := _generate_code(prefix)
        _feature_giftcode_input(hwnd, code)
        Sleep 300
    }
}

_generate_code(prefix) {
    rand_num := Random(0, 100)
    suffix := ""
    chars := "abcdefghijklmnopqrstuvwxyz0123456789"

    Loop 14 {
        idx := Random(1, 36)
        suffix .= SubStr(chars, idx, 1)
    }

    return prefix . "_" . rand_num . "-" . suffix
}

_feature_giftcode_input(hwnd, code) {
    CoordMode("Mouse", "Screen")

    clickGiftcodeBtnX := 273
    clickGiftcodeBtnY := 73
    clickInputX := 620
    clickInputY := 343
    clickSubmitX := 739
    clickSubmitY := 343

    _click_post(hwnd, clickGiftcodeBtnX, clickGiftcodeBtnY)
    Sleep 50

    _click_post(hwnd, clickInputX, clickInputY)
    Sleep 50

    _post_string(hwnd, code)
    Sleep 100

    _click_post(hwnd, clickSubmitX, clickSubmitY)
    Sleep 100

    _post_with_vk_string(hwnd, "ESC")
    Sleep 100
}

_post_string(hwnd, str) {
    Loop Parse, str {
        ch := A_LoopField
        charCode := Ord(ch)
        PostMessage(0x0102, charCode, 1, , hwnd)
        Sleep(5)
    }
}

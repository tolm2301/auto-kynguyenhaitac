_win_is_browser_process(processName) {
    processName := StrLower(processName)
    browserSet := Map(
        "chrome.exe", true,
        "msedge.exe", true,
        "firefox.exe", true,
        "brave.exe", true,
        "opera.exe", true,
        "opera_gx.exe", true,
        "iexplore.exe", true
    )
    return browserSet.Has(processName)
}

_win_is_game_window(hwnd) {
    title := WinGetTitle("ahk_id " . hwnd)
    if !InStr(title, "Kỷ Nguyên Hải Tặc")
        return false

    processName := WinGetProcessName("ahk_id " . hwnd)
    if _win_is_browser_process(processName)
        return false

    return true
}

_win_get_game() {
    hwnds := _win_get_list()
    if (hwnds.Length = 0) {
        MsgBox "Không tìm thấy cửa sổ game"
        Exit()
    }

    return hwnds[1]
}

_win_get_game_1() {
    hwnd := WinExist("Kỷ Nguyên Hải Tặc 1")

    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game"
        Exit()
    }

    return hwnd
}

_win_get_list() {
    hwnds := []
    allHwnds := WinGetList()

    for hwnd in allHwnds {
        if _win_is_game_window(hwnd)
            hwnds.Push(hwnd)
    }

    if (hwnds.Length = 0) {
        MsgBox "Không tìm thấy cửa sổ game"
        Exit()
    }

    return hwnds
}

_win_resize_list() {
    ; Cho phép tìm cả cửa sổ đang ẩn (Hidden)
    DetectHiddenWindows True

    hwnds := _win_get_list()

    for hwnd in hwnds {
        try {
            ; Lấy vị trí X, Y hiện tại để không làm lệch cửa sổ
            WinGetPos(&winX, &winY, , , hwnd)

            ; Cú pháp DllCall SetWindowPos:
            ; hWnd, hWndInsertAfter, X, Y, cx (Width), cy (Height), uFlags
            ; Flag 0x0010 (SWP_NOACTIVATE): Không kích hoạt cửa sổ
            ; Flag 0x0040 (SWP_SHOWWINDOW): Hiển thị nếu nó đang ẩn (tùy chọn)
            ; Flag 0x0200 (SWP_NOREPOSITION): Không thay đổi thứ tự Z-order

            DllCall("User32.dll\SetWindowPos",
                "Ptr", hwnd,
                "Ptr", 0,
                "Int", winX,
                "Int", winY,
                "Int", 1280,
                "Int", 720,
                "UInt", 0x0010 | 0x0200
            )
        }
    }
}

_win_resize_game() {
    hwnd := _win_get_game()
    try {
        ; Lấy vị trí X, Y hiện tại để không làm lệch cửa sổ
        WinGetPos(&winX, &winY, , , hwnd)

        ; Cú pháp DllCall SetWindowPos:
        ; hWnd, hWndInsertAfter, X, Y, cx (Width), cy (Height), uFlags
        ; Flag 0x0010 (SWP_NOACTIVATE): Không kích hoạt cửa sổ
        ; Flag 0x0040 (SWP_SHOWWINDOW): Hiển thị nếu nó đang ẩn (tùy chọn)
        ; Flag 0x0200 (SWP_NOREPOSITION): Không thay đổi thứ tự Z-order

        DllCall("User32.dll\SetWindowPos",
            "Ptr", hwnd,
            "Ptr", 0,
            "Int", winX,
            "Int", winY,
            "Int", 1280,
            "Int", 720,
            "UInt", 0x0010 | 0x0200
        )
    }
}

_win_resize_game_1() {

    hwnd1 := _win_get_game_1()
    try {
        ; Lấy vị trí X, Y hiện tại để không làm lệch cửa sổ
        WinGetPos(&winX, &winY, , , hwnd1)

        ; Cú pháp DllCall SetWindowPos:
        ; hWnd, hWndInsertAfter, X, Y, cx (Width), cy (Height), uFlags
        ; Flag 0x0010 (SWP_NOACTIVATE): Không kích hoạt cửa sổ
        ; Flag 0x0040 (SWP_SHOWWINDOW): Hiển thị nếu nó đang ẩn (tùy chọn)
        ; Flag 0x0200 (SWP_NOREPOSITION): Không thay đổi thứ tự Z-order

        DllCall("User32.dll\SetWindowPos",
            "Ptr", hwnd1,
            "Ptr", 0,
            "Int", winX,
            "Int", winY,
            "Int", 1280,
            "Int", 720,
            "UInt", 0x0010 | 0x0200
        )
    }
}

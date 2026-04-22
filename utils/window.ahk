global g_ocr_debug_mode := false

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

_ocr_from_bit_map(hwnd, x1, y1, x2, y2, ocrOptions := 0, scale := 2.0) {
    global g_ocr_debug_mode
    startedAt := A_TickCount

    x := x1
    y := y1
    w := Max(1, x2 - x1)
    h := Max(1, y2 - y1)
    scaleFactor := (scale > 0) ? scale : 1.0
    scaledW := Max(1, Round(w * scaleFactor))
    scaledH := Max(1, Round(h * scaleFactor))
    debugPath := ""
    captureStartedAt := A_TickCount

    hdcWindow := DllCall("GetDC", "Ptr", hwnd, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcWindow, "Ptr")
    hbm := DllCall("CreateCompatibleBitmap", "Ptr", hdcWindow, "Int", scaledW, "Int", scaledH, "Ptr")

    oldObj := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hbm, "Ptr")
    DllCall("SetStretchBltMode", "Ptr", hdcMem, "Int", 4) ; HALFTONE
    DllCall("StretchBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", scaledW, "Int", scaledH, "Ptr", hdcWindow, "Int", x, "Int", y, "Int", w, "Int", h, "UInt", 0x00CC0020)
    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", oldObj)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", hdcWindow)

    ; DEBUG SAVE - thêm lại đơn giản
    if g_ocr_debug_mode {
        try {
            debugDir := A_ScriptDir . "\logs\ocr_debug"
            DirCreate(debugDir)
            stamp := FormatTime(A_Now, "yyyyMMdd_HHmmss")
            ; Lưu với tên gồm: question/option + timestamp
            debugPath := debugDir . "\ocr_" . stamp . "_x" . x . "_y" . y . "_s" . scaleFactor . ".png"
            _ocr_save_bitmap_to_file(hbm, debugPath)
            OutputDebug("[OCR_DEBUG] Saved: " debugPath)
        }
    }

    captureElapsedMs := A_TickCount - captureStartedAt
    debugContext := Map(
        "hwnd", hwnd,
        "region", Format("x={1},y={2},w={3},h={4}", x, y, w, h),
        "scale", scaleFactor,
        "scaledSize", Format("{1}x{2}", scaledW, scaledH),
        "debugImagePath", debugPath,
        "captureElapsedMs", captureElapsedMs
    )

    runtimeOptions := Map()
    if IsObject(ocrOptions) {
        for key, value in ocrOptions
            runtimeOptions[key] := value
    }
    runtimeOptions["debugContext"] := debugContext

    _ocr_worker_trace_capture_request(debugContext)
    result := _ocr_worker_from_hbitmap(hbm, runtimeOptions)
    text := result["ok"] ? result["text"] : ""
    _ocr_worker_trace_capture_result(debugContext, result, A_TickCount - startedAt)

    DllCall("DeleteObject", "Ptr", hbm)

    return _normalize_ocr_text(text)
}

; Thêm helper đơn giản save bitmap
_ocr_save_bitmap_to_file(hbm, filePath) {
    gdipToken := 0
    pBitmap := 0

    try {
        if !hbm
            throw Error("Invalid HBITMAP (0)")

        hGdip := DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
        if !hGdip {
            hGdip := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
            if !hGdip
                throw Error("LoadLibrary(gdiplus) failed. LastError=" . A_LastError)
        }

        startupInput := Buffer(16 + (A_PtrSize * 2), 0)
        NumPut("UInt", 1, startupInput, 0)

        status := DllCall("gdiplus\GdiplusStartup", "Ptr*", &gdipToken, "Ptr", startupInput, "Ptr", 0, "UInt")
        if (status != 0)
            throw Error("GdiplusStartup failed. status=" . status)

        status := DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hbm, "Ptr", 0, "Ptr*", &pBitmap, "UInt")
        if (status != 0 || !pBitmap)
            throw Error("GdipCreateBitmapFromHBITMAP failed. status=" . status)

        pngClsid := Buffer(16, 0)
        hr := DllCall("ole32\CLSIDFromString", "WStr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", pngClsid, "UInt")
        if (hr != 0)
            throw Error("CLSIDFromString(PNG) failed. hr=" . Format("0x{:08X}", hr))

        status := DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", filePath, "Ptr", pngClsid, "Ptr", 0, "UInt")
        if (status != 0)
            throw Error("GdipSaveImageToFile failed. status=" . status . " path=" . filePath)
    } finally {
        if pBitmap
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        if gdipToken
            DllCall("gdiplus\GdiplusShutdown", "Ptr", gdipToken)
    }
}

_normalize_ocr_text(text) {
    diacritic_map := Map(
        "à","a","á","a","ả","a","ã","a","ạ","a",
        "â","a","ầ","a","ấ","a","ẩ","a","ẫ","a","ậ","a",
        "ă","a","ằ","a","ắ","a","ẳ","a","ẵ","a","ặ","a",
        "è","e","é","e","ẻ","e","ẽ","e","ẹ","e",
        "ê","e","ề","e","ế","e","ể","e","ễ","e","ệ","e",
        "ì","i","í","i","ỉ","i","ĩ","i","ị","i",
        "ò","o","ó","o","ỏ","o","õ","o","ọ","o",
        "ô","o","ồ","o","ố","o","ổ","o","ỗ","o","ộ","o",
        "ơ","o","ờ","o","ớ","o","ở","o","ỡ","o","ợ","o",
        "ù","u","ú","u","ủ","u","ũ","u","ụ","u",
        "ư","u","ừ","u","ứ","u","ử","u","ữ","u","ự","u",
        "ỳ","y","ý","y","ỷ","y","ỹ","y","ỵ","y",
        "Đ","d","đ","d"
    )
    
    result := ""
    loop parse text {
        c := A_LoopField
        result .= diacritic_map.Has(c) ? diacritic_map[c] : c
    }

    result := StrReplace(result, " ")
    result := StrReplace(result, "cauhoi")
    
    return  result
}
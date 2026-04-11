_win_get_game() {
    hwnd := WinExist("Kỷ Nguyên Hải Tặc", , "1")

    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game"
        Exit()
    }

    return hwnd
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
    hwnds := WinGetList("Kỷ Nguyên Hải Tặc")

    if !hwnds {
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

_ocr_from_bit_map(hwnd, x1, y1, x2, y2) {
    x := x1
    y := y1
    w := x2 - x1
    h := y2 - y1

    hdcWindow := DllCall("GetDC", "Ptr", hwnd)
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcWindow)
    hbm := DllCall("CreateCompatibleBitmap", "Ptr", hdcWindow, "Int", w, "Int", h)
    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hbm)
    DllCall("BitBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdcWindow, "Int", x, "Int", y, "UInt", 0x00CC0020)
    DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", hdcWindow)
    DllCall("DeleteDC", "Ptr", hdcMem)

    result := OCR.FromBitmap(hbm)
    DllCall("DeleteObject", "Ptr", hbm)

    text := result.Text

    ; Normalize text bị lỗi encode
    text := _normalize_ocr_text(text)

    return text
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
    
    return FixOCRErrors(result)
}


FixOCRErrors(inputText) {
    static ocr_map := Map(
        "ngLr i choi khic","nguoi choi khac",
        "men phi","mien phi",
        "Qu NVHN","Qua NVHN",
        "BikipNvo","Bi kip Vo",
        "fri_r ng","truong",
        "Fl_r ng","Trong",
        "bl_r ng","buoc",
        "fr nh","trong",
        "dl_r c","duoc",
        "n lei","co loi",
        "N vuc","Khu vuc",
        "Ho n","Hoan",
        "lirn m i","lam moi",
        "ce nh n","co nhan",
        "hing ng y","hang ngay",
        "T l y","Tuy y",
        "Khi u chien","Kieu chien",
        "Ho ng","Hoang",
        "Dizm","Diem",
        "Chizu","Chiu",
        "m6i","moi",
        "V ng","Vang",
        "L m","Lam",
        "M t","Mot",
        "L n","Lan",
        "D u","Dau",
        "c a","cua",
        "c u","cua",
        "v i","voi",
        "N. vucöco loi","Khu vuc co loi",
        "Hoän fränh","Hoan thanh",
        "dl_røc","duoc",
        "ngäy","ngay",
        "tät","tat",
        "Mö tå","Mo ta",
        "Khiäu chien","Kieu chien",
        "Däu","Dau",
        "bl_röng","buoc",
        "Häy","Hay",
        "nhüng","nhung",
        "ngLröi","nguoi",
        "khic","khac",
        "Fl_röng","Trong",
        "chüng","chung",
        "cüa","cua",
        "fri_röng","truong",
        "Quå","Qua",
        "Hoång","Hoang",
        "Chiu mö","Chiu mo",
        "T.lüy","Tich luy",
        "Läm moi","Lam moi",
        "ce nhän","co nhan",
        "lirn möi","lam moi",
        "cäu Fei","cua phe"
    )
    
    static sorted_keys := 0
    if !sorted_keys {
        sorted_keys := []
        for wrong in ocr_map
            sorted_keys.Push(wrong)
        ; Insertion sort - O(n^2) nhưng n nhỏ nên không vấn đề
        loop sorted_keys.Length {
            i := A_Index
            while i > 1 && StrLen(sorted_keys[i]) > StrLen(sorted_keys[i-1]) {
                temp := sorted_keys[i], sorted_keys[i] := sorted_keys[i-1], sorted_keys[i-1] := temp, i--
            }
        }
    }
    
    result := inputText
    for wrong in sorted_keys {
        pattern := StrReplace(wrong, "\", "\\")
        pattern := StrReplace(pattern, ".", "\.")
        result := RegExReplace(result, "i)" . pattern, ocr_map[wrong])
    }
    
    return RegExReplace(result, "\s+", " ")
}
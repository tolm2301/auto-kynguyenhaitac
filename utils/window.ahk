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
    hwnds := _win_get_list()

    for hwnd in hwnds {
        WinGetPos &winX, &winY, &winWidth, &winHeight, hwnd

        WinActivate hwnd
        WinMove winX, winY, 1280, 720, hwnd
    }
}

_win_resize_game() {
    hwnd := _win_get_game()
    ; Lấy vị trí và kích thước hiện tại của cửa sổ game
    WinGetPos &winX, &winY, &winWidth, &winHeight, hwnd

    WinActivate hwnd
    WinMove winX, winY, 1280, 720, hwnd
}

_win_resize_game_1() {

    hwnd1 := _win_get_game_1()
    ; Lấy vị trí và kích thước hiện tại của cửa sổ game
    WinGetPos &winX, &winY, &winWidth, &winHeight, hwnd1

    WinActivate hwnd1
    WinMove winX, winY, 1280, 720, hwnd1
}
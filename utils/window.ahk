_win_get_game() {
    hwnd := WinExist("Kỷ Nguyên Hải Tặc",,"1")

    if !hwnd {
        MsgBox "Không tìm thấy cửa sổ game"
        Exit()
    }

    return hwnd
}

_win_resize_game() {

    hwnd := _win_get_game()
    ; Lấy vị trí và kích thước hiện tại của cửa sổ game
    WinGetPos &winX, &winY, &winWidth, &winHeight, hwnd

    WinActivate hwnd
    WinMove winX, winY, 1280, 720, hwnd
}
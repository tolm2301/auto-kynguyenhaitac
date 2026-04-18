---
name: process-and-window-guards
description: Verify HWND, PID, title, and active state before automation steps
compatibility: opencode
metadata:
  domain: ahk2
  area: guards
---

## What I do
- Xác định đúng cửa sổ game giữa nhiều window đang mở
- Lọc process browser để tránh click nhầm tab web game
- Resize cửa sổ game về chuẩn 1280x720 nhưng giữ nguyên vị trí và không activate

## Key Patterns (from real project)
- Multi-window detection: `WinGetList()` -> `_win_is_game_window(hwnd)`
- Title guard bắt buộc chứa `"Kỷ Nguyên Hải Tặc"`
- Browser filtering theo process name (`chrome.exe`, `msedge.exe`, `firefox.exe`, `brave.exe`, ...)
- Preserve vị trí trước resize: `WinGetPos(&winX, &winY, , , hwnd)`
- `SetWindowPos` với `0x0010 | 0x0200` (`SWP_NOACTIVATE | SWP_NOREPOSITION`)

## Code Examples
```autohotkey
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

_win_resize_game() {
    hwnd := _win_get_game()
    try {
        WinGetPos(&winX, &winY, , , hwnd)

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
```

## Implementation Details
- Guard đầu tiên là title match, guard thứ hai là process blacklist browser.
- Luôn lấy list hwnd từ hệ thống rồi filter, thay vì assume 1 window cố định.
- Resize dùng DllCall giúp ổn định cho nhiều cửa sổ, không làm đổi focus đang thao tác tay.
- Khi không có window hợp lệ, dừng sớm bằng `MsgBox + Exit()` để tránh automation mù.

## Timing & Constants
- Target size chuẩn: `1280 x 720`
- SetWindowPos flags: `0x0010 | 0x0200`
- Browser blacklist: `chrome/msedge/firefox/brave/opera/opera_gx/iexplore`
- Game title keyword: `Kỷ Nguyên Hải Tặc`

## Checklist
1. Dùng `_win_get_list()` trước mọi vòng auto đa cửa sổ.
2. Kiểm tra title + process name trước khi nhận hwnd là game.
3. Resize giữ nguyên `winX/winY`, không hard-code vị trí.
4. Không activate cưỡng bức nếu dùng PostMessage input.
5. Nếu không tìm thấy window, fail-fast ngay.

## Common Mistakes
- Chỉ lọc theo title, không lọc process -> dính cửa sổ browser có tiêu đề tương tự.
- Resize với tọa độ cố định làm văng layout người dùng.
- Gửi input vào hwnd cũ không còn tồn tại vì không refresh danh sách window.
- Dùng `WinActivate` liên tục gây giật focus không cần thiết.

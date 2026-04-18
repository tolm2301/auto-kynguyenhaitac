# Window Management (`utils/window.ahk`)

## Overview

`utils/window.ahk` quản lý 3 việc cốt lõi:

1. Nhận diện cửa sổ game hợp lệ
2. Lọc nhầm browser window
3. Chuẩn hóa kích thước emulator về `1280x720`

---

## Implementation

## 1) Multi-window detection logic

Luồng detect chính:

```text
_win_get_list()
  -> WinGetList()
  -> for each hwnd: _win_is_game_window(hwnd)
       -> title contains "Kỷ Nguyên Hải Tặc"
       -> processName NOT in browser set
  -> trả về mảng hwnd hợp lệ
```

### Browser filtering

`_win_is_browser_process(processName)` dùng `Map` blacklist:

| Process bị loại | Giá trị |
|---|---|
| chrome.exe | true |
| msedge.exe | true |
| firefox.exe | true |
| brave.exe | true |
| opera.exe | true |
| opera_gx.exe | true |
| iexplore.exe | true |

Khi `_win_is_game_window()` thấy process thuộc map trên thì trả `false`.

---

## 2) `_win_resize_game()` / `_win_resize_list()` với SetWindowPos

### Kỹ thuật

- Lấy vị trí hiện tại bằng `WinGetPos(&winX, &winY, , , hwnd)`
- Gọi `DllCall("User32.dll\SetWindowPos", ...)`
- Giữ nguyên X/Y, đổi size về `1280x720`
- Không activate window

### DllCall parameters

| Param | Value trong code | Ý nghĩa |
|---|---|---|
| `hWnd` | `hwnd` | Cửa sổ target |
| `hWndInsertAfter` | `0` | Không đổi thứ tự đặc biệt |
| `X` / `Y` | `winX` / `winY` | Giữ vị trí hiện tại |
| `cx` / `cy` | `1280` / `720` | Kích thước chuẩn |
| `uFlags` | `0x0010 | 0x0200` | `SWP_NOACTIVATE` + `SWP_NOREPOSITION` |

### Flag sử dụng

| Flag | Hex | Mô tả |
|---|---|---|
| SWP_NOACTIVATE | `0x0010` | Không lấy focus |
| SWP_NOREPOSITION | `0x0200` | Không đổi Z-order |

> Ghi chú: comment trong file có nhắc `SWP_SHOWWINDOW (0x0040)` nhưng hiện tại không OR flag này.

---

## Key Functions

| Function | Vai trò |
|---|---|
| `_win_is_browser_process(processName)` | Kiểm tra process có phải browser |
| `_win_is_game_window(hwnd)` | Validate title + loại browser |
| `_win_get_list()` | Trả danh sách tất cả game windows |
| `_win_get_game()` | Lấy window đầu tiên |
| `_win_resize_list()` | Resize toàn bộ windows trong list |
| `_win_resize_game()` | Resize 1 window đầu tiên |

---

## Data Structures

| Name | Type | Nội dung |
|---|---|---|
| `browserSet` | Map | tập process browser để exclude |
| `hwnds` | Array | danh sách cửa sổ game |

---

## Timing

- Không có timer nội bộ riêng trong `window.ahk`.
- Resize/detect chạy theo lời gọi từ GUI hoặc feature.

---

## Error Handling

- `_win_get_list()` và `_win_get_game()`:
  - nếu không có cửa sổ hợp lệ thì `MsgBox "Không tìm thấy cửa sổ game"` + `Exit()`.
- `_win_resize_*()` có `try` bọc thao tác resize mỗi cửa sổ.

---

## TODO

1. Tách hard-code title game (`"Kỷ Nguyên Hải Tặc"`) vào config chung.
2. Bổ sung check PID/Exe whitelist cho emulator process (đang chủ yếu dựa title + browser blacklist).
3. Trả lỗi dạng object `{ok, err}` thay vì `MsgBox + Exit()` để dễ test/unit flow.

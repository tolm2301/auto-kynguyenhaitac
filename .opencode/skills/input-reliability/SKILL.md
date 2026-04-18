---
name: input-reliability
description: Make AHK2 input actions reliable with focus checks and safe timing
compatibility: opencode
metadata:
  domain: ahk2
  area: input
---

## What I do
- Ưu tiên PostMessage click/key để giảm phụ thuộc focus window
- Chuẩn hoá multi-click, drag và key post theo vk
- Giữ nhịp sleep nhỏ giữa down/up để game nhận input ổn định

## Key Patterns (from real project)
- `_click_post(hwnd, x, y)` dùng `WM_LBUTTONDOWN/UP`
- `_multi_click_post(hwnd, x, y, count, sleepTime)` để spam action có kiểm soát
- `_post_with_vk_string(hwnd, vk_string)` gửi virtual key
- Không cần `WinActivate` trước click khi dùng PostMessage

## Code Examples
```autohotkey
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
```

## Implementation Details
- Toạ độ click luôn encode vào `lParam` bằng `(y << 16) | (x & 0xFFFF)`.
- Nhịp click chuẩn: down -> sleep ngắn -> up, giảm miss click trong game.
- Multi-click dùng vòng lặp integer + delay tuỳ chỉnh theo feature.
- Keyboard input chuyển từ string key (`"ESC"`, `"Enter"`) sang VK trước khi gửi.
- Kết hợp với window guard (`hwnd` hợp lệ) để tránh post nhầm process.

## Timing & Constants
- Click down/up gap: `Sleep 30`
- Key down/up gap: `Sleep(10)`
- Multi-click default delay: `500 ms` (có thể override)
- Một số feature override delay lớn (vd `1000 ms`) để khớp animation game

## Checklist
1. Luôn có `hwnd` hợp lệ trước khi `_click_post`.
2. Ưu tiên PostMessage cho click/key lặp nhiều lần.
3. Delay phải đủ để game nhận state (không spam 0ms).
4. Dùng `_multi_click_post` thay vì copy-paste nhiều `_click_post`.
5. Key đặc biệt (ESC/ENTER) gửi qua `_post_with_vk_string`.

## Common Mistakes
- Quên mask `x & 0xFFFF` làm sai `lParam` ở vài tọa độ.
- Bỏ sleep giữa down/up khiến click bị nuốt.
- Dùng `SendInput` khi window không focus rồi nghĩ game lỗi.
- Spam click quá nhanh làm desync với UI transition.

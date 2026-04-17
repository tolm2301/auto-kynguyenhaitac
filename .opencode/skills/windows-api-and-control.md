# Windows API and Control Skill (AHK2)

## Mục tiêu
Ưu tiên automation theo window/control trước khi dùng click tọa độ để tăng độ bền script.

## Thứ tự ưu tiên chiến lược
1. `ControlClick` / `ControlSend` theo ClassNN hoặc control handle.
2. `PostMessage` / `SendMessage` vào control/window cụ thể.
3. `WinActivate + SendInput`.
4. `Click x,y` (chỉ khi không còn lựa chọn khác).

## Wrapper mẫu cho Win API

```autohotkey
class WinApi {
    static FindWindow(title) {
        return WinExist(title)
    }

    static SetForeground(hwnd) {
        return DllCall("user32\SetForegroundWindow", "ptr", hwnd, "int")
    }

    static SendMsg(hwnd, msg, wParam := 0, lParam := 0) {
        return DllCall("user32\SendMessageW"
            , "ptr", hwnd
            , "uint", msg
            , "uptr", wParam
            , "uptr", lParam
            , "uptr")
    }
}
```

## Control pattern

```autohotkey
ActivateAndClick(winTitle, controlName) {
    if !WinExist(winTitle)
        throw Error("Window not found: " winTitle)

    WinActivate(winTitle)
    if !WinWaitActive(winTitle, , 2)
        throw Error("Cannot activate: " winTitle)

    ControlClick(controlName, winTitle)
}
```

## Checklist ổn định
1. Xác minh đúng window: title + pid nếu cần.
2. Luôn có timeout cho `WinWait*`.
3. Dùng retry khi control phản hồi chậm.
4. Log rõ bước fail: window, control, action.

---
name: gui-automation
description: Build stable AHK2 GUIs and bind automation features cleanly
compatibility: opencode
metadata:
  domain: ahk2
  area: gui
---

## What I do
- Dựng GUI nhiều tab (Main/Boss/Phụ trợ) cho auto game
- Bind button trực tiếp vào `_feature_*` và cập nhật status text runtime
- Chạy timer nền 60s để refresh thông tin lịch event
- Chuẩn hoá pattern `try/finally -> _feature_reset_running_status()` cho mọi flow

## Key Patterns (from real project)
- Multi-tab GUI với `AddTab([..."Main", "Boss", "Phụ trợ"])`
- Event timer 60 giây: `SetTimer(_update_event_text, 60000)`
- Feature status binding: `g_featureText.Text := "Tính năng đang chạy: ..."`
- Fast init/quick setup dùng `g_inputCount` truyền vào feature support
- Reset status tập trung bằng `_feature_reset_running_status()`

## Code Examples
```autohotkey
_gui_init() {
    global g_inputCount, isRunning, g_featureText, g_nextEventText, g_nextEventControl

    myGui := Gui("+Resize +MinSize340x500", "Auto VHT - Control Panel")
    myGui.AddGroupBox("x14 y56 w332 h72", "Thiết lập nhanh")
    g_inputCount := myGui.AddEdit("x130 y84 w64 h26 vInputCount", "1")

    g_featureText := myGui.AddText("x14 y134 w332 h24 +0x200", "Tính năng đang chạy: Chưa có")
    myTab := myGui.AddTab("x" guiCfg.tabX " y" guiCfg.tabY " w" guiCfg.tabW " h" guiCfg.tabH, ["Main", "Boss", "Phụ trợ"])

    btnDaily.OnEvent("Click", (*) => _feature_daily())
    btnEnhance.OnEvent("Click", (*) => _feature_enhance(g_inputCount.Value))
    btnRaKhoi.OnEvent("Click", (*) => _feature_rakhoi(g_inputCount.Value))

    _start_event_timer()
    _start_activity_scheduler()
}

_start_event_timer() {
    global g_eventTimerEnabled
    if !g_eventTimerEnabled {
        g_eventTimerEnabled := true
        SetTimer(_update_event_text, 60000)
    }
}

_feature_daily() {

    global isRunning, g_featureText, g_dailyWorkerPids, g_dailyStopFile

    _daily_init_runtime()
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Daily"
    hwnds := _win_get_list()
    isRunning := true

    try {
        g_dailyWorkerPids := []
        g_dailyStopFile := _daily_build_stop_file()
    } finally {
        _feature_reset_running_status()
    }
}

_feature_reset_running_status() {
    global g_featureText
    if (IsSet(g_featureText))
        g_featureText.text := "Tính năng đang chạy: Chưa có"
}
```

## Implementation Details
- Luôn giữ callback nút ngắn: gọi `_feature_*` entry function, không đặt business logic trong GUI file.
- Trạng thái đang chạy chỉ viết qua `g_featureText`, tránh nhiều label rời gây lệch trạng thái.
- Timer event text chạy độc lập với scheduler; dùng cờ `g_eventTimerEnabled` để tránh đăng ký timer trùng.
- Các button hỗ trợ (Enhance/Ra Khơi/...) nhận `g_inputCount.Value` để điều khiển số vòng lặp nhanh từ GUI.

## Timing & Constants
- `SetTimer(_update_event_text, 60000)` (refresh event mỗi 60s)
- Fast action delay thường nằm trong feature (`Sleep 500`, `Sleep 1000`, ...), GUI không tự sleep.

## Checklist
1. GUI có đủ tab: Main/Boss/Phụ trợ.
2. Mọi nút bind vào `_feature_*` rõ ràng.
3. Có `g_featureText` và reset qua `_feature_reset_running_status()`.
4. Timer 60s chỉ start 1 lần.
5. Nút cần số lần chạy phải đọc từ `g_inputCount`.

## Common Mistakes
- Quên `finally` nên status bị kẹt “đang chạy”.
- Đặt logic dài trong callback GUI làm treo thao tác.
- Start `SetTimer` nhiều lần do thiếu cờ guard.
- Hard-code text status ở nhiều nơi, gây mismatch giữa scheduler và manual run.

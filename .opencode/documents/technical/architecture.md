# Auto Võ Hồn Tiên - Technical Architecture

## Overview

Project dùng **AutoHotkey v2** để automation game "Kỷ Nguyên Hải Tặc" trên emulator, theo mô hình:

- GUI điều khiển (`gui/gui_main.ahk`)
- Feature layer (`features/*.ahk`)
- Utility layer (`utils/*.ahk`)
- Resource/config (`resources/*.ini`)

Luồng chính ưu tiên:

1. Tìm + chuẩn hóa window game
2. Điều khiển bằng `PostMessage` (click/keyboard)
3. OCR + fuzzy matching cho Q&A
4. Scheduler chạy event theo lịch (5s tick)

---

## Module Diagram

```text
main.ahk
 ├─ parse CLI args
 │   ├─ --daily-worker <hwnd> [stopFile]
 │   └─ --boss-worker <mode> <hwnd>
 ├─ include gui/gui_main.ahk
 ├─ include utils/*
 └─ include features/*

gui/gui_main.ahk
 ├─ build GUI 360x525 (3 tabs)
 ├─ bind button -> _feature_...()
 ├─ start event text timer (60s)
 └─ start scheduler timer (5s)

features/
 ├─ daily.ahk      (multi-worker, 24 task, resume)
 ├─ boss.ahk       (punk/kraken/kaido, 15m fight loop)
 ├─ hoidapcothuong.ahk (OCR + fuzzy 3 đáp án)
 └─ haitacthongthai.ahk (OCR + fuzzy 4 đáp án)

utils/
 ├─ window.ahk      (window detect/resize + OCR bitmap capture)
 ├─ post_message.ahk(click/key via PostMessage)
 ├─ scheduler.ahk   (events.ini, executed-state)
 ├─ OCR.ahk         (OCR lib include/wrapper support)
 └─ log_file.ahk/date.ahk
```

---

## Data Flow: GUI -> Feature -> Worker -> Window

```text
[User click GUI]
    -> _feature_xxx()
        -> _win_resize_list()
        -> hwnds := _win_get_list()
        -> (optional) spawn worker processes per hwnd
            -> worker entry parse args
            -> run single-window routine
                -> _click_post / _post_with_vk_string
                -> _ocr_from_bit_map (if needed)
        -> progress/log/state update
```

## Input Transport Layer (PostMessage)

Automation input chủ yếu đi qua `utils/post_message.ahk` thay vì `SendInput` trực tiếp:

- `_click_post(hwnd, x, y)` -> `WM_LBUTTONDOWN (0x201)` + `WM_LBUTTONUP (0x202)`
- `_multi_click_post(hwnd, x, y, count, delay)` -> loop click nhiều lần
- `_post_with_vk_string(hwnd, vk)` -> map vk rồi gửi `WM_KEYDOWN/WM_KEYUP`

Mục tiêu: giảm phụ thuộc focus/foreground window khi multi-window automation.

### Chi tiết theo nhóm feature

- **Daily**: parent process spawn N workers (mỗi `hwnd` 1 process), dùng stop-file để broadcast stop.
- **Boss**: parent process spawn N workers theo mode (`punk|kraken|kaido`), mỗi worker tự loop chiến đấu 15 phút.
- **Q&A**: chạy OCR câu hỏi + OCR đáp án, normalize + fuzzy match từ `resources/Question.ini`.

---

## CLI Arguments Parsing (main.ahk)

### Nhánh 1: Daily worker

```ahk
if (A_Args.Length >= 2 and A_Args[1] = "--daily-worker") {
    hwnd := Integer(A_Args[2])
    stopFile := (A_Args.Length >= 3) ? A_Args[3] : ""
    _feature_daily_worker_entry(hwnd, stopFile)
    ExitApp()
}
```

### Nhánh 2: Boss worker

```ahk
if (A_Args.Length >= 3 and A_Args[1] = "--boss-worker") {
    mode := A_Args[2]
    hwnd := Integer(A_Args[3])
    _boss_worker_entry(mode, hwnd)
    ExitApp()
}
```

### Nhánh 3: GUI mode (default)

```ahk
_gui_init()
_hoidap_load_vocab_cache()
_httt_load_vocab_cache()
```

---

## Key Functions

| Layer | Function | Vai trò |
|---|---|---|
| Entry | `main.ahk` arg parsing | Routing worker/GUI mode |
| GUI | `_gui_init()` | Build UI, bind events, start timers |
| Window | `_win_get_list()` | Lấy danh sách cửa sổ game hợp lệ |
| Window | `_win_resize_list()` | Chuẩn hóa size 1280x720 |
| Input | `_click_post()` | Click không cần focus bằng `PostMessage` |
| OCR | `_ocr_from_bit_map()` | Capture bitmap vùng + OCR.FromBitmap |
| Scheduler | `_start_activity_scheduler()` | Tick 5 giây, trigger event |
| Daily | `_feature_daily()` | Spawn/monitor daily workers |
| Boss | `_boss_run_parallel()` | Spawn/monitor boss workers |

---

## Data Structures

| Name | Type | Mục đích |
|---|---|---|
| `g_dailyWorkerPids` | Array | PID workers daily đang chạy |
| `g_bossWorkerPids` | Array | PID workers boss đang chạy |
| `g_dailyStopFile` | String | Đường dẫn stop flag file |
| `g_activityExecutedMap` | Map | Đánh dấu event đã chạy trong ngày |
| `_hoidap_vocab_cache` | Map | Cache token + entries cho Q&A 3 đáp án |
| `_httt_vocab_cache` | Map | Cache token + entries cho Q&A 4 đáp án |

---

## Timing

| Thành phần | Timing |
|---|---|
| Event scheduler tick | 5000 ms |
| GUI event text refresh | 60000 ms |
| Daily worker wait polling | 500 ms |
| Boss worker wait polling | 500 ms |
| Boss fight loop duration | 15 phút |
| Boss attack click interval | 2000 ms |

---

## Error Handling

- `main.ahk`: `OnExit(_app_on_exit)` gọi `_feature_stop()` để cleanup.
- Scheduler: `try/catch/finally` trong `_activity_scheduler_tick()` và `_scheduler_execute_event()`.
- Worker entry: validate `A_Args.Length`, lỗi thì `ExitApp(1)`.
- Boss worker: catch lỗi và append `logs/boss_worker_error.log`.

---

## TODO / Gaps

1. Chuẩn hóa naming file/function boss worker:
   - đang có cả `main --boss-worker ...` và `features/boss_worker.ahk`.
2. Chuẩn hóa event list giữa `resources/events.ini` và `_scheduler_is_supported_event()`.
3. Tài liệu hóa thêm dependency OCR external (`OCR.FromBitmap`) trong `utils/OCR.ahk`.

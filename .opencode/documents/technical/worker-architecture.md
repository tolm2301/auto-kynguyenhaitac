# Worker Architecture (Daily & Boss)

## Overview

Project dùng mô hình **multi-process worker** để xử lý nhiều cửa sổ game song song:

- Parent process: GUI/main feature orchestration
- Worker process: chạy automation cho từng `hwnd`

2 nhóm worker:

1. **Daily worker** (`features/daily.ahk` + `features/daily_worker.ahk`)
2. **Boss worker** (`features/boss.ahk` + `features/boss_worker.ahk`)

---

## Multi-process model

## 1) Daily

Parent `_feature_daily()`:

1. `_daily_init_runtime()` set timing constants
2. `_win_resize_list()` + `hwnds := _win_get_list()`
3. Tạo `g_dailyStopFile`
4. Loop từng hwnd -> `_daily_start_worker(hwnd, stopFile)`
5. `_daily_wait_workers(...)` chờ tất cả worker xong

Worker entry:

- GUI mode: `main.ahk --daily-worker <hwnd> [stopFile]`
- Script mode: `features/daily_worker.ahk <hwnd> [stopFile]`

Worker gọi `_feature_daily_worker_entry(hwnd, stopFile)` -> `_feature_daily_single_hwnd(hwnd)`.

## 2) Boss

Parent `_boss_run_parallel(mode, featureName)`:

1. resize + lấy hwnd list
2. `_boss_start_workers(mode, hwnds)`
3. `_boss_wait_workers(pids)`

Worker entry:

- GUI mode: `main.ahk --boss-worker <mode> <hwnd>`
- Script mode: `features/boss_worker.ahk <mode> <hwnd>`

Worker gọi `_boss_worker_entry(mode, hwnd)`.

---

## CLI Contracts

| Worker | Args |
|---|---|
| Daily | `--daily-worker <hwnd> [stopFile]` |
| Boss | `--boss-worker <mode> <hwnd>` |

`mode` hỗ trợ: `punk`, `kraken`, `kaido`.

---

## Stop file mechanism (Daily)

Daily dùng stop-file để phát tín hiệu stop cho tất cả worker:

- Tạo file: `_daily_build_stop_file()` -> `logs/daily_stop_<A_NowUTC>_<A_TickCount>.flag`
- Khi user bấm Stop (`_feature_stop`) hoặc parent cần dừng:
  - `_daily_signal_stop(stopFile)` tạo file cờ
  - worker check `_daily_should_continue()`
  - nếu file tồn tại -> worker return sớm

### Check point trong worker

`_feature_daily_single_hwnd` check trước mỗi task:

```ahk
if !_daily_should_continue() {
    _daily_log("Stop signal hwnd=" . hwnd . " tại task #" . taskIndex)
    return
}
```

---

## Progress tracking INI (Daily)

File state: `resources/dailystate.ini`, section `Daily`.

Keys:

| Key | Ý nghĩa |
|---|---|
| `lastCompletedTaskIndex` | index task đã xong gần nhất |
| `lastCompletedTaskId` | id task đã xong gần nhất |
| `updatedAt` | timestamp cập nhật |

### Resume logic

- `_daily_load_progress(tasks, totalTasks)` đọc state và tính `startIndex`
- Sau mỗi task success: `_daily_save_progress(taskIndex, taskId)`
- Hoàn tất all task: `_daily_reset_progress()` xóa section để reset vòng sau

---

## Fight loop timing (Boss)

Hàm `_boss_fight_loop(hwnd, shouldClickAttack := true)`:

- `endTick := A_TickCount + 15 * 60 * 1000`
- Loop đến khi hết 15 phút
- Mỗi vòng:
  - nếu `shouldClickAttack` -> `_click_post(hwnd, 748, 156)`
  - `Sleep 2000`
- Hết giờ: `Sleep 5000` rồi gửi `ESC`

### Timing table

| Thành phần | Giá trị |
|---|---|
| Boss total fight duration | 15 phút |
| Attack interval | 2 giây |
| Worker monitor polling (parent) | 500 ms |

---

## Daily timing constants

Thiết lập tại `_daily_init_runtime()`:

| Constant | Value |
|---|---|
| `FEATURE_TASK_SLEEP` | 5000 |
| `FEATURE_TASK_LONG_SLEEP` | 15000 |
| `LOAD_SLEEP` | 2000 |
| `SHORT_LOAD_SLEEP` | 1000 |
| `EXIT_FEATURE_SLEEP` | 7000 |

---

## Key Functions

| Function | Vai trò |
|---|---|
| `_feature_daily()` | parent orchestration daily workers |
| `_daily_start_worker(hwnd, stopFile)` | spawn 1 daily worker |
| `_daily_wait_workers(pids, stopFile)` | wait + stop handling |
| `_feature_daily_single_hwnd(hwnd)` | chạy full task list 1 cửa sổ |
| `_feature_punk/_feature_kraken/_feature_kaido` | entry boss modes |
| `_boss_start_worker(mode, hwnd)` | spawn 1 boss worker |
| `_boss_fight_loop(hwnd, shouldClickAttack)` | vòng combat 15 phút |
| `_feature_stop()` | global stop (daily + boss) |

---

## Error Handling

- Daily parent có `try/finally` để luôn reset trạng thái.
- Daily per-task có `try/catch` log fail và rethrow.
- Boss worker có catch ghi `logs/boss_worker_error.log`.
- Stop logic có cleanup PID arrays + stop file.

---

## TODO

1. `dailystate.ini` hiện dùng chung section `Daily`; chạy đa worker có thể ghi đè progress giữa các hwnd.
2. Parent currently có thể `ProcessClose` worker khi stop -> cần cân nhắc graceful shutdown nhiều hơn.
3. Chưa có timeout watchdog cho worker bị treo lâu bất thường.

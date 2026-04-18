---
name: feature-architecture
description: Split AHK2 work into feature, config, utils, and GUI binding layers
compatibility: opencode
metadata:
  domain: ahk2
  area: architecture
---

## What I do
- Tổ chức project theo lớp: entrypoint -> gui -> features -> utils/resources
- Dùng worker process cho tác vụ nặng (daily/boss) để chạy đa cửa sổ ổn định
- Tách state/progress ra INI + flag file để resume/stop an toàn

## Key Patterns (from real project)
- Multi-process worker model với CLI args: `--daily-worker`, `--boss-worker`
- Progress tracking qua `resources/dailystate.ini`
- Stop mechanism qua flag file: `logs/daily_stop_*.flag`
- Runtime constants tập trung trong `_daily_init_runtime()`
- Resolve base dir cho worker/script mode bằng `_daily_get_base_dir()`

## Code Examples
```text
main.ahk
gui/gui_main.ahk
features/
  daily.ahk, daily_worker.ahk
  boss.ahk, boss_worker.ahk
  hoidapcothuong.ahk
  haitacthongthai.ahk
utils/window.ahk, OCR.ahk, scheduler.ahk, post_message.ahk
resources/events.ini, Question.ini
logs/
```

```autohotkey
if (A_Args.Length >= 2 and A_Args[1] = "--daily-worker") {
    hwnd := Integer(A_Args[2])
    stopFile := (A_Args.Length >= 3) ? A_Args[3] : ""
    _feature_daily_worker_entry(hwnd, stopFile)
    ExitApp()
}

if (A_Args.Length >= 3 and A_Args[1] = "--boss-worker") {
    mode := A_Args[2]
    hwnd := Integer(A_Args[3])
    _boss_worker_entry(mode, hwnd)
    ExitApp()
}

_daily_init_runtime() {
    global FEATURE_TASK_SLEEP := 5000
    global FEATURE_TASK_LONG_SLEEP := 15000
    global LOAD_SLEEP := 2000
    global SHORT_LOAD_SLEEP := 1000
    global EXIT_FEATURE_SLEEP := 7000
}

_daily_get_base_dir() {
    if DirExist(A_ScriptDir . "\resources")
        return A_ScriptDir

    if DirExist(A_ScriptDir . "\..\resources")
        return A_ScriptDir . "\.."

    return A_WorkingDir
}

_daily_get_state_path() {
    return _daily_get_base_dir() . "\resources\dailystate.ini"
}

_daily_build_stop_file() {
    logDir := _daily_get_base_dir() . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    return logDir . "\daily_stop_" . A_NowUTC . "_" . A_TickCount . ".flag"
}

_daily_start_worker(hwnd, stopFile) {
    pid := 0

    if A_IsCompiled {
        runCommand := Format('"{1}" --daily-worker "{2}" "{3}"', A_ScriptFullPath, hwnd, stopFile)
        try Run(runCommand, _daily_get_base_dir(), "Hide", &pid)
        return pid
    }

    baseDir := _daily_get_base_dir()
    workerScript := baseDir . "\features\daily_worker.ahk"
    if !FileExist(workerScript)
        return 0
}
```

## Implementation Details
- `main.ahk` là router: nếu có CLI arg worker thì chạy worker entry và `ExitApp`, nếu không thì khởi tạo GUI.
- Feature dài (Daily/Boss) chạy worker-process per hwnd để tránh block process chính.
- Daily có khả năng resume task dựa trên `lastCompletedTaskIndex` + `lastCompletedTaskId` trong INI.
- Stop feature không kill mù: tạo stop flag + đóng worker còn sống có kiểm tra `ProcessExist`.
- Worker script có bản `_feature_reset_running_status()` tối thiểu để tương thích include feature.

## Timing & Constants
- `FEATURE_TASK_SLEEP=5000`
- `LOAD_SLEEP=2000`
- `EXIT_FEATURE_SLEEP=7000`
- `FEATURE_TASK_LONG_SLEEP=15000`
- Poll worker alive loop sleep: `500 ms`

## Checklist
1. Entry function rõ: `_feature_<name>()`.
2. Có path resolver cho script/compiled mode.
3. Feature nặng có worker riêng + CLI args rõ ràng.
4. Có state file nếu feature cần resume.
5. Có stop flag và cleanup PID list sau khi kết thúc.

## Common Mistakes
- Hard-code `A_ScriptDir` khiến worker không tìm thấy `resources` khi chạy từ thư mục khác.
- Chạy multi-window trong 1 process duy nhất làm flow chồng lấn input.
- Không persist progress nên fail giữa chừng phải chạy lại từ đầu.
- Dùng `ProcessClose` mà không có stop signal -> dễ mất trạng thái dang dở.

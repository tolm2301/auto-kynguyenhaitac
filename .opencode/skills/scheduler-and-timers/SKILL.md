---
name: scheduler-and-timers
description: Trigger AHK2 jobs with SetTimer, polling, and time-based scheduling
compatibility: opencode
metadata:
  domain: ahk2
  area: scheduling
---

## What I do
- Chạy scheduler nền theo tick 5 giây với busy-guard để tránh re-entry
- Parse lịch từ `resources/events.ini` theo format `eventName=days|time`
- Persist trạng thái run theo ngày và chống chạy lặp trong 1 phút
- Map event name sang `_feature_*` bằng `switch`

## Key Patterns (from real project)
- `SetTimer(_activity_scheduler_tick, 5000)` + gọi tick ngay sau khi start
- Busy flag `g_activitySchedulerBusy` bao quanh toàn bộ tick
- Run key theo ngày: `yyyyMMdd|event|HH:mm` + `g_activityExecutedMap`
- Daily state file: `logs/scheduler_state_YYYYMMDD.txt`
- Bỏ qua event nếu quá 1 phút từ giờ hẹn hoặc đã chạy rồi

## Code Examples
```autohotkey
_start_activity_scheduler() {
    global g_activitySchedulerEnabled
    if g_activitySchedulerEnabled
        return

    _scheduler_load_executed_state()
    g_activitySchedulerEnabled := true
    SetTimer(_activity_scheduler_tick, 5000)
    _activity_scheduler_tick()
}

_activity_scheduler_tick() {
    global g_activitySchedulerBusy
    if g_activitySchedulerBusy
        return

    g_activitySchedulerBusy := true
    try {
        _scheduler_load_executed_state()
        event := _scheduler_get_due_event()
        if IsObject(event)
            _scheduler_execute_event(event)
    } catch as err {
        _scheduler_log("Scheduler error: " . err.Message)
    } finally {
        g_activitySchedulerBusy := false
    }
}

_scheduler_get_due_event() {
    global g_activityExecutedMap

    iniPath := A_ScriptDir . "\resources\events.ini"
    if !FileExist(iniPath)
        return ""

    loop read iniPath {
        line := Trim(A_LoopReadLine)
        if (line = "" or SubStr(line, 1, 1) = "[" or InStr(line, "=") = 0)
            continue

        parts := StrSplit(line, "=")
        eventName := Trim(parts[1])

        eventParts := StrSplit(Trim(parts[2]), "|")
        dayParts := StrSplit(Trim(eventParts[1]), ",")
        timeParts := StrSplit(Trim(eventParts[2]), ":")

        eventHour := Integer(Trim(timeParts[1]))
        eventMinute := Integer(Trim(timeParts[2]))
        eventTotalMinutes := eventHour * 60 + eventMinute
        if ((nowMinutes - eventTotalMinutes) > 1)
            continue

        runKey := FormatTime(A_Now, "yyyyMMdd") . "|" . eventName . "|" . Format("{:02}:{:02}", eventHour, eventMinute)
        if g_activityExecutedMap.Has(runKey)
            continue
    }
}

_scheduler_get_state_path(date := "") {
    logDir := A_ScriptDir . "\\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    d := (date = "") ? FormatTime(A_Now, "yyyyMMdd") : date
    return logDir . "\\scheduler_state_" . d . ".txt"
}

_scheduler_run_event(eventName) {
    global g_inputCount

    count := Integer(g_inputCount.Value)
    if (count <= 0)
        count := 1

    switch eventName {
        case "Daily":
            _feature_daily()
        case "Tầm bảo chiến":
            _feature_tam_bao_chien()
        case "Cường Hoá":
            _feature_enhance(count)
        case "Ra Khơi":
            _feature_rakhoi(count)
        case "Năm Mới Phát Tài":
            _feature_nammoiphattai(count)
        default:
            throw Error("Event chưa được map feature: " . eventName)
    }
}
```

## Implementation Details
- Scheduler chỉ làm 3 việc: tìm due event, mark trạng thái, dispatch sang feature.
- Parse `events.ini` theo dòng, bỏ qua section header (`[... ]`) và dòng lỗi format.
- Rule chống duplicate:
  - cùng ngày cùng event cùng giờ chỉ chạy 1 lần (`g_activityExecutedMap`)
  - event trễ quá 1 phút thì bỏ (`(nowMinutes - eventTotalMinutes) > 1`)
- State được reload theo ngày (`g_schedulerStateLoadedDate`) để tự reset map qua ngày mới.
- Khi chạy auto, cập nhật GUI text và luôn `finally -> _feature_reset_running_status()`.

## Timing & Constants
- Tick interval: `5000 ms`
- Cửa sổ cho phép trigger event: trong vòng `<= 1 phút`
- Persist key format: `yyyyMMdd|EventName|HH:mm`
- State file: `logs\scheduler_state_YYYYMMDD.txt`

## Checklist
1. Có busy flag guard cho tick.
2. Có state persistence theo ngày.
3. Có map event -> feature rõ ràng.
4. Có log cho error/run/completed/failed.
5. Không để scheduler gọi feature khi chưa validate event supported.

## Common Mistakes
- Không khóa busy flag -> tick chồng chéo, chạy lặp feature.
- Không persist runKey -> restart app gây chạy lại event đã chạy.
- Parse `events.ini` thiếu validate `|` / `:` -> crash runtime.
- Không reset state theo ngày -> hôm sau không chạy event.

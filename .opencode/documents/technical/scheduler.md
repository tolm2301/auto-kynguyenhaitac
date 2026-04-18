# Event Scheduler (`utils/scheduler.ahk`)

## Overview

Scheduler chịu trách nhiệm tự chạy feature theo lịch từ `resources/events.ini`.

Đặc điểm chính:

- Tick mỗi **5 giây** (`SetTimer`)
- So sánh theo `A_WDay` + `HH:mm`
- Chỉ trigger event nếu đang trong cửa sổ **<= 1 phút** kể từ giờ event
- Persist trạng thái đã chạy theo ngày trong `logs/scheduler_state_YYYYMMDD.txt`

---

## Implementation

## 1) 5-second tick loop

Entry:

```ahk
_start_activity_scheduler() {
    _scheduler_load_executed_state()
    SetTimer(_activity_scheduler_tick, 5000)
    _activity_scheduler_tick()
}
```

Tick handler có guard `g_activitySchedulerBusy` để tránh re-entrant run.

```text
tick -> load state hôm nay -> get due event -> execute event
```

---

## 2) `events.ini` parsing

Định dạng mỗi dòng:

```text
EventName=day1,day2,...|HH:mm
```

Ví dụ:

```ini
Rồng Punk=1,2,3,4,5,6,7|15:30
Kraken=1,2,3,4,5,6,7|21:00
Kaido=1,2,3,4,5,6,7|21:30
```

### Điều kiện event "due"

Một event được chọn chạy khi:

1. `eventName` nằm trong `_scheduler_is_supported_event(...)`
2. Ngày hiện tại nằm trong day list
3. `eventTotalMinutes <= nowMinutes`
4. `nowMinutes - eventTotalMinutes <= 1`
5. `runKey` chưa tồn tại trong `g_activityExecutedMap`

`runKey` format:

```text
yyyyMMdd|eventName|HH:mm
```

---

## 3) State persistence + daily reset

### In-memory

- `g_activityExecutedMap := Map()`
- map key = `runKey`
- value status: `running/done/failed/persisted`

### File persistence

- File: `logs/scheduler_state_YYYYMMDD.txt`
- Mỗi dòng 1 `runKey`
- Khi mới thấy runKey lần đầu -> append file

### Daily reset logic

`_scheduler_load_executed_state()` dùng `g_schedulerStateLoadedDate`:

- nếu đã load đúng ngày hôm nay -> return
- nếu sang ngày mới -> clear map + load file state ngày mới (nếu có)

---

## 4) Event-to-feature mapping

`_scheduler_run_event(eventName)` map tên event -> hàm feature:

| Event Name | Function |
|---|---|
| `Rồng Punk` | `_feature_punk()` |
| `Kraken` | `_feature_kraken()` |
| `Kaido` | `_feature_kaido()` |
| `Daily` | `_feature_daily()` |
| `Tầm bảo chiến` | `_feature_tam_bao_chien()` |
| `Cường Hoá` | `_feature_enhance(count)` |
| `Ra Khơi` | `_feature_rakhoi(count)` |
| `Năm Mới Phát Tài` | `_feature_nammoiphattai(count)` |
| `Ảnh hồn` | `_feature_anhhon(count)` |
| `Tấn công hải quân` | `_feature_tanconghaiquan()` |
| `Hỏi đáp có thưởng` | `_feature_hoidapcothuong()` |
| `Register Uta World` | `_feature_register_uta()` |

`count` lấy từ GUI input `g_inputCount.Value`, tối thiểu = 1.

---

## Key Functions

| Function | Vai trò |
|---|---|
| `_start_activity_scheduler()` | Khởi động scheduler timer |
| `_activity_scheduler_tick()` | Tick loop + error guard |
| `_scheduler_get_due_event()` | Parse lịch và chọn event cần chạy |
| `_scheduler_execute_event(event)` | Đánh dấu trạng thái + gọi feature |
| `_scheduler_mark_executed(runKey, status)` | Ghi map executed |
| `_scheduler_load_executed_state()` | Load state theo ngày |
| `_scheduler_append_executed_state(runKey)` | Persist runKey ra file |
| `_scheduler_log(msg)` | Log scheduler theo ngày |

---

## Data Structures

| Name | Type | Mục đích |
|---|---|---|
| `g_activitySchedulerEnabled` | Bool | cờ đã bật timer |
| `g_activitySchedulerBusy` | Bool | lock chống chạy chồng tick |
| `g_activityExecutedMap` | Map | theo dõi event đã chạy |
| `g_schedulerStateLoadedDate` | String | ngày đã load state gần nhất |

---

## Timing

| Thành phần | Giá trị |
|---|---|
| Scheduler tick | 5000 ms |
| Event due window | <= 1 phút sau mốc event |

---

## Error Handling

- `_activity_scheduler_tick()` bọc `try/catch/finally`.
- `_scheduler_execute_event()`:
  - mark `running` trước khi gọi
  - success -> mark `done`
  - fail -> mark `failed` + log lỗi
  - finally -> `_feature_reset_running_status()`
- `_scheduler_log()` tự rotate log theo ngày (xóa file cũ nếu khác ngày).

---

## TODO

1. `resources/events.ini` có event chưa support (`Chiến trường1`, `Smile`, `Uta World`, ...), hiện bị bỏ qua bởi `_scheduler_is_supported_event`.
2. Scheduler currently parse file line-by-line thủ công, chưa validate duplicate event/time.
3. Chưa có offset timezone/config cho server time game.

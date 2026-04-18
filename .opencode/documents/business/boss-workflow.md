# Boss Workflow

## Overview
Boss có 3 mode chạy theo worker riêng cho từng cửa sổ game.

| Mode | Feature name | Khác biệt |
|---|---|---|
| `punk` | Rồng punk | vào boss qua menu phải, có click attack trong loop |
| `kraken` | Kraken | path tương tự punk, khác tọa độ boss entry |
| `kaido` | Kaido | path riêng, **không** auto click attack trong loop |

## Flow
```text
bấm boss hoặc scheduler gọi boss
 -> resize list window
 -> spawn worker cho từng hwnd
 -> worker vào boss screen
 -> click tham gia / săn boss
 -> fight loop 15 phút
 -> hết giờ -> ESC thoát
 -> reset running status
```

## Click path theo mode
### Rồng punk
`729,35 -> 339,200 -> 893,558 -> 680,73 -> 582,145 x10 -> fight`

### Kraken
`729,35 -> 402,259 -> 893,558 -> 680,73 -> 582,145 x10 -> fight`

### Kaido
`1125,541 -> 1129,122 -> 1129,173 -> fight`

## Fight loop mechanism
| Rule | Giá trị |
|---|---|
| thời gian loop | 15 phút |
| tick loop | 2 giây |
| thoát khi hết giờ | sleep 5s rồi gửi `ESC` |
| auto attack | bật cho punk/kraken, tắt cho kaido |

## Scheduler integration
- boss event lấy từ `resources/events.ini`
- scheduler tick mỗi 5 giây
- chỉ chạy các event được map trong `_scheduler_run_event()`
- event chỉ được chạy 1 lần/ngày theo `runKey`

### Boss schedule hiện có
| Boss | Ngày | Giờ |
|---|---|---|
| Rồng Punk | 1-7 | 15:30 |
| Kraken | 1-7 | 21:00 |
| Kaido | 1-7 | 21:30 |

## Timing
| Thành phần | Giá trị |
|---|---|
| worker wait loop | 500 ms |
| pre-click sleeps | 1000-5000 ms tùy bước |
| fight duration | 15 phút |

## Risks
- boss worker bị close bằng `ProcessClose()` khi stop
- nếu vào boss chậm hơn thời gian, loop vẫn chạy đủ 15 phút tính từ lúc start loop
- Kaido không auto attack nên phụ thuộc màn đánh tay sẵn có

## TODO
- TODO: xác nhận lại path boss entry nếu UI đổi layout
- TODO: bổ sung log riêng cho từng boss mode nếu cần debug sâu hơn

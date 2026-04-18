# Overview

## Mục tiêu
Auto VHT là bộ AHK v2 tự động hóa game Võ Hồn Tiên theo hướng:
- chạy feature bằng nút GUI hoặc scheduler
- hỗ trợ nhiều cửa sổ game
- có log, resume, stop an toàn
- OCR + fuzzy match cho các màn hỏi đáp

## Kiến trúc chính
```text
main.ahk
 ├─ gui/gui_main.ahk         -> GUI 3 tab, nút chạy feature
 ├─ utils/                  -> window, OCR, post_message, scheduler, log
 └─ features/
     ├─ daily.ahk           -> Daily 24 task
     ├─ boss.ahk            -> Boss 3 mode
     ├─ hoidapcothuong.ahk   -> Q&A ABC
     ├─ haitacthongthai.ahk  -> Q&A ABCD
     └─ ... other feature
```

## Flow tổng quát khi user bấm nút
```text
User click GUI
 -> _win_resize_list() / _win_get_list()
 -> set isRunning = true
 -> feature runner xử lý từng hwnd
 -> nếu multi-window: spawn worker process
 -> task chạy theo flow riêng
 -> finish / fail / stop
 -> reset trạng thái GUI
```

## Điểm chung của mọi feature
| Thành phần | Vai trò |
|---|---|
| `isRunning` | cờ chạy chung, dùng để dừng an toàn |
| `g_featureText` | hiển thị feature đang chạy |
| `PostMessage` | click/key không cần focus trực tiếp |
| `OCR` | đọc câu hỏi / option / trạng thái |
| `scheduler` | tự gọi feature theo lịch trong `events.ini` |

## Scheduler
- đọc `resources/events.ini`
- tick mỗi 5 giây
- chỉ chạy event đã tới giờ, trong vòng 1 phút sau mốc
- tránh chạy trùng trong ngày bằng `logs/scheduler_state_YYYYMMDD.txt`

## Risks
- OCR lệch khi scale UI thay đổi
- popup chen ngang làm sai click path
- multi-window cần đồng bộ stop/process kill
- một số task phụ thuộc màn hình đúng trạng thái trước đó

## TODO
- TODO: xác nhận lại một số tọa độ phụ thuộc resolution/scale
- TODO: chuẩn hóa tên feature giữa GUI, scheduler và file ini

# Daily Workflow

## Overview
Daily chạy tuần tự 24 task, có resume theo state file và hỗ trợ multi-window worker process.

## Flow
```text
bấm Daily
 -> resize list window
 -> lấy danh sách hwnd game
 -> tạo stop flag
 -> spawn worker cho từng cửa sổ
 -> worker load progress từ dailystate.ini
 -> chạy task từ task tiếp theo
 -> save progress sau mỗi task
 -> hết task thì reset state
```

## Progress / Resume
**File state:** `resources/dailystate.ini`  
**Section:** `[Daily]`

| Key | Ý nghĩa |
|---|---|
| `lastCompletedTaskIndex` | index task đã xong gần nhất |
| `lastCompletedTaskId` | id task đã xong |
| `updatedAt` | thời điểm lưu |

### Rule resume
- đọc state khi start
- nếu index/id hợp lệ thì tiếp tục từ task kế tiếp
- nếu state lỗi / hết task -> chạy lại từ đầu
- sau khi xong toàn bộ task -> xóa section `[Daily]`

## Stop mechanism
| Cơ chế | Mô tả |
|---|---|
| `isRunning = false` | stop chung |
| stop file `.flag` | worker kiểm tra file tồn tại để dừng |
| kill process | dừng worker PID đang chạy |

Stop file được tạo trong `logs/` theo mẫu `daily_stop_<UTC>_<tick>.flag`.

## Timing
| Tên biến | Giá trị |
|---|---|
| `FEATURE_TASK_SLEEP` | 5000 ms |
| `FEATURE_TASK_LONG_SLEEP` | 15000 ms |
| `LOAD_SLEEP` | 2000 ms |
| `SHORT_LOAD_SLEEP` | 1000 ms |
| `EXIT_FEATURE_SLEEP` | 7000 ms |

## 24 task
| # | Task | Click path chính |
|---|---|---|
| 1 | `che_do` | 925,35 -> 551,125 -> 279,405 x7 + Enter -> 1089,334 -> 1143,414 -> 1208,38 |
| 2 | `anh_hon` | 925,35 -> 690,125 -> 511,623 -> 711,387 -> 623,440 -> Enter -> ESC -> 1222,41 |
| 3 | `all_blue` | 925,35 -> 765,125 -> 319,201 / 738,243 / 277,446 / 614,512 / 897,505 (mỗi điểm: click + lặp 10 lần click/ESC) |
| 4 | `imple_down` | 925,35 -> 832,125 -> 557,624 x4 -> 1222,41 |
| 5 | `dung_luyen` | 925,35 -> 972,125 -> 548,548 -> Enter -> 1189,46 |
| 6 | `vung_bien_than_bi` | 925,35 -> 625,181 -> lặp 10x: 563,583 -> 524,332 -> 860,647 -> 508,345 -> 543,229 |
| 7 | `haki` | 925,35 -> 697,181 -> 574,615 -> ESC -> 1222,41 |
| 8 | `nguyen_to` | 925,35 -> 835,181 -> 936,43 -> 688,252 -> 470,354 -> ESC ESC -> 549,470 -> 626,575 x7 -> ESC -> 1222,41 |
| 9 | `tap_kick` | 732,36 -> 405,321 -> 886,554 -> 364,201 -> 699,546 -> ESC |
| 10 | `tang_qua` | 576,612 -> 416,136 -> 569,461 -> 560,445 -> ESC |
| 11 | `bao_thach` | 858,615 -> 679,389 -> 415,59 -> 710,408 x3 -> ESC -> 864,38 -> 828,224 -> loop 5x: 569,368 + 569,408 -> ESC -> 1235,29 |
| 12 | `tinh_ban` | 957,615 -> 336,559 -> ESC |
| 13 | `ra_khoi` | 45,270 -> 804,210 x15 -> ESC |
| 14 | `linh_treo_thuong` | 1184,616 -> 855,533 -> ESC |
| 15 | `dau_truong` | 993,40 -> 763,122 -> loop 5x: 759,258 x15 -> 1013,662 -> ESC -> 1211,36 |
| 16 | `huan_luyen` | 69,201 -> 576,194 -> 623,544 x2 -> 576,283 -> 623,544 x2 -> 576,361 -> 623,544 x2 -> ESC |
| 17 | `nau_an` | 33,225 -> 518,148 -> ESC -> lặp 9 ô nguyên liệu (x3/y3, x2/y3, x1/y3, x3/y2...) mỗi ô: 33,225 -> item -> 581,449 x10 -> ESC ESC |
| 18 | `tam_bao` | 993,40 -> 836,122 -> loop 5x: 938,38 -> 683,364 -> 908,310 x30 -> 557,570 -> sleep 60s -> 150,248 -> cuối loop -> 1211,36 |
| 19 | `boi_duong_tinh_linh` | 692,599 -> 483,610 -> 1037,422 -> Enter -> 1227,38 |
| 20 | `nhan_thuong_linh_danh_thue` | 926,41 -> 1045,193 -> 409,503 -> 869,33 -> 738,186 -> 746,285 -> Enter -> ESC ESC -> 1222,26 |
| 21 | `dat_hang` | 1072,614 -> 1000,541 -> 704,245/302/357/418 -> 501,268 x10 -> ESC ESC (lặp 4 đơn) |
| 22 | `linh_the_bai` | 728,43 -> 419,524 -> 400,323 -> 692,559 -> ESC |
| 23 | `cuong_hoa_tau_chien` | 728,43 -> 419,524 x2 -> 332,200 -> 619,560 -> 768,340 x20 -> 768,427 x20 -> 768,515 x20 -> ESC ESC |
| 24 | `nhon_hop_qua` | 61,365 -> 393,176 -> 630,460 -> 507,176 -> 630,460 -> 619,176 -> 630,460 -> 742,176 -> 630,460 -> ESC ESC |

## Error handling
| Tình huống | Xử lý |
|---|---|
| worker fail giữa chừng | log lỗi rồi throw lên caller |
| stop được bật | dừng worker, xóa stop flag nếu cần |
| state file hỏng | fallback start từ task 1 |
| cửa sổ game không có | `_win_get_list()` sẽ báo và thoát |

## Risks
- nhiều task dùng tọa độ cố định, dễ lệch nếu UI scale thay đổi
- task `nau_an`, `tam_bao`, `dau_truong` phụ thuộc thời gian chờ khá dài
- nếu popup chèn giữa chừng, click chain có thể sai

## TODO
- TODO: tách bảng tọa độ theo screen/resolution profile
- TODO: xác nhận lại các task có nhiều bước phụ trong màn con

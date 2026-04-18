# UI States

## Overview
Tài liệu này gom các state UI chính để map từ ảnh/OCR sang hành động.

## Main game UI regions
| Region | Dấu hiệu |
|---|---|
| Top menu button | các click mở feature thường ở `925,35`, `993,40`, `728,43` |
| Left/bottom feature shortcuts | nút như `45,270`, `61,365`, `1184,616` |
| Right-side panel | các màn con / boss / event thường nằm ở `x>600` |
| Exit/close buttons | thường ở góc phải trên: `1211,36`, `1222,41`, `1235,29` |

## Control panel states
| State | Dấu hiệu | Ý nghĩa |
|---|---|---|
| Idle | `Tính năng đang chạy: Chưa có` | không feature nào active |
| Running | text đổi sang tên feature | đang chạy manual/scheduler |
| Auto running | `Tính năng đang chạy (auto): ...` | scheduler đang execute |

## Event scheduler state
| State | Dấu hiệu | Ý nghĩa |
|---|---|---|
| Next event available | `Sự kiện tiếp theo: ...` | có lịch hôm nay |
| No schedule today | `Không có hôm nay` | không có event trong ngày |
| End of day | `Kết thúc hoạt động` | sau 22h |

## Q&A popup states
### Hoidap có thưởng
```text
State Q seen
 -> OCR question 580x146..930x190
 -> OCR A/B/C
 -> chọn đáp án
 -> confirm 856,284
```

### Hải tặc thông thái
```text
State question seen
 -> OCR question 294x190..977x340
 -> OCR A/B/C/D
 -> chọn đáp án
 -> confirm 907,584
```

## Boss entrance states
| State | Dấu hiệu | Hành động |
|---|---|---|
| Boss menu | đang ở màn danh mục boss | click boss tile |
| Join boss | có nút tham gia/săn boss | click vào fight entry |
| Fight loop | đang trong trận | click attack định kỳ (trừ Kaido) |
| Exit fight | hết 15 phút | gửi ESC |

## Daily task states
| State | Dấu hiệu | Hành động |
|---|---|---|
| Feature main panel | menu feature mở | chọn đúng task |
| Sub-feature screen | màn con task đang mở | thao tác click/Enter/ESC |
| Return to main | nút close/ESC hoạt động | thoát màn con |

## Risks
- nhiều state dùng cùng nút đóng ở góc phải trên, dễ lệch nếu resize
- popup đè lên state chính làm OCR/click sai
- một số màn task phải vào đúng tab trước khi thao tác

## TODO
- TODO: bổ sung ảnh chụp từng state nếu có bộ screenshot
- TODO: chuẩn hóa tên state theo ảnh thực tế khi review manual

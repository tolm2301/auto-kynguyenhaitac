# MEMORY - AHK2 Developer Agent

## 2025

### 2025-04-05 (Ngày khởi tạo)
- Khởi tạo workspace AHK2 Development Agent
- Tạo AGENTS.md với đầy đủ specifications về:
  - AutoHotkey2 syntax mastery
  - Windows API integration (DllCall, PostMessage, SendMessage)
  - GUI & Window Management
  - Automation & Input
  - OCR & Image Recognition
  - COM & External Interfaces
  - Performance & Threading
  - Error handling & debugging
- Tạo cấu trúc thư mục `.ai/developer/.skill/` để lưu trữ skills
- Thiết lập quy trình quản lý công việc:
  - MEMORY.md: Lưu lịch sử công việc
  - TASK.md: Theo dõi công việc hàng ngày
  - Clear TASK.md mỗi ngày

### 2025-04-05 (Task: Daily Task Point 4)
- Tạo script `features/daily_task_point4.ahk`
- Cấu trúc:
  - `DailyTaskConfig`: Class lưu cấu hình (tọa độ tab, vùng tìm icon, vùng OCR, tọa độ nút refresh)
  - `DailyTaskPoint4`: Class chính xử lý logic
- Workflow:
  1. Click mở tab nhiệm vụ hàng ngày
  2. ImageSearch tìm icon nhiệm vụ trong vùng defined
  3. Click icon → hiển thị điểm số
  4. OCR đọc điểm → nếu = 4 → DONE
  5. Nếu ≠ 4 → Click nút refresh → lặp lại
- Hàm helper `_feature_daily_task_point4_simple()` cho việc gọi đơn giản
- Sử dụng Windows.Media.Ocr có sẵn trong utils/OCR.ahk

### 2025-04-05 (Tích hợp GUI)
- Thêm button "Daily Task Điểm 4" vào Main Tab trong `gui/gui_main.ahk`
- Thêm sự kiện OnEvent Click gọi `_feature_daily_task_p4()`
- Tạo hàm `_feature_daily_task_p4()` với tham số mẫu (cần user điều chỉnh tọa độ)
- Tạo skill file `.ai/developer/.skill/gui-automation.md`

## 2026

### 2026-04-11 (Refactor Agent + Skills)
- Tối ưu lại `.ai/developer/AGENTS.md` theo workflow AHK2 thực chiến (module, retry/timeout, logging, checklist giao code)
- Nâng cấp kho skill trong `.ai/developer/.skill/README.md`
- Cập nhật `gui-automation.md` và thêm các skill mới:
  - `.ai/developer/.skill/windows-api-and-control.md`
  - `.ai/developer/.skill/ocr-imagesearch.md`
  - `.ai/developer/.skill/debug-and-stability.md`
- Clear task cũ trong `.ai/developer/TASK.md`

### 2026-04-11 (Scheduler + Automation Flow)
- Thêm scheduler chạy ngầm theo `resources/events.ini`, tự trigger event theo giờ, có log tại `logs/scheduler.log`
- Chỉnh boss features để chạy theo trigger scheduler thay vì chờ giờ cứng bên trong hàm
- Tách scheduler ra module riêng `utils/scheduler.ahk` để dễ quản lý

### 2026-04-11 (Q&A Features)
- Tách riêng tính năng `Hải tặc thông thái` thành file `features/haitacthongthai.ahk`
- Thêm button `Hải tặc thông thái` ở Main tab (dưới `Tầm bảo chiến`) trong `gui/gui_main.ahk`
- Chuẩn hóa logic trả lời:
  - `hoidapcothuong`: theo ABC
  - `haitacthongthai`: theo ABCD, không fallback theo letter INI khi score thấp (vì đáp án random vị trí)
- Bổ sung logging chi tiết OCR/options/score cho debug

### 2026-04-11 (OCR)
- Tăng cường OCR options trong `_ocr_from_bit_map` (scale/grayscale, retry pass)
- Ghi nhận hạn chế hiện tại: Windows OCR trên máy chưa có `vi-VN`, gây lỗi đọc tiếng Việt
- Trạng thái tiếp theo: đợi event thứ 3 để tiếp tục tune `haitacthongthai` theo log thực tế user cung cấp

---

*Lưu ý: Mỗi ngày làm việc xong sẽ clear TASK.md và lưu vào MEMORY.md*

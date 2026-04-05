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

---

*Lưu ý: Mỗi ngày làm việc xong sẽ clear TASK.md và lưu vào MEMORY.md*
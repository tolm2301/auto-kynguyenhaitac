# AHK2 Developer Skills

Kho skill thực chiến cho AutoHotkey2, theo chuẩn OpenCode `skills/<name>/SKILL.md`.

## Active Skills

1. `gui-automation`
   - Tạo GUI, event binding, status flow, và entry point cho feature.

2. `windows-api-and-control`
   - Ưu tiên Control/Win API, wrapper `DllCall`, và tương tác cửa sổ an toàn.

3. `ocr-imagesearch`
   - Hybrid detect với ImageSearch + OCR, normalize text, retry pipeline.

4. `debug-and-stability`
   - Logging, timeout, retry, fail-safe, và debug checklist.

5. `feature-architecture`
   - Cách tách feature, config, utils, và điểm nối với GUI.

6. `process-and-window-guards`
   - Xác minh HWND, PID, title, and active window trước khi thao tác.

7. `input-reliability`
   - Chuẩn hóa Send/Click/CoordMode, chống mất focus và double trigger.

8. `scheduler-and-timers`
   - Timer, polling, background trigger, và lịch chạy task.

9. `hotkeys-and-focus`
   - Hotkey mapping, focus switching, và xử lý input context.

10. `ini-config-and-paths`
    - Cấu hình INI, path resolution, resource layout, và cache file.

11. `gui-state-machine`
    - Mô hình hóa flow GUI theo state và transition rõ ràng.

12. `ocr-tuning`
    - Tối ưu OCR cho UI tiếng Việt và text hỗn hợp.

13. `release-workflow`
    - Chuẩn hóa bước kiểm tra, ghi chú, và đóng gói trước khi release.

## Usage Rule
- Khi tạo feature mới: đọc theo thứ tự `feature-architecture` -> `gui-automation` -> `windows-api-and-control` -> `ocr-imagesearch` (nếu cần) -> `debug-and-stability`.
- Skill mới phải có: mục tiêu, pattern code, checklist lỗi thường gặp.

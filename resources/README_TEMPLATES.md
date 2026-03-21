# Template Images cho Quest Feature

Để tính năng Quest hoạt động, bạn cần tạo các file ảnh template bằng cách crop từ màn hình game.

## Các file cần tạo

| File | Mô tả | Kích thước |
|------|-------|------------|
| `btn_skip.png` | Nút "Bỏ Qua" trong dialog | ~50x30 px |
| `btn_next.png` | Nút "Tiếp theo" / mũi tên vàng | ~50x30 px |
| `btn_finish_quest.png` | Nút "Hoàn thành" trong bảng nhận thưởng | ~80x30 px |
| `icon_main_quest.png` | Icon/chữ [Chính] trong tab nhiệm vụ (backup OCR) | ~30x20 px |

## Cách tạo

1. Chụp màn hình game (PrintScreen)
2. Mở bằng Paint hoặc tool chỉnh sửa ảnh
3. Crop chính xác vùng chứa nút/icon cần thiết
4. Lưu file .png vào thư mục này (`resources/`)

## Lưu ý

- Nên crop sát mép button/icon để tăng độ chính xác
- Giữ nguyên màu gốc, không chỉnh sửa độ sáng/tương phản
- Nếu button có animation, crop lúc button đang ở trạng thái "bình thường"
- Threshold mặc định là 0.8 - nếu không tìm thấy, giảm xuống 0.7

## Test

Chạy thử và kiểm tra log:
```
[DIALOG] Phát hiện nút Bỏ Qua, đang click...
```

Nếu không thấy log này, kiểm tra lại ảnh template.

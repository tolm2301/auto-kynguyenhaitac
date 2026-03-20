# Auto VHT - Kỷ Nguyên Hải Tặc

Tool tự động hóa game **Kỷ Nguyên Hải Tặc** (One Piece: Treasure Cruise).

## Python Rewrite

Đây là phiên bản viết lại từ AutoHotkey sang Python với các cải tiến:
- **Logging đầy đủ** để trace lỗi và debug
- **OCR Tiếng Việt** sử dụng EasyOCR cho tính năng Hỏi đáp có thưởng
- **Cấu trúc module hóa** dễ bảo trì và mở rộng

## Cài đặt

```bash
# Cài đặt dependencies
pip install -r requirements.txt
```

## Chạy chương trình

```bash
python main.py
```

## Tính năng

- **Cường Hoá** - Tự động cường hóa đồ
- **Ra Khơi** - Auto ra khơi
- **Năm Mới Phát Tài** - Event năm mới
- **Daily** - Tự động làm daily tasks
- **Ảnh Hồn** - Auto ảnh hồn
- **Tấn Công Hải Quân** - Auto tấn công hải quân
- **Hỏi Đáp Có Thưởng** - Sử dụng OCR để nhận diện câu hỏi và tìm đáp án
- **Boss: Rồng Punk** - Auto join lúc 15:30
- **Boss: Kraken** - Auto join lúc 21:00

## OCR cho Tiếng Việt

Sử dụng **EasyOCR** - thư viện OCR mã nguồn mở với hỗ trợ tiếng Việt tốt:
- Không cần cài đặt thêm
- Hỗ trợ cả tiếng Anh và tiếng Việt
- Xử lý được chữ có dấu

## Cấu trúc project

```
├── main.py              # Entry point
├── requirements.txt     # Dependencies
├── utils/
│   ├── logger.py       # Logging utilities
│   ├── window.py       # Window management
│   ├── post_message.py # Mouse/keyboard input
│   ├── date_utils.py   # Date/time utilities
│   └── ocr.py          # EasyOCR wrapper
├── features/
│   ├── enhance.py
│   ├── rakhoi.py
│   ├── daily.py
│   ├── anhhon.py
│   ├── boss.py
│   ├── hoidapcothuong.py
│   └── ...
├── gui/
│   └── main_window.py  # Main GUI
└── resources/
    └── Question.ini    # Q&A database
```

## Logging

Logs được lưu trong thư mục `logs/` với format:
- `auto_vht_YYYYMMDD.log`
- Console: INFO level
- File: DEBUG level

## Dependencies

- `easyocr` - OCR với hỗ trợ tiếng Việt
- `opencv-python` - Xử lý ảnh
- `numpy` - Numerical computing
- `Pillow` - Image processing
- `pywin32` - Windows API
- `rapidfuzz` - Fuzzy string matching cho Q&A

## Tác giả

Auto Kynguyenhaitac

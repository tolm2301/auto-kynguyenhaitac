# OCR worker prototype (PaddleOCR tiếng Việt)

Prototype này dùng **Python worker chạy nền** + **file-based IPC** để nhận ảnh crop từ AHK.

## 1) Python runtime cho worker (chốt)

- Worker dùng **Python 3.11** (không dùng Python 3.13 cho worker path).
- Exe khuyến nghị (máy hiện tại):
  - `C:\Users\ToLM\AppData\Local\Python\pythoncore-3.11-64\python.exe`

Set biến môi trường trước khi chạy AHK:

- `OCR_WORKER_PYTHON=C:\Users\ToLM\AppData\Local\Python\pythoncore-3.11-64\python.exe`

## 2) Cài dependency (pinned)

```bash
"C:\Users\ToLM\AppData\Local\Python\pythoncore-3.11-64\python.exe" -m pip install -r tools/ocr_worker_requirements.txt
```

Version đã pin trong `tools/ocr_worker_requirements.txt`:

- `paddleocr==2.7.3`
- `paddlepaddle==2.6.2`
- `Pillow==10.4.0`
- `numpy==1.26.4` (fix ABI ổn định cho OpenCV/PaddleOCR trên Windows)

## 3) Luồng hoạt động

1. AHK capture vùng OCR thành `HBITMAP`.
2. `_ocr_worker_from_hbitmap(...)` lưu ra PNG temp trong `%TEMP%\auto_kynguyenhaitac_ocr`.
3. AHK ghi request file `requests\req_<id>.req`.
4. Python worker (đã preload PaddleOCR) đọc request, OCR, ghi response `responses\resp_<id>.resp`.
5. AHK đọc response và trả text về `_ocr_from_bit_map(...)`.

## 4) Log debug

- AHK log: `logs/ocr_worker.log`
- Python log: `logs/ocr_worker_py.log`

## 5) Test nhanh

1. Chạy app AHK như bình thường (`main.ahk`).
2. Trigger feature có OCR (ví dụ hỏi đáp).
3. Mở `logs/ocr_worker.log` và kiểm tra:
   - Start command
   - request image path
   - elapsedMs
   - text preview / lỗi

Nếu worker fail khi start, xem `logs/ocr_worker_py.log` để biết lỗi import/model.

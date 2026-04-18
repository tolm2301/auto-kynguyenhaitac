# OCR Engine (`utils/window.ahk` + `utils/OCR.ahk`)

## Overview

OCR engine hiện tại dùng:

- **Capture bitmap thủ công bằng WinAPI/GDI** trong `_ocr_from_bit_map(...)`
- **Nhận dạng text** bằng `OCR.FromBitmap(...)` (class OCR trong `utils/OCR.ahk`)
- **Retry theo scale** ở tầng feature (Q&A): `2.0 -> 2.25 -> 2.5`
- **Hậu xử lý text**: normalize + map sửa lỗi OCR (`FixOCRErrors`)

---

## Implementation

## 1) Bitmap capture flow

### Pipeline

```text
hwnd + (x1,y1,x2,y2)
  -> GetDC(hwnd)
  -> CreateCompatibleDC(hdcWindow)
  -> CreateCompatibleBitmap(w,h)
  -> SelectObject(hdcMem, hbm)
  -> BitBlt(from window DC -> memory DC)
  -> OCR.FromBitmap(hbm, {lang, scale, grayscale})
  -> DeleteObject(hbm)
```

### Signature đang dùng

```ahk
_ocr_from_bit_map(hwnd, x1, y1, x2, y2, ocrOptions := 0, scale := 2.0)
```

| Param | Kiểu | Vai trò |
|---|---|---|
| `hwnd` | Int/Ptr | cửa sổ game |
| `x1,y1,x2,y2` | Int | vùng capture |
| `ocrOptions` | Any | **chưa sử dụng trực tiếp** trong function hiện tại |
| `scale` | Float | scale OCR, mặc định `2.0` |

---

## 2) OCR options thực tế

Trong `_ocr_from_bit_map`, call OCR:

```ahk
result := OCR.FromBitmap(hbm, {lang: "en-US", scale: scale, grayscale: 1})
text := result.text
text := RegExReplace(text, "[^\x20-\x7E]", "")
```

### Option matrix

| Option | Value | Ý nghĩa |
|---|---|---|
| `lang` | `en-US` | OCR language pack |
| `scale` | biến theo call site | tăng kích thước trước OCR |
| `grayscale` | `1` | OCR trên ảnh gray |

---

## 3) Scale retry mechanism

Retry không nằm trong `_ocr_from_bit_map`, mà nằm ở feature gọi OCR:

- Câu hỏi: thường `[2.0, 2.25, 2.5]`
- Option trả lời: ví dụ Hỏi đáp có thưởng dùng `[2.5, 2.75, 3.0]`

Ví dụ (rút gọn từ `features/hoidapcothuong.ahk`):

```ahk
scaleLevels := [2.0, 2.25, 2.5]
for _, scl in scaleLevels {
    questionText := _ocr_from_bit_map(hwnd, 580, 146, 930, 190, 0, scl)
    if (Trim(questionText) != "")
        break
}
```

---

## 4) Text post-processing

## 4.1 Normalize tiếng Việt và sửa lỗi OCR

`_normalize_ocr_text(text)`:

1. map ký tự có dấu -> không dấu (`đ -> d`, `á -> a`, ...)
2. gọi `FixOCRErrors(result)` để thay thế các pattern OCR sai phổ biến

`FixOCRErrors(inputText)`:

- dùng static `ocr_map` (nhiều cặp sai -> đúng)
- sort key theo độ dài giảm dần để tránh replace sai chồng nhau
- replace bằng `RegExReplace` case-insensitive
- normalize spacing (`\s+ -> " "`)

## 4.2 Normalize cho Q&A matching

Tầng Q&A dùng normalize riêng:

- lowercase
- remove prefix đáp án (`A:` / `B:` / ...)
- remove non `[a-z0-9]`

Ví dụ:

```ahk
value := StrLower(Trim(text))
value := RegExReplace(value, "^[abc]\s*[:\-\.)]\s*", "")
value := RegExReplace(value, "[^a-z0-9]+", "")
```

---

## 5) Debug save mechanism (`logs/ocr_debug/`)

Biến global:

```ahk
global g_ocr_debug_mode := false
```

Khi bật `g_ocr_debug_mode = true`, `_ocr_from_bit_map` sẽ:

1. Tạo folder `logs/ocr_debug`
2. Build filename có timestamp + tọa độ (`ocr_yyyyMMdd_HHmmss_x..._y....png`)
3. Gọi `_ocr_save_bitmap_to_file(hbm, debugPath)`
4. `OutputDebug` đường dẫn file

`_ocr_save_bitmap_to_file` dùng GDI+:

- `GdiplusStartup`
- `GdipCreateBitmapFromHBITMAP`
- `GdipSaveImageToFile` (encoder PNG CLSID)
- `finally`: dispose image + shutdown GDI+

---

## Key Functions

| Function | Vai trò |
|---|---|
| `_ocr_from_bit_map(...)` | capture vùng màn hình window + OCR |
| `_ocr_save_bitmap_to_file(hbm, path)` | lưu bitmap debug dạng PNG |
| `_normalize_ocr_text(text)` | normalize text + bỏ dấu tiếng Việt |
| `FixOCRErrors(inputText)` | sửa các lỗi OCR thường gặp theo map |
| `OCR.FromBitmap(...)` | OCR core từ thư viện `utils/OCR.ahk` |

---

## Data Structures

| Name | Type | Nội dung |
|---|---|---|
| `g_ocr_debug_mode` | Bool | bật/tắt lưu ảnh debug OCR |
| `diacritic_map` | Map | map ký tự tiếng Việt -> ASCII |
| `ocr_map` | Map | map text lỗi OCR -> text chuẩn |

---

## Timing

- OCR retry scale chạy tuần tự, không sleep cố định trong `_ocr_from_bit_map`.
- Sleep/pacing OCR phụ thuộc feature gọi OCR (Q&A thường OCR tức thì rồi match).

---

## Error Handling

- `_ocr_save_bitmap_to_file` có `try/finally`, throw khi GDI+/CLSID/save fail.
- `_ocr_from_bit_map` có khối `try` riêng cho phần save debug để không ảnh hưởng flow OCR chính.
- Cleanup handle GDI: `ReleaseDC`, `DeleteDC`, `DeleteObject`.

---

## TODO

1. `ocrOptions` trong `_ocr_from_bit_map` đang chưa được dùng -> cần merge với options call `OCR.FromBitmap`.
2. `text := RegExReplace(text, "[^\x20-\x7E]", "")` loại ký tự ngoài ASCII; có thể làm mất tiếng Việt OCR được -> cần xác nhận chủ đích.
3. Chưa có timeout/retry wrapper thống nhất ở utility-level (retry hiện nằm phân tán trong feature files).

# PaddleOCR local runtime (AHK wrapper)

Luồng OCR chính đang dùng wrapper function-based tại:

- `utils/paddle_ocr.ahk` (các hàm `_paddle_ocr_*`)

Mặc định hiện tại:

- `modelType = "mobile"`
- `lang = "vi"`

---

## Checklist cài asset (mobile + tiếng Việt)

> Thư mục runtime được resolve cố định theo: `vendor\paddleocr\Dll\inference`

### 1) Tải runtime DLL (bắt buộc)

- Nguồn: `telppa/PaddleOCR-AutoHotkey`
- Link trực tiếp thư mục:  
  `https://github.com/telppa/PaddleOCR-AutoHotkey/tree/master/PaddleOCR/Dll`

Cần lấy tối thiểu:

- `PaddleOCR.dll`
- các DLL phụ thuộc đi kèm trong cùng bộ runtime

Đặt vào:

- `vendor\paddleocr\Dll\`

### 2) Tải model detect (mobile_det)

- Link trực tiếp:  
  `https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_det_infer.tar`

Giải nén và **đổi tên thư mục** thành:

- `mobile_det`

Đặt vào:

- `vendor\paddleocr\Dll\inference\mobile_det\`

### 3) Tải model classify (mobile_cls)

- Link trực tiếp:  
  `https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_cls_infer.tar`

Giải nén và **đổi tên thư mục** thành:

- `mobile_cls`

Đặt vào:

- `vendor\paddleocr\Dll\inference\mobile_cls\`

### 4) Tải model recognize tiếng Việt (mobile_rec_vi)

- Link trực tiếp (bản thử nhanh đã chốt):  
  `https://paddleocr.bj.bcebos.com/dygraph_v2.0/multilingual/latin_PP-OCRv3_mobile_rec_infer.tar`

Giải nén và **đổi tên thư mục** thành:

- `mobile_rec_vi`

Đặt vào:

- `vendor\paddleocr\Dll\inference\mobile_rec_vi\`

### 5) Tải từ điển tiếng Việt (dict_vi.txt)

- Link trực tiếp upstream:  
  `https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/dict/vi_dict.txt`

Đổi tên file thành:

- `dict_vi.txt`

Đặt vào:

- `vendor\paddleocr\Dll\inference\dict_vi.txt`

---

## Cây thư mục cuối cùng (đúng tên để wrapper nhận)

```text
vendor/
  paddleocr/
    Dll/
      PaddleOCR.dll
      ... (DLL phụ thuộc khác)
      inference/
        mobile_cls/
          inference.pdmodel
          inference.pdiparams
          inference.pdiparams.info
        mobile_det/
          inference.pdmodel
          inference.pdiparams
          inference.pdiparams.info
        mobile_rec_vi/
          inference.pdmodel
          inference.pdiparams
          inference.pdiparams.info
        dict_vi.txt
```

## Ghi chú nhanh

- Repo này đang validate asset theo path: `vendor\paddleocr\Dll\inference\...`
- Nếu thiếu 1 trong các mục trên, OCR sẽ fail ở bước validate/init runtime.
- Cần chạy AutoHotkey x64 (`A_PtrSize = 8`).

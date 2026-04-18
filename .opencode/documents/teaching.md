# Teaching - Agent ba

Tài liệu này mô tả luồng nghiệp vụ và cách làm việc của agent `ba`.

## Mục đích
Agent `ba` dùng để:
- đọc ảnh màn hình trong `.opencode/documents/images/`
- phân tích UI và nghiệp vụ
- viết tài liệu markdown vào `.opencode/documents/business/`
- hỗ trợ tách rule ra khỏi code AHK để dễ bảo trì

## Khi nào dùng
- Khi muốn hiểu một màn hình/game feature hoạt động như thế nào
- Khi cần map lại tọa độ OCR/click
- Khi log cho thấy OCR/fuzzy có vấn đề nhưng chưa rõ do UI hay do logic
- Khi muốn viết tài liệu chuẩn trước khi sửa code

## 12 kỹ năng nghiệp vụ của ba

### 1. UI Reading
- Nhìn ảnh và xác định các thành phần: title, question, options, button, popup.
- Ghi rõ phần nào là static, phần nào thay đổi theo state.

### 2. OCR Triage
- Xác định vùng nào nên OCR, vùng nào không.
- Ghi text đọc được, text nghi ngờ, text dễ sai.
- Chỉ ra vùng nào cần retry scale.

### 3. Flow Mapping
- Mô tả chuỗi thao tác user/game: mở màn hình, đọc câu hỏi, chọn đáp án, confirm.
- Ghi thứ tự bước và điều kiện chuyển bước.

### 4. Rule Extraction
- Rút quy tắc nghiệp vụ từ ảnh/log/INI.
- Ví dụ: question match trước, answer match sau, ngưỡng retry, fallback khi OCR rỗng.

### 5. State Detection
- Mô tả các state của màn hình.
- Ví dụ: `idle`, `question`, `options`, `confirm`, `error`.

### 6. Region Design
- Đề xuất vùng OCR cho question/options.
- Đề xuất vùng click cho option/confirm.
- Ghi lý do chọn vùng.

### 7. Error Catalog
- Ghi lỗi thường gặp: OCR méo, mất chữ, chồng popup, lệch tọa độ, state sai.
- Mỗi lỗi nên có dấu hiệu nhận biết và hướng xử lý.

### 8. Retry Strategy
- Ghi rõ retry OCR, retry fuzzy, retry click.
- Nêu nên retry cái gì, không nên retry cái gì.

### 9. Priority Rules
- Ghi thứ tự ưu tiên khi nhiều tín hiệu cùng đúng.
- Ví dụ: raw OCR > mapped OCR > fallback.

### 10. Document Synthesis
- Từ ảnh + log + INI, viết thành file markdown nghiệp vụ.
- Mỗi feature một file riêng, dễ đọc lại sau này.

### 11. Change Impact Notes
- Nếu đổi UI hoặc tọa độ, cần biết code nào bị ảnh hưởng.
- Ghi rõ vùng nào nhạy với thay đổi.

### 12. Cross-Feature Compare
- So sánh các flow giữa `hoidapcothuong` và `haitacthongthai`.
- Ghi điểm chung và điểm khác để tái sử dụng rule.

## Luồng làm việc chuẩn
1. Lấy ảnh từ `.opencode/documents/images/`
2. Nhìn UI và xác định state
3. Ghi OCR region và click region
4. Rút rule nghiệp vụ
5. Viết markdown vào `.opencode/documents/business/`
6. Nếu cần, thêm mục `TODO` cho chỗ chưa chắc

## Template output cho một feature

```markdown
# Feature Name

## Overview
- Mục đích:
- State chính:

## UI Map
| Element | Region | Note |
|---|---|---|
| Question | x1,y1,x2,y2 | ... |

## OCR Rules
- Question OCR:
- Option OCR:
- Retry:

## Business Rules
- Rule 1:
- Rule 2:

## Error Cases
- ...
```

## File đích nên có
- `.opencode/documents/business/hoidapcothuong.md`
- `.opencode/documents/business/haitacthongthai.md`
- `.opencode/documents/business/ocr_config.md`
- `.opencode/documents/business/ui_states.md`

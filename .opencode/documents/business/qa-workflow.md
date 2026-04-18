# QA Workflow

## Overview
Có 2 feature hỏi đáp:
- **Hỏi đáp có thưởng**: 3 đáp án `A/B/C`
- **Hải tặc thông thái**: 4 đáp án `A/B/C/D`

Chung một nguyên tắc: OCR câu hỏi -> fuzzy match `Question.ini` -> OCR đáp án -> chọn đáp án có score cao nhất -> click xác nhận.

## OCR flow
```text
OCR câu hỏi
 -> clean text
 -> map OCR text qua vocab cache
 -> fuzzy match question trong Question.ini
 -> lấy answer expected
 -> OCR các option
 -> score từng option
 -> chọn option tốt nhất
 -> click option + confirm
```

## OCR regions
### Hỏi đáp có thưởng
| Vùng | Tọa độ | Scale retry |
|---|---|---|
| Question | `580,146 -> 930,190` | `2.0 -> 2.25 -> 2.5` |
| A | `622,181 -> 888,215` | `2.5 -> 2.75 -> 3.0` |
| B | `622,213 -> 888,241` | `2.5 -> 2.75 -> 3.0` |
| C | `622,245 -> 815,288` | `2.5 -> 2.75 -> 3.0` |
| Confirm | click `856,284` | - |

### Hải tặc thông thái
| Vùng | Tọa độ | Scale retry |
|---|---|---|
| Question | `294,190 -> 977,340` | `2.0 -> 2.25 -> 2.5` |
| A | `290,352 -> 974,403` | `2.5` |
| B | `290,405 -> 974,457` | `2.5` |
| C | `290,460 -> 974,509` | `2.5` |
| D | `290,516 -> 974,559` | `2.5` |
| Confirm | click `907,584` | - |

## Fuzzy matching algorithm
### Common rule
- normalize lowercase
- bỏ ký tự đặc biệt
- tách token theo nhóm chữ/số
- tính score bằng:
  - `charScore` (StrDiff)
  - `tokenScore` (overlap token)
  - `blendScore = char*0.65 + token*0.35`
  - chọn `max(charScore, tokenScore, blendScore)`

### Retry threshold
Thử tuần tự: `0.8 -> 0.7 -> 0.6 -> 0.5 -> 0.4 -> 0.3`

### Vocab cache
| Feature | Section ini | Cache |
|---|---|---|
| Hỏi đáp có thưởng | `[Questions]` | `questionTokens`, `answerTokens`, `questionFixCache`, `answerFixCache` |
| Hải tặc thông thái | `[Haitacthongthai]` | tương tự |

Cache dùng để:
- sửa lỗi OCR phổ biến
- map token gần giống sang vocab chuẩn
- giảm sai số khi question/answer bị dính ký tự lạ

## Answer selection
### Hỏi đáp có thưởng (ABC)
- OCR từng option A/B/C
- lấy `expectedRaw` từ question match
- score option theo raw text và mapped text
- nếu `letter = ""` hoặc `score < 0.3` -> bỏ qua
- nếu question score < 0.3 -> không trả lời
- click option rồi click confirm

### Hải tặc thông thái (ABCD)
- OCR từng option A/B/C/D
- match answer expected với option
- nếu `bestScore < 0.40` -> hiện MsgBox cảnh báo, không auto click
- nếu đủ tin cậy -> click option + confirm

## Điểm khác nhau Hoidap vs HTTT
| Hạng mục | Hoidap | HTTT |
|---|---|---|
| Số đáp án | 3 | 4 |
| Vùng question | hẹp hơn | rộng hơn |
| Threshold an toàn | 0.3 | 0.4 |
| Hành vi khi score thấp | dừng luôn | báo MsgBox, không click |
| Cache section | `[Questions]` | `[Haitacthongthai]` |

## Risks
- OCR scale sai làm question rỗng
- đáp án dài nhiều dòng dễ dính option khác
- fuzzy match có thể chọn nhầm nếu question gần giống nhau
- HTTT có risk tie-break nội bộ, cần verify khi dữ liệu câu hỏi nhiều

## TODO
- TODO: thống nhất chuẩn nhập `Question.ini` cho cả 2 feature
- TODO: bổ sung test case cho câu có số / năm / ngày tháng
- TODO: rà soát lại các câu có answer dạng list nhiều từ

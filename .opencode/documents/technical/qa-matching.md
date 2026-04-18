# Q&A Fuzzy Matching (`hoidapcothuong.ahk` + `haitacthongthai.ahk`)

## Overview

Hai feature Q&A dùng chung chiến lược:

1. OCR câu hỏi + OCR các lựa chọn
2. Normalize text
3. Fuzzy match câu hỏi với `resources/Question.ini`
4. Fuzzy match đáp án expected với option OCR
5. Chọn letter tốt nhất theo score + tie-break rule

Khác biệt chính:

- `hoidapcothuong`: 3 đáp án A/B/C
- `haitacthongthai`: 4 đáp án A/B/C/D

---

## Implementation

## 1) Vocab cache structure

Cả 2 module load cache 1 lần:

- `_hoidap_load_vocab_cache()` đọc section `[Questions]`
- `_httt_load_vocab_cache()` đọc section `[Haitacthongthai]`

### Cấu trúc cache

| Key | Type | Nội dung |
|---|---|---|
| `questionTokens` | Map[token -> true] | vocab token của câu hỏi |
| `answerTokens` | Map[token -> true] | vocab token của đáp án |
| `iniEntries` | Array<object> | danh sách `{q, qNorm, qCompact, a}` |
| `questionFixCache` | Map | cache sửa token OCR câu hỏi |
| `answerFixCache` | Map | cache sửa token OCR đáp án |

---

## 2) Normalize pipeline

## 2.1 Cho fuzzy question matching

- lowercase
- remove cụm `thoi gian tra loi con ...`
- thay ký tự OCR nhiễu (module hoidap có thêm rule 0/6->o, 1->i, ...)
- regex `[^a-z0-9]+ -> " "`
- collapse spaces

## 2.2 Cho answer comparison

- lowercase
- bỏ prefix letter (`A:`, `B)`, ...)
- regex `[^a-z0-9]+ -> ""`

---

## 3) StrDiff algorithm (Levenshtein-based)

`StrDiff` (`_httt_str_diff` bên HTTT) trả về similarity 0..1:

```text
similarity = 1 - (levenshtein_distance / max(len1, len2))
```

Đặc điểm:

- Dùng DP matrix `(L1+1) x (L2+1)`
- Case-insensitive (đưa về lowercase trước)
- Nếu một chuỗi rỗng -> 0

---

## 4) Token overlap score

`_question_token_overlap_score(a, b)` / `_httt_question_token_overlap_score(a,b)`:

1. Tách token regex `[a-z0-9]{3,}`
2. Đếm token trùng (exact hoặc gần chứa nhau)
3. Score = `hit / totalSearchTokens`

---

## 5) Combined score formula

Khi so câu hỏi với mỗi entry:

```text
charScore  = StrDiff(searchCompact, entryCompact)
tokenScore = token_overlap(searchNorm, entryNorm)
blendScore = charScore * 0.65 + tokenScore * 0.35
finalScore = max(charScore, tokenScore, blendScore)
```

Ngoài ra có pre-filter `commonCount < 2` thì skip candidate.

---

## 6) Threshold retry cascade

Áp dụng cho cả tìm câu hỏi và chọn đáp án:

```text
0.8 -> 0.7 -> 0.6 -> 0.5 -> 0.4 -> 0.3
```

Logic:

- Ưu tiên match ở threshold cao trước
- Nếu fail thì hạ dần
- Dừng ngay khi tìm được kết quả hợp lệ

---

## 7) Answer selection + tie-breaking

### Hỏi đáp có thưởng (A/B/C)

Rule trong `_hoidap_find_best_answer_for_options`:

1. score chính = `max(rawScore, mappedScore)`
2. tie-break level 1: `rawScore` cao hơn
3. tie-break level 2: `mappedScore` cao hơn
4. tie-break level 3: **letter priority `C > B > A`**

`letterPriority := Map("A", 1, "B", 2, "C", 3)`

### Hải tặc thông thái (A/B/C/D)

`letterPriority := {A: 3, B: 2, C: 1, D: 0}` và điều kiện chọn dùng `<` ở tie-break,
=> thứ tự ưu tiên thực tế: **D > C > B > A**.

> Lưu ý: rule này khác yêu cầu C > B > A (đối với mode 3 đáp án). HTTT có thêm D nên đang dùng policy khác.

---

## Key Functions

| Module | Function | Vai trò |
|---|---|---|
| hoidap | `_hoidap_find_best_with_retry` | tìm câu hỏi tốt nhất theo threshold cascade |
| hoidap | `_hoidap_fuzzy_match_cached` | match nhanh từ `iniEntries` cache |
| hoidap | `_hoidap_find_best_answer_for_options` | chọn A/B/C tốt nhất |
| hoidap | `StrDiff` | similarity Levenshtein-based |
| httt | `_httt_find_best_with_retry` | retry threshold cho câu hỏi |
| httt | `_httt_fuzzy_match_cached` | fuzzy từ cache |
| httt | `_httt_find_best_answer_for_options` | chọn A/B/C/D tốt nhất |
| httt | `_httt_str_diff` | similarity Levenshtein-based |

---

## Data Structures

| Name | Type | Mục đích |
|---|---|---|
| `_hoidap_vocab_cache` | Map | cache từ section `[Questions]` |
| `_httt_vocab_cache` | Map | cache từ section `[Haitacthongthai]` |
| `_hoidap_fuzzy_retry_cache` | Map | memo kết quả fuzzy retry theo key `(mapped|raw|threshold)` |
| `optionMap` | Map | map letter -> OCR option text |

---

## Timing

- OCR question retry scale: `2.0/2.25/2.5`
- OCR option retry (hoidap): `2.5/2.75/3.0`
- click answer + confirm: mỗi bước sleep `500 ms`

---

## Error Handling

- Nếu OCR question rỗng -> log và return.
- Nếu question score < 0.3 -> bỏ qua.
- Nếu answer score < 0.3 hoặc không xác định letter -> bỏ qua.
- Logging ra:
  - `logs/hoidap.log`
  - `logs/haitacthongthai.log`

---

## TODO

1. Chuẩn hóa tie-break policy giữa 2 module (đặc biệt HTTT có ưu tiên D cao nhất).
2. Gom duplicated logic (normalize, tokenization, fuzzy core) vào `utils/qa_matcher.ahk`.
3. Bổ sung benchmark/log thống kê chất lượng match theo từng threshold.

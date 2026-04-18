---
name: ocr-tuning
description: Tune OCR workflows for Vietnamese and mixed UI text in AHK2
compatibility: opencode
metadata:
  domain: ahk2
  area: vision
---

## What I do
- Tối ưu OCR cho câu hỏi/đáp án game với retry nhiều scale và nhiều ngưỡng
- Chuẩn hoá text mạnh (lowercase, bỏ dấu, lọc ký tự) để fuzzy match ổn định
- Giảm sai OCR bằng vocab cache + token mapping + FixOCRErrors

## Key Patterns (from real project)
- Scale retry cascade thực chiến: `2.0 -> 2.25 -> 2.5 -> 2.75 -> 3.0` (chia theo question/options)
- Vocab cache dạng `Map`: `questionTokens`, `answerTokens`, `iniEntries`
- Fuzzy match dùng `StrDiff` (Levenshtein-based), `tokenScore`, `blendScore`
- Threshold retry: `[0.8, 0.7, 0.6, 0.5, 0.4, 0.3]`
- Normalize: lowercase + remove diacritics + regex `[^a-z0-9]`
- `FixOCRErrors` dùng `sorted_keys` và insertion sort để ưu tiên thay chuỗi dài trước

## Code Examples
```autohotkey
_ocr_from_bit_map(hwnd, x1, y1, x2, y2, ocrOptions := 0, scale := 2.0) {
    x := x1
    y := y1
    w := x2 - x1
    h := y2 - y1

    hdcWindow := DllCall("GetDC", "Ptr", hwnd)
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcWindow)
    hbm := DllCall("CreateCompatibleBitmap", "Ptr", hdcWindow, "Int", w, "Int", h)
    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hbm)
    DllCall("BitBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdcWindow, "Int", x, "Int", y, "UInt", 0x00CC0020)
    DllCall("ReleaseDC", "Ptr", hwnd, "Ptr", hdcWindow)
    DllCall("DeleteDC", "Ptr", hdcMem)

    result := OCR.FromBitmap(hbm, {lang: "en-US", scale: scale, grayscale: 1})
    text := result.text
    text := RegExReplace(text, "[^\x20-\x7E]", "")

    DllCall("DeleteObject", "Ptr", hbm)

    return text
}

_hoidap_auto_answer(hwnd) {
    scaleLevels := [2.0, 2.25, 2.5]
    questionText := ""
    usedScale := ""
    for idx, scl in scaleLevels {
        questionText := _ocr_from_bit_map(hwnd, 580, 146, 930, 190, 0, scl)
        questionText := _hoidap_clean_question_text(questionText)
        if (Trim(questionText) != "") {
            usedScale := scl
            break
        }
    }
}

_hoidap_read_option_text_with_retry(hwnd, x1, y1, x2, y2) {
    scaleLevels := [2.5, 2.75, 3.0]
    bestText := ""
    firstNonEmpty := ""

    for idx, scl in scaleLevels {
        text := Trim(_ocr_from_bit_map(hwnd, x1, y1, x2, y2, 0, scl))
        if (text = "")
            continue

        if (firstNonEmpty = "")
            firstNonEmpty := text

        if (bestText = "")
            bestText := text
    }

    if (bestText != "")
        return bestText
    return firstNonEmpty
}

_hoidap_find_best_with_retry(iniPath, mappedText, rawText, threshold) {
    thresholdLevels := [0.8, 0.7, 0.6, 0.5, 0.4, 0.3]

    for _, currentThreshold in thresholdLevels {
        if (Trim(mappedText) != "") {
            result := _hoidap_fuzzy_match_cached(mappedText, currentThreshold)
            if (result.Score > 0)
                return result
        }

        if (Trim(rawText) != "") {
            result := _hoidap_fuzzy_match_cached(rawText, currentThreshold)
            if (result.Score > 0)
                return result
        }
    }

    return {Score: 0}
}

_hoidap_fuzzy_match_cached(searchStr, threshold) {
    charScore := StrDiff(searchCompact, entry.qCompact)
    tokenScore := _question_token_overlap_score(searchNorm, entry.qNorm)
    blendScore := (charScore * 0.65 + tokenScore * 0.35)
    score := Max(charScore, tokenScore, blendScore)
}

_normalize_qa_text(text) {
    value := StrLower(Trim(text))
    value := RegExReplace(value, "^[abc]\s*[:\-\.)]\s*", "")
    value := RegExReplace(value, "[^a-z0-9]+", "")
    return value
}

_normalize_ocr_text(text) {
    diacritic_map := Map(
        "à","a","á","a","ả","a","ã","a","ạ","a",
        "â","a","ầ","a","ấ","a","ẩ","a","ẫ","a","ậ","a",
        "Đ","d","đ","d"
    )

    result := ""
    loop parse text {
        c := A_LoopField
        result .= diacritic_map.Has(c) ? diacritic_map[c] : c
    }

    return FixOCRErrors(result)
}

FixOCRErrors(inputText) {
    static sorted_keys := 0
    if !sorted_keys {
        sorted_keys := []
        for wrong in ocr_map
            sorted_keys.Push(wrong)
        ; Insertion sort - O(n^2) nhưng n nhỏ nên không vấn đề
        loop sorted_keys.Length {
            i := A_Index
            while i > 1 && StrLen(sorted_keys[i]) > StrLen(sorted_keys[i-1]) {
                temp := sorted_keys[i], sorted_keys[i] := sorted_keys[i-1], sorted_keys[i-1] := temp, i--
            }
        }
    }
}
```

## Implementation Details
- Tách OCR question và OCR options thành 2 pha scale khác nhau để tiết kiệm thời gian nhưng vẫn đủ chính xác.
- Dùng cache `iniEntries` để fuzzy trong RAM, không đọc INI lặp lại mỗi lần OCR.
- So khớp token có điều kiện `commonCount < 2` thì bỏ qua để giảm false positive.
- Score cuối lấy `Max(char, token, blend)` để tận dụng cả khoảng cách ký tự lẫn ngữ nghĩa token.
- Map token OCR về vocab chuẩn với `StrDiff >= 0.8` và cache fix token để lần sau nhanh hơn.

## Timing & Constants
- Scale question: `[2.0, 2.25, 2.5]`
- Scale options: `[2.5, 2.75, 3.0]`
- Threshold retry: `[0.8, 0.7, 0.6, 0.5, 0.4, 0.3]`
- Blend score weight: `char 0.65` + `token 0.35`
- Early stop fuzzy khi `score >= 0.95`

## Checklist
1. OCR phải qua normalize trước khi match.
2. Có scale retry cascade, không đọc 1 scale cố định.
3. Có threshold retry từ cao xuống thấp.
4. Có vocab cache `questionTokens/answerTokens/iniEntries`.
5. Có log score (`char/token/blend`) khi cần debug.

## Common Mistakes
- Chỉ dùng 1 score (char hoặc token) nên match sai câu gần giống.
- Không remove dấu/ký tự lạ trước khi fuzzy.
- Không sort key thay thế OCR theo độ dài -> replace ngắn đè replace dài.
- Quên cache token fix làm tốc độ giảm mạnh khi chạy liên tục.

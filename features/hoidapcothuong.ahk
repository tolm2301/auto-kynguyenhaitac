_feature_hoidapcothuong() {
    global isRunning, g_featureText

    _win_resize_list()
    hwnds := _win_get_list()
    if (hwnds.Length = 0)
        return

    isRunning := true
    g_featureText.Text := "Tính năng đang chạy: Hỏi đáp có thưởng"

    hwnd := hwnds[1]
    _hoidap_auto_answer(hwnd)
}

_hoidap_auto_answer(hwnd) {
    iniPath := A_ScriptDir . "\resources\Question.ini"
    section := _hoidap_get_section()

    questionText := _hoidap_read_question(hwnd)
    if (Trim(questionText) = "") {
        _hoidap_log("OCR câu hỏi rỗng")
        return
    }

    bestMatch := FindFuzzyMatch(iniPath, section, questionText, 0.4)
    if (bestMatch.Score <= 0) {
        _hoidap_log("Không tìm thấy câu hỏi đủ match (>=0.4) | OCR Q: " . questionText)
        return
    }

    _hoidap_log("Q match | score=" . Format("{:.3f}", bestMatch.Score) . " | Q=" . bestMatch.Question . " | A=" . bestMatch.Answer)

    optionMap := _hoidap_read_option_map(hwnd)
    _hoidap_log_game_options(optionMap)
    result := _pick_answer_letter_from_option_map(bestMatch.Answer, optionMap)
    answerLetter := result.letter

    if (answerLetter = "") {
        _hoidap_log("Không xác định được đáp án A/B/C | OCR Q: " . questionText)
        return
    }

    if _click_hoidap_answer(hwnd, answerLetter)
        _hoidap_log("Đã trả lời " . answerLetter . " | Answer score: " . Format("{:.3f}", result.score) . " | expected=" . result.expected)
}

_hoidap_log_game_options(optionMap) {
    text := ""
    for letter in ["A", "B", "C"] {
        raw := optionMap.Has(letter) ? Trim(optionMap[letter]) : ""
        parsed := _extract_option_value_from_ocr(raw, letter)
        norm := _normalize_qa_text(parsed)
        text .= letter . " raw=[" . raw . "] parsed=[" . parsed . "] norm=[" . norm . "] | "
    }
    _hoidap_log("OCR options | " . text)
}

_hoidap_get_section() {
    return "Questions"
}

_hoidap_read_question(hwnd) {
    return _ocr_from_bit_map(hwnd, 634, 154, 884, 186)
}

_hoidap_get_option_config() {
    static cfg := Map(
        "A", {ocrX1: 622, ocrY1: 181, ocrX2: 888, ocrY2: 215, clickX: 633, clickY: 197},
        "B", {ocrX1: 622, ocrY1: 213, ocrX2: 888, ocrY2: 241, clickX: 636, clickY: 229},
        "C", {ocrX1: 622, ocrY1: 245, ocrX2: 815, ocrY2: 288, clickX: 636, clickY: 260}
    )
    return cfg
}

_hoidap_get_confirm_button_config() {
    return {x: 856, y: 284}
}

_hoidap_read_option_map(hwnd) {
    cfg := _hoidap_get_option_config()
    optionMap := Map()
    for letter in ["A", "B", "C"] {
        opt := cfg[letter]
        optionMap[letter] := _ocr_from_bit_map(hwnd, opt.ocrX1, opt.ocrY1, opt.ocrX2, opt.ocrY2)
    }
    return optionMap
}

_click_hoidap_answer(hwnd, answerLetter) {
    cfg := _hoidap_get_option_config()
    confirm := _hoidap_get_confirm_button_config()
    if !cfg.Has(answerLetter)
        return false

    _click_post(hwnd, cfg[answerLetter].clickX, cfg[answerLetter].clickY)
    Sleep 1000
    ; _click_post(hwnd, confirm.x, confirm.y)
    ; Sleep 1000
    return true
}

_pick_answer_letter_from_option_map(answerText, optionMap) {
    expected := _normalize_qa_text(_extract_answer_value(answerText))
    if (expected = "")
        return {letter: "", score: 0.0, expected: expected}

    bestLetter := ""
    bestScore := -1.0
    detail := ""
    hasAnyOptionText := false

    for letter in ["A", "B", "C"] {
        if !optionMap.Has(letter)
            continue

        optionParsed := _extract_option_value_from_ocr(optionMap[letter], letter)
        optionNorm := _normalize_qa_text(optionParsed)
        if (optionNorm = "")
            continue

        hasAnyOptionText := true

        score := _hoidap_similarity(expected, optionNorm)
        detail .= letter . "=" . Format("{:.3f}", score) . "(" . optionNorm . ") "

        if (score > bestScore) {
            bestScore := score
            bestLetter := letter
        }
    }

    _hoidap_log("Answer score | expected=" . expected . " | " . Trim(detail) . "| pick=" . bestLetter)

    if !hasAnyOptionText {
        fallbackLetter := _extract_answer_letter(answerText)
        if (fallbackLetter != "") {
            _hoidap_log("Answer OCR rong, fallback theo INI letter=" . fallbackLetter)
            return {letter: fallbackLetter, score: 0.0, expected: expected}
        }
    }

    if (bestLetter = "")
        return {letter: "", score: 0.0, expected: expected}

    return {letter: bestLetter, score: bestScore, expected: expected}
}

_extract_answer_value(answerText) {
    text := Trim(answerText)
    if RegExMatch(text, "^[ABCabc]\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])
    return text
}

_extract_answer_letter(answerText) {
    text := Trim(answerText)
    if RegExMatch(text, "^([ABCabc])\s*[:\-\.)]", &m)
        return StrUpper(m[1])
    return ""
}

_extract_option_value_from_ocr(optionText, letter) {
    text := StrReplace(optionText, "`r", "")
    text := Trim(text)

    if RegExMatch(text, "^" . letter . "\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])

    if RegExMatch(text, "^[ABCabc]\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])

    lines := StrSplit(text, "`n")
    for line in lines {
        line := Trim(line)
        if (line = "")
            continue
        if RegExMatch(line, "^" . letter . "\s*[:\-\.)]\s*(.+)$", &m)
            return Trim(m[1])
    }

    for line in lines {
        line := Trim(line)
        if (line != "")
            return line
    }

    return text
}

_hoidap_similarity(expectedNorm, candidateNorm) {
    if (expectedNorm = candidateNorm)
        return 1.0

    if InStr(candidateNorm, expectedNorm) || InStr(expectedNorm, candidateNorm) {
        minLen := Min(StrLen(expectedNorm), StrLen(candidateNorm))
        maxLen := Max(StrLen(expectedNorm), StrLen(candidateNorm))
        return 0.9 + (minLen / maxLen) * 0.1
    }

    return StrDiff(expectedNorm, candidateNorm)
}

_normalize_qa_text(text) {
    value := StrLower(Trim(text))
    value := RegExReplace(value, "^[abc]\s*[:\-\.)]\s*", "")
    value := RegExReplace(value, "[^a-z0-9]+", "")
    return value
}

_hoidap_log(msg) {
    logDir := A_ScriptDir . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\hoidap.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    FileAppend("[" . timestamp . "] " . msg . "`n", logPath, "UTF-8")
}

FindFuzzyMatch(IniPath, Section, SearchStr, Threshold := 0.6) {
    BestScore := 0
    MatchedQ := ""
    MatchedA := ""

    try {
        AllData := IniRead(IniPath, Section)
    } catch {
        return {Score: 0}
    }

    Loop Parse, AllData, "`n", "`r" {
        if (A_LoopField = "")
            continue

        Pos := InStr(A_LoopField, "=")
        if (!Pos)
            continue

        FileQ := SubStr(A_LoopField, 1, Pos - 1)
        FileA := SubStr(A_LoopField, Pos + 1)
        CurrentScore := StrDiff(SearchStr, FileQ)

        if (CurrentScore > BestScore) {
            BestScore := CurrentScore
            MatchedQ := FileQ
            MatchedA := FileA
        }
    }

    if (BestScore >= Threshold)
        return {Score: BestScore, Question: MatchedQ, Answer: MatchedA}

    return {Score: 0}
}

StrDiff(s1, s2) {
    L1 := StrLen(s1), L2 := StrLen(s2)
    if (L1 = 0 || L2 = 0)
        return 0

    s1 := StrLower(s1), s2 := StrLower(s2)

    MaxLen := Max(L1, L2)
    Dist := Array()
    Loop L1 + 1 {
        i := A_Index - 1
        Dist.Push(Array())
        Loop L2 + 1 {
            j := A_Index - 1
            Dist[i + 1].Push(i = 0 ? j : (j = 0 ? i : 0))
        }
    }

    Loop L1 {
        i := A_Index
        Loop L2 {
            j := A_Index
            cost := (SubStr(s1, i, 1) = SubStr(s2, j, 1) ? 0 : 1)
            Dist[i + 1][j + 1] := Min(Dist[i][j + 1] + 1, Dist[i + 1][j] + 1, Dist[i][j] + cost)
        }
    }

    return 1 - (Dist[L1 + 1][L2 + 1] / MaxLen)
}

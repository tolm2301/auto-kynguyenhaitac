_feature_haitacthongthai() {
    global isRunning, g_featureText

    _win_resize_list()
    hwnds := _win_get_list()
    if (hwnds.Length = 0)
        return

    isRunning := true
    g_featureText.Text := "Tính năng đang chạy: Hải tặc thông thái"

    iniPath := A_ScriptDir . "\resources\Question.ini"
    section := "Haitacthongthai"

    hwnd := hwnds[1]


    questionText := _httt_read_question(hwnd)
    if (Trim(questionText) = "") {
        _httt_log("OCR câu hỏi rỗng")
        return
    }

    bestMatch := _httt_find_fuzzy_match(iniPath, section, questionText, 0.4)
    if (bestMatch.Score <= 0) {
        _httt_log("Không match câu hỏi | OCR Q: " . questionText)
        return
    }

    for hwndElement in hwnds {
        if !isRunning
            return

        optionMap := _httt_read_option_map(hwndElement)
        result := _httt_pick_answer(bestMatch.Answer, optionMap)
        if (result.letter = "") {
            _httt_log("Không xác định đáp án | Q: " . bestMatch.Question)
            continue
        }

        if _httt_click_answer(hwndElement, result.letter)
            _httt_log("Đã trả lời " . result.letter . " | Q=" . bestMatch.Question . " | A=" . bestMatch.Answer)
    }
}

_httt_read_question(hwnd) {
    return _ocr_from_bit_map(hwnd, 294, 190, 977, 329)
}

_httt_get_option_config() {
    static cfg := Map(
        "A", { ocrX1: 300, ocrY1: 355, ocrX2: 974, ocrY2: 397, clickX: 318, clickY: 373 },
        "B", { ocrX1: 300, ocrY1: 407, ocrX2: 974, ocrY2: 450, clickX: 318, clickY: 425 },
        "C", { ocrX1: 300, ocrY1: 462, ocrX2: 974, ocrY2: 506, clickX: 318, clickY: 478 },
        "D", { ocrX1: 300, ocrY1: 515, ocrX2: 974, ocrY2: 556, clickX: 318, clickY: 532 }
    )
    return cfg
}

_httt_get_confirm_button_config() {
    return { x: 907, y: 584 }
}

_httt_read_option_map(hwnd) {
    cfg := _httt_get_option_config()
    optionMap := Map()
    for letter in ["A", "B", "C", "D"] {
        opt := cfg[letter]
        optionMap[letter] := _ocr_from_bit_map(hwnd, opt.ocrX1, opt.ocrY1, opt.ocrX2, opt.ocrY2)
    }
    _httt_log("OCR options | A=[" . optionMap["A"] . "] B=[" . optionMap["B"] . "] C=[" . optionMap["C"] . "]" . "] D=[" . optionMap["D"] . "]")
    return optionMap
}

_httt_pick_answer(answerText, optionMap) {
    expected := _httt_normalize(_httt_extract_answer_value(answerText))
    bestLetter := ""
    bestScore := -1.0
    scoreLog := ""

    for letter in ["A", "B", "C", "D"] {
        if !optionMap.Has(letter)
            continue
        optionValue := _httt_extract_option_value(optionMap[letter], letter)
        optionNorm := _httt_normalize(optionValue)
        if (optionNorm = "")
            continue

        score := _httt_similarity(expected, optionNorm)
        scoreLog .= letter . "=" . Format("{:.3f}", score) . " "

        if (score > bestScore) {
            bestScore := score
            bestLetter := letter
        }
    }

    _httt_log("Answer score | expected=" . expected . " | " . Trim(scoreLog) . "| pick=" . bestLetter)
    return { letter: bestLetter, score: bestScore }
}

_httt_click_answer(hwnd, answerLetter) {
    cfg := _httt_get_option_config()
    confirm := _httt_get_confirm_button_config()
    if !cfg.Has(answerLetter)
        return false

    _click_post(hwnd, cfg[answerLetter].clickX, cfg[answerLetter].clickY)
    Sleep 250
    ; _click_post(hwnd, confirm.x, confirm.y)
    ; Sleep 600
    return true
}

_httt_extract_answer_value(answerText) {
    text := Trim(answerText)
    if RegExMatch(text, "^[ABCabc]\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])
    return text
}

_httt_extract_option_value(optionText, letter) {
    text := Trim(StrReplace(optionText, "`r", ""))
    if RegExMatch(text, "^" . letter . "\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])
    if RegExMatch(text, "^[ABCabc]\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])
    return text
}

_httt_normalize(text) {
    value := StrLower(Trim(text))
    value := RegExReplace(value, "^[abc]\s*[:\-\.)]\s*", "")
    value := RegExReplace(value, "[^a-z0-9]+", "")
    return value
}

_httt_similarity(a, b) {
    if (a = b)
        return 1.0
    return _httt_str_diff(a, b)
}

_httt_find_fuzzy_match(iniPath, section, searchStr, threshold := 0.6) {
    bestScore := 0
    matchedQ := ""
    matchedA := ""

    try {
        allData := IniRead(iniPath, section)
    } catch {
        return { Score: 0 }
    }

    Loop Parse, allData, "`n", "`r" {
        if (A_LoopField = "")
            continue

        pos := InStr(A_LoopField, "=")
        if (!pos)
            continue

        fileQ := SubStr(A_LoopField, 1, pos - 1)
        fileA := SubStr(A_LoopField, pos + 1)
        currentScore := _httt_str_diff(searchStr, fileQ)

        if (currentScore > bestScore) {
            bestScore := currentScore
            matchedQ := fileQ
            matchedA := fileA
        }
    }

    if (bestScore >= threshold)
        return { Score: bestScore, Question: matchedQ, Answer: matchedA }

    return { Score: 0 }
}

_httt_str_diff(s1, s2) {
    L1 := StrLen(s1), L2 := StrLen(s2)
    if (L1 = 0 || L2 = 0)
        return 0

    s1 := StrLower(s1), s2 := StrLower(s2)
    maxLen := Max(L1, L2)
    dist := Array()

    Loop L1 + 1 {
        i := A_Index - 1
        dist.Push(Array())
        Loop L2 + 1 {
            j := A_Index - 1
            dist[i + 1].Push(i = 0 ? j : (j = 0 ? i : 0))
        }
    }

    Loop L1 {
        i := A_Index
        Loop L2 {
            j := A_Index
            cost := (SubStr(s1, i, 1) = SubStr(s2, j, 1) ? 0 : 1)
            dist[i + 1][j + 1] := Min(dist[i][j + 1] + 1, dist[i + 1][j] + 1, dist[i][j] + cost)
        }
    }

    return 1 - (dist[L1 + 1][L2 + 1] / maxLen)
}

_httt_log(msg) {
    logDir := A_ScriptDir . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\haitacthongthai.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    FileAppend("[" . timestamp . "] " . msg . "`n", logPath, "UTF-8")
}
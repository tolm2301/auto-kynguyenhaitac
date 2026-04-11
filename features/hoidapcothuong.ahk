_feature_hoidapcothuong() {
    global isRunning, g_featureText

    _hoidap_reset_log()

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
    snapshotText := _hoidap_read_quiz_snapshot(hwnd)
    parsed := _hoidap_parse_quiz_snapshot(snapshotText)

    questionText := parsed.question
    if (questionText = "")
        questionText := _hoidap_read_question(hwnd)
    questionText := _hoidap_clean_question_text(questionText)
    if (Trim(questionText) = "") {
        _hoidap_log("OCR câu hỏi rỗng")
        return
    }

    bestMatch := FindBestFuzzyMatchAcrossIni(iniPath, questionText, 0.4)
    if (bestMatch.Score <= 0) {
        _hoidap_log("Không tìm thấy câu hỏi đủ match (>=0.4) | OCR Q: " . questionText)
        return
    }

    _hoidap_log("Q match | score=" . Format("{:.3f}", bestMatch.Score) . " | section=" . bestMatch.Section . " | Q=" . bestMatch.Question . " | A=" . bestMatch.Answer)

    optionMap := _hoidap_read_option_map(hwnd)
    for letter in ["A", "B", "C"] {
        if (Trim(optionMap[letter]) = "" && parsed.options.Has(letter) && Trim(parsed.options[letter]) != "")
            optionMap[letter] := parsed.options[letter]
    }
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
    return _ocr_from_bit_map(hwnd, 250, 146, 930, 190)
}

_hoidap_read_quiz_snapshot(hwnd) {
    return _ocr_from_bit_map(hwnd, 250, 146, 930, 292)
}

_hoidap_parse_quiz_snapshot(text) {
    src := StrReplace(text, "`r", "")
    src := RegExReplace(src, "\s+", " ")
    result := {question: "", options: Map("A", "", "B", "", "C", "")}

    if RegExMatch(src, "i)cau\s*hoi\s*[:\-]?\s*(.+?)(?=\bA\s*[:\-\.)])", &mq)
        result.question := Trim(mq[1])
    if RegExMatch(src, "i)\bA\s*[:\-\.)]\s*(.+?)(?=\bB\s*[:\-\.)])", &mA)
        result.options["A"] := Trim(mA[1])
    if RegExMatch(src, "i)\bB\s*[:\-\.)]\s*(.+?)(?=\bC\s*[:\-\.)])", &mB)
        result.options["B"] := Trim(mB[1])
    if RegExMatch(src, "i)\bC\s*[:\-\.)]\s*(.+?)(?=\bXac\s*dinh|$)", &mC)
        result.options["C"] := Trim(mC[1])

    _hoidap_log("OCR snapshot | " . src)
    return result
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
    fallbackLetter := _extract_answer_letter(answerText)
    if (expected = "")
        return {letter: "", score: 0.0, expected: expected}

    bestLetter := ""
    bestScore := -1.0
    secondScore := -1.0
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
            secondScore := bestScore
            bestScore := score
            bestLetter := letter
        } else if (score > secondScore) {
            secondScore := score
        }
    }

    gap := bestScore - secondScore
    _hoidap_log("Answer score | expected=" . expected . " | " . Trim(detail) . "| best=" . Format("{:.3f}", bestScore) . " second=" . Format("{:.3f}", secondScore) . " gap=" . Format("{:.3f}", gap) . " pick=" . bestLetter)

    if !hasAnyOptionText {
        if (fallbackLetter != "") {
            _hoidap_log("Answer OCR rong, fallback theo INI letter=" . fallbackLetter)
            return {letter: fallbackLetter, score: 0.0, expected: expected}
        }
    }

    if (bestLetter = "")
        return {letter: "", score: 0.0, expected: expected}

    if (bestScore < 0.40) {
        if (fallbackLetter != "") {
            _hoidap_log("Do tin cay thap, fallback theo INI letter=" . fallbackLetter)
            return {letter: fallbackLetter, score: bestScore, expected: expected}
        }
        _hoidap_log("Do tin cay thap, bo qua cau hoi")
        return {letter: "", score: bestScore, expected: expected}
    }

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
    numA := _hoidap_extract_number_token(expectedNorm)
    numB := _hoidap_extract_number_token(candidateNorm)
    if (numA != "" || numB != "") {
        if (numA = numB && numA != "")
            return 1.0
        return 0.1
    }

    if (expectedNorm = candidateNorm)
        return 1.0

    if InStr(candidateNorm, expectedNorm) || InStr(expectedNorm, candidateNorm) {
        minLen := Min(StrLen(expectedNorm), StrLen(candidateNorm))
        maxLen := Max(StrLen(expectedNorm), StrLen(candidateNorm))
        return 0.9 + (minLen / maxLen) * 0.1
    }

    return StrDiff(expectedNorm, candidateNorm)
}

_hoidap_extract_number_token(text) {
    if RegExMatch(text, "(\d+(?:[\.,]\d+)?)", &m)
        return StrReplace(m[1], ",", ".")
    return ""
}

_hoidap_clean_question_text(text) {
    q := Trim(text)
    q := RegExReplace(q, "(?i)thoi\s*gian\s*tra\s*loi\s*con.*$", "")
    q := RegExReplace(q, "\s+", " ")
    return Trim(q)
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

_hoidap_reset_log() {
    logDir := A_ScriptDir . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\hoidap.log"
    try FileDelete(logPath)
}

FindFuzzyMatch(IniPath, Section, SearchStr, Threshold := 0.6) {
    BestScore := 0
    MatchedQ := ""
    MatchedA := ""

    searchNorm := _normalize_question_for_match(SearchStr)
    if (searchNorm = "")
        return {Score: 0}
    searchCompact := StrReplace(searchNorm, " ", "")

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
        fileNorm := _normalize_question_for_match(FileQ)
        fileCompact := StrReplace(fileNorm, " ", "")
        charScore := StrDiff(searchCompact, fileCompact)
        tokenScore := _question_token_overlap_score(searchNorm, fileNorm)
        CurrentScore := Max(charScore, tokenScore, (charScore * 0.65 + tokenScore * 0.35))

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

FindBestFuzzyMatchAcrossIni(IniPath, SearchStr, Threshold := 0.4) {
    BestScore := 0
    MatchedQ := ""
    MatchedA := ""
    MatchedSection := ""
    bestTie := -1
    candidates := []

    searchNorm := _normalize_question_for_match(SearchStr)
    if (searchNorm = "")
        return {Score: 0}
    searchCompact := StrReplace(searchNorm, " ", "")

    if !FileExist(IniPath)
        return {Score: 0}

    currentSection := ""
    loop read IniPath {
        row := Trim(A_LoopReadLine)
        if (row = "")
            continue

        if RegExMatch(row, "^\[(.+)\]$", &mSec) {
            currentSection := Trim(mSec[1])
            continue
        }

        pos := InStr(row, "=")
        if !pos
            continue

        fileQ := Trim(SubStr(row, 1, pos - 1))
        fileA := Trim(SubStr(row, pos + 1))
        if (fileQ = "" || fileA = "")
            continue

        fileNorm := _normalize_question_for_match(fileQ)
        fileCompact := StrReplace(fileNorm, " ", "")
        charScore := StrDiff(searchCompact, fileCompact)
        tokenScore := _question_token_overlap_score(searchNorm, fileNorm)
        blendScore := (charScore * 0.65 + tokenScore * 0.35)
        currentScore := Max(charScore, tokenScore, blendScore)
        tieBreaker := (tokenScore * 0.001) + (charScore * 0.0001)

        if (currentScore >= Threshold) {
            _hoidap_insert_candidate_sorted(candidates, {
                score: currentScore,
                token: tokenScore,
                char: charScore,
                blend: blendScore,
                tie: tieBreaker,
                section: currentSection,
                question: fileQ
            })
        }

        if (currentScore > BestScore || (Abs(currentScore - BestScore) < 0.000001 && tieBreaker > ((MatchedQ = "") ? -1 : bestTie))) {
            BestScore := currentScore
            MatchedQ := fileQ
            MatchedA := fileA
            MatchedSection := currentSection
            bestTie := tieBreaker
        }
    }

    _hoidap_log_threshold_candidates(candidates, Threshold)

    if (BestScore < Threshold)
        return {Score: 0}

    return {Score: BestScore, Question: MatchedQ, Answer: MatchedA, Section: MatchedSection}
}

_hoidap_insert_candidate_sorted(candidates, candidate) {
    if (candidates.Length = 0) {
        candidates.Push(candidate)
        return
    }

    inserted := false
    loop candidates.Length {
        idx := A_Index
        if (candidate.score > candidates[idx].score || (Abs(candidate.score - candidates[idx].score) < 0.000001 && candidate.tie > candidates[idx].tie)) {
            candidates.InsertAt(idx, candidate)
            inserted := true
            break
        }
    }

    if !inserted
        candidates.Push(candidate)
}

_hoidap_log_threshold_candidates(candidates, threshold) {
    if (candidates.Length = 0) {
        _hoidap_log("Threshold candidates | >= " . threshold . " | none")
        return
    }

    _hoidap_log("Threshold candidates | >= " . threshold . " | count=" . candidates.Length)
    for item in candidates {
        _hoidap_log("Candidate | score=" . Format("{:.6f}", item.score) . " | token=" . Format("{:.6f}", item.token) . " | char=" . Format("{:.6f}", item.char) . " | blend=" . Format("{:.6f}", item.blend) . " | tie=" . Format("{:.6f}", item.tie) . " | section=" . item.section . " | Q=" . item.question)
    }
}

_normalize_question_for_match(text) {
    t := StrLower(Trim(text))
    t := RegExReplace(t, "(?i)thoi\s*gian\s*tra\s*loi\s*con.*$", "")

    ; Sửa nhanh vài lỗi OCR phổ biến kiểu Mon/M6n, ghetlä, ...
    t := RegExReplace(t, "(?<=[a-z])[06](?=[a-z])", "o")
    t := RegExReplace(t, "(?<=[a-z])1(?=[a-z])", "i")
    t := RegExReplace(t, "(?<=[a-z])5(?=[a-z])", "s")
    t := RegExReplace(t, "(?<=[a-z])4(?=[a-z])", "a")

    t := RegExReplace(t, "[^a-z0-9]+", " ")
    t := RegExReplace(t, "\s+", " ")
    return Trim(t)
}

_question_token_overlap_score(a, b) {
    aa := _split_tokens_for_match(a)
    bb := _split_tokens_for_match(b)
    if (aa.Length = 0 || bb.Length = 0)
        return 0

    hit := 0
    for token in aa {
        if _array_has_token(bb, token)
            hit += 1
    }
    return hit / aa.Length
}

_split_tokens_for_match(text) {
    tokens := []
    if (text = "")
        return tokens

    ; Tách theo nhóm chữ/số để không phụ thuộc khoảng trắng OCR
    i := 1
    while (i <= StrLen(text)) {
        if RegExMatch(SubStr(text, i), "^[a-z0-9]{3,}", &m) {
            tokens.Push(m[0])
            i += StrLen(m[0])
        } else {
            i += 1
        }
    }
    return tokens
}

_array_has_token(arr, token) {
    for v in arr {
        if (v = token)
            return true
        if InStr(v, token) || InStr(token, v)
            return true
    }
    return false
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

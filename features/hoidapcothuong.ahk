; Cache vocabulary cho OCR post-processing
global _hoidap_vocab_cache := Map()
global _hoidap_vocab_loaded := false
global _hoidap_fuzzy_retry_cache := Map()

_feature_hoidapcothuong() {
    global isRunning, g_featureText, g_ocr_debug_mode

    _hoidap_reset_log()
    _hoidap_load_vocab_cache()
    g_ocr_debug_mode := false

    _win_resize_list()
    hwnds := _win_get_list()
    if (hwnds.Length = 0)
        return

    isRunning := true
    g_featureText.Text := "Tính năng đang chạy: Hỏi đáp có thưởng"

    try {
        hwnd := hwnds[1]
        _hoidap_auto_answer(hwnd)
    } finally {
        _feature_reset_running_status()
    }
}

_hoidap_auto_answer(hwnd) {
    global _hoidap_vocab_cache

    iniPath := A_ScriptDir . "\resources\Question.ini"
    ; OCR retry theo scale tăng dần: 2.0 -> 2.25 -> 2.5
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

    if (Trim(questionText) = "") {
        _hoidap_log("OCR câu hỏi rỗng")
        return
    }

    _hoidap_log("OCR question retry done | scale=" . usedScale . " | text=" . questionText)

    questionMapped := questionText
    if (_hoidap_vocab_cache.Has("questionTokens"))
        questionMapped := _hoidap_map_ocr_to_vocab(questionText, _hoidap_vocab_cache["questionTokens"], _hoidap_vocab_cache["questionFixCache"])

    _hoidap_log("OCR question | raw=" . questionText . " | mapped=" . questionMapped)

    bestMatch := _hoidap_find_best_with_retry(iniPath, questionMapped, questionText, 0.6)
    if (bestMatch.Score <= 0) {
        _hoidap_log("Không tìm thấy câu hỏi đủ match | mapped=" . questionMapped . " | raw=" . questionText)
        return
    }

    ; Kiểm tra question đạt ngưỡng tối thiểu 0.3
    if (bestMatch.Score < 0.3) {
        _hoidap_log("Question score thấp: " . Format("{:.3f}", bestMatch.Score))
        return
    }

    _hoidap_log("Q match | score=" . Format("{:.3f}", bestMatch.Score) . " | section=" . bestMatch.Section . " | Q=" . bestMatch.Question . " | A=" . bestMatch.Answer)

    optionMap := _hoidap_read_option_map(hwnd)
    _hoidap_log("OCR options raw | A=[" . (optionMap.Has("A") ? optionMap["A"] : "") . "] | B=[" . (optionMap.Has("B") ? optionMap["B"] : "") . "] | C=[" . (optionMap.Has("C") ? optionMap["C"] : "") . "]")
    _hoidap_log_game_options(optionMap)
    answerResult := _hoidap_find_best_answer_for_options(optionMap, bestMatch.Answer)
    if (answerResult.letter = "" || answerResult.score < 0.3) {
        _hoidap_log("Answer match thap | letter=" . answerResult.letter . " score=" . Format("{:.3f}", answerResult.score))
        return
    }
    _hoidap_log("Answer matched | letter=" . answerResult.letter . " score=" . Format("{:.3f}", answerResult.score) . " answer=" . answerResult.matchedAnswer)
    answerLetter := answerResult.letter

    if (answerLetter = "") {
        _hoidap_log("Không xác định được đáp án A/B/C | OCR Q: " . questionText)
        return
    }

    if _click_hoidap_answer(hwnd, answerLetter)
        _hoidap_log("Đã trả lời " . answerLetter . " | Answer score: " . Format("{:.3f}", answerResult.score) . " | matched=" . answerResult.matchedAnswer)
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
        optionMap[letter] := _hoidap_read_option_text_with_retry(hwnd, opt.ocrX1, opt.ocrY1, opt.ocrX2, opt.ocrY2)
    }
    return optionMap
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

_hoidap_find_best_answer_for_options(optionMap, bestMatchAnswer) {
    global _hoidap_vocab_cache

    expectedRaw := _extract_answer_value(bestMatchAnswer)
    expectedNorm := _normalize_qa_text(expectedRaw)
    if (expectedNorm = "")
        return {letter: "", score: 0.0, matchedAnswer: "", matchedOcrText: ""}

    bestOption := ""
    bestScore := 0.0
    bestRawScore := 0.0
    bestMappedScore := 0.0
    bestMatchedAnswer := ""
    bestMatchedOcrText := ""

    ; Thử với các ngưỡng: 0.8 -> 0.7 -> 0.6 -> 0.5 -> 0.4 -> 0.3
    thresholdLevels := [0.8, 0.7, 0.6, 0.5, 0.4, 0.3]
    ; Ưu tiên tie-break khi vẫn bằng điểm: C > B > A
    letterPriority := Map("A", 1, "B", 2, "C", 3)

    for _, minThreshold in thresholdLevels {
        for letter in ["A", "B", "C"] {
            if !optionMap.Has(letter)
                continue

            ocrText := optionMap[letter]
            ocrParsed := _extract_option_value_from_ocr(ocrText, letter)
            ocrNorm := _normalize_qa_text(ocrParsed)
            if (ocrNorm = "")
                continue

            ; 1) Score theo OCR nguyên bản (trước map)
            rawScore := _hoidap_similarity(expectedNorm, ocrNorm)

            ; 2) Map OCR text qua vocab answer để fix lỗi OCR
            mappedNorm := ocrNorm
            if (_hoidap_vocab_cache.Has("answerTokens"))
                mappedNorm := _hoidap_map_ocr_to_vocab(ocrNorm, _hoidap_vocab_cache["answerTokens"], _hoidap_vocab_cache["answerFixCache"])

            ; 3) Score sau map
            mappedScore := _hoidap_similarity(expectedNorm, mappedNorm)

            ; Điểm chính vẫn là điểm cao hơn giữa raw/mapped
            score := Max(rawScore, mappedScore)

            ; Tiebreak theo yêu cầu:
            ; - ưu tiên rawScore cao hơn
            ; - nếu rawScore bằng, ưu tiên mappedScore cao hơn
            ; - nếu vẫn bằng, ưu tiên C > B > A
            isBetter := false
            if (score > bestScore) {
                isBetter := true
            } else if (score = bestScore) {
                if (rawScore > bestRawScore) {
                    isBetter := true
                } else if (rawScore = bestRawScore) {
                    if (mappedScore > bestMappedScore) {
                        isBetter := true
                    } else if (mappedScore = bestMappedScore) {
                        if (bestOption = "" || letterPriority[letter] > letterPriority[bestOption])
                            isBetter := true
                    }
                }
            }

            if (score >= minThreshold && isBetter) {
                bestScore := score
                bestRawScore := rawScore
                bestMappedScore := mappedScore
                bestOption := letter
                bestMatchedAnswer := ocrParsed
                bestMatchedOcrText := ocrParsed
            }
        }

        if (bestScore >= minThreshold)
            break
    }

    return {
        letter: bestOption,
        score: bestScore,
        matchedAnswer: bestMatchedAnswer,
        matchedOcrText: bestMatchedOcrText
    }
}

_click_hoidap_answer(hwnd, answerLetter) {
    cfg := _hoidap_get_option_config()
    confirm := _hoidap_get_confirm_button_config()
    if !cfg.Has(answerLetter)
        return false

    _click_post(hwnd, cfg[answerLetter].clickX, cfg[answerLetter].clickY)
    Sleep 500
    _click_post(hwnd, confirm.x, confirm.y)
    Sleep 500
    return true
}

_extract_answer_value(answerText) {
    text := Trim(answerText)
    if RegExMatch(text, "^[ABCabc]\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])
    return text
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
    _log_append(logPath, "[" . timestamp . "] " . msg . "`n", "UTF-8")
}

_hoidap_reset_log() {
    logDir := A_ScriptDir . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\hoidap.log"
    try FileDelete(logPath)
}

FindFuzzyMatch(IniPath, Section, SearchStr, Threshold := 0.8) {
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

FindBestFuzzyMatchAcrossIni(IniPath, SearchStr, Threshold := 0.8) {
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

    if (BestScore < Threshold)
        return {Score: 0}

    return {Score: BestScore, Question: MatchedQ, Answer: MatchedA, Section: MatchedSection}
}

_hoidap_find_best_with_retry(iniPath, mappedText, rawText, threshold) {
    global _hoidap_fuzzy_retry_cache

    cacheKey := _normalize_question_for_match(mappedText) . "|" . _normalize_question_for_match(rawText) . "|" . threshold

    if (_hoidap_fuzzy_retry_cache.Has(cacheKey))
        return _hoidap_fuzzy_retry_cache[cacheKey]

    ; Thử với nhiều ngưỡng: 0.8 -> 0.7 -> 0.6 -> 0.5 -> 0.4 -> 0.3
    thresholdLevels := [0.8, 0.7, 0.6, 0.5, 0.4, 0.3]

    final := {Score: 0}

    for _, currentThreshold in thresholdLevels {
        if (Trim(mappedText) != "") {
            result := _hoidap_fuzzy_match_cached(mappedText, currentThreshold)
            if (result.Score > 0) {
                _hoidap_fuzzy_retry_cache[cacheKey] := result
                return result
            }
        }

        if (Trim(rawText) != "") {
            result := _hoidap_fuzzy_match_cached(rawText, currentThreshold)
            if (result.Score > 0) {
                _hoidap_fuzzy_retry_cache[cacheKey] := result
                return result
            }
        }
    }

    _hoidap_fuzzy_retry_cache[cacheKey] := final
    return final
}

_hoidap_load_vocab_cache() {
    global _hoidap_vocab_loaded, _hoidap_vocab_cache

    if (_hoidap_vocab_loaded)
        return
    _hoidap_vocab_loaded := true

    iniPath := A_ScriptDir . "\resources\Question.ini"
    if !FileExist(iniPath)
        return

    questionTokens := Map()
    answerTokens := Map()
    iniEntries := []

    try {
        allData := IniRead(iniPath, "Questions")
    } catch {
        return
    }

    Loop Parse, allData, "`n", "`r" {
        if (A_LoopField = "")
            continue

        parsed := _hoidap_parse_qa_line(A_LoopField)
        if !parsed.ok
            continue

        questionPart := parsed.question
        answerPart := parsed.answer
        qNorm := _normalize_question_for_match(questionPart)

        for token in _split_tokens_for_match(qNorm)
            questionTokens[token] := true

        for token in _hoidap_tokenize_answer_for_vocab(answerPart)
            answerTokens[token] := true

        iniEntries.Push({q: questionPart, qNorm: qNorm, qCompact: StrReplace(qNorm, " ", ""), a: answerPart})
    }

    _hoidap_vocab_cache["questionTokens"] := questionTokens
    _hoidap_vocab_cache["answerTokens"] := answerTokens
    _hoidap_vocab_cache["iniEntries"] := iniEntries
    _hoidap_vocab_cache["questionFixCache"] := Map()
    _hoidap_vocab_cache["answerFixCache"] := Map()

    _hoidap_log("Vocab cache loaded | questionTokens=" . questionTokens.Count . " | answerTokens=" . answerTokens.Count . " | iniEntries=" . iniEntries.Length)
}

_hoidap_fuzzy_match_cached(searchStr, threshold) {
    global _hoidap_vocab_cache

    if !_hoidap_vocab_cache.Has("iniEntries")
        return {Score: 0}

    entries := _hoidap_vocab_cache["iniEntries"]
    if !entries || entries.Length = 0
        return {Score: 0}

    searchNorm := _normalize_question_for_match(searchStr)
    if (searchNorm = "")
        return {Score: 0}

    searchCompact := StrReplace(searchNorm, " ", "")
    searchTokens := _split_tokens_for_match(searchNorm)
    if (searchTokens.Length = 0)
        return {Score: 0}

    bestScore := 0
    bestQ := ""
    bestA := ""

    searchTokenSet := Map()
    for token in searchTokens
        searchTokenSet[token] := true

    for entry in entries {
        commonCount := 0
        entryTokens := _split_tokens_for_match(entry.qNorm)
        for token in entryTokens {
            if searchTokenSet.Has(token)
                commonCount++
        }

        if (commonCount < 2)
            continue

        charScore := StrDiff(searchCompact, entry.qCompact)
        tokenScore := _question_token_overlap_score(searchNorm, entry.qNorm)
        blendScore := (charScore * 0.65 + tokenScore * 0.35)
        score := Max(charScore, tokenScore, blendScore)

        if (score > bestScore) {
            bestScore := score
            bestQ := entry.q
            bestA := entry.a
        }

        if (score >= 0.95)
            break
    }

    if (bestScore >= threshold)
        return {Score: bestScore, Question: bestQ, Answer: bestA, Section: _hoidap_get_section()}

    return {Score: 0}
}

_hoidap_parse_qa_line(line) {
    row := Trim(line)
    if (row = "")
        return {ok: false, question: "", answer: ""}

    eqPos := InStr(row, "=")
    if (eqPos) {
        q := Trim(SubStr(row, 1, eqPos - 1))
        a := Trim(SubStr(row, eqPos + 1))
        if (q != "" && a != "")
            return {ok: true, question: q, answer: a}
    }

    ; Fallback cho format kiểu: question: answer
    if RegExMatch(row, "^(.*?):\s*(.+)$", &m) {
        q := Trim(m[1])
        a := Trim(m[2])
        if (q != "" && a != "")
            return {ok: true, question: q, answer: a}
    }

    return {ok: false, question: "", answer: ""}
}

_hoidap_tokenize_answer_for_vocab(answerText) {
    tokens := []
    t := StrLower(Trim(answerText))
    if (t = "")
        return tokens

    ; Bỏ prefix A/B/C nếu có trong answer
    t := RegExReplace(t, "^[abc]\s*[:\-\.)]\s*", "")

    ; Đồng bộ sửa lỗi OCR phổ biến
    t := RegExReplace(t, "(?<=[a-z])[06](?=[a-z])", "o")
    t := RegExReplace(t, "(?<=[a-z])1(?=[a-z])", "i")
    t := RegExReplace(t, "(?<=[a-z])5(?=[a-z])", "s")
    t := RegExReplace(t, "(?<=[a-z])4(?=[a-z])", "a")

    ; Tokenize trực tiếp từ raw answer, không cắt trước ký tự đặc biệt
    i := 1
    while (i <= StrLen(t)) {
        if RegExMatch(SubStr(t, i), "^[a-z0-9]{3,}", &m) {
            tokens.Push(m[0])
            i += StrLen(m[0])
        } else {
            i += 1
        }
    }

    return tokens
}

_hoidap_map_ocr_to_vocab(ocrText, vocabSet, tokenFixCache := "") {
    if (Trim(ocrText) = "")
        return ""

    normText := _normalize_question_for_match(ocrText)
    tokens := _split_tokens_for_match(normText)
    if (tokens.Length = 0)
        return normText

    result := ""
    for token in tokens {
        mappedToken := token

        if (IsObject(vocabSet) && vocabSet.Has(token)) {
            mappedToken := token
        } else if (IsObject(tokenFixCache) && tokenFixCache.Has(token)) {
            mappedToken := tokenFixCache[token]
        } else {
            bestMatch := ""
            bestScore := 0.0
            tokenLen := StrLen(token)

            if IsObject(vocabSet) {
                for vocabToken, _ in vocabSet {
                    if (Abs(StrLen(vocabToken) - tokenLen) > 2)
                        continue
                    if (SubStr(vocabToken, 1, 1) != SubStr(token, 1, 1))
                        continue

                    score := StrDiff(token, vocabToken)
                    if (score > bestScore && score >= 0.8) {
                        bestScore := score
                        bestMatch := vocabToken
                    }
                }
            }

            if (bestMatch != "")
                mappedToken := bestMatch

            if IsObject(tokenFixCache)
                tokenFixCache[token] := mappedToken
        }

        if (result != "")
            result .= " "
        result .= mappedToken
    }

    return Trim(result)
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

    bbSet := Map()
    for token in bb
        bbSet[token] := true

    hit := 0
    for token in aa {
        if (bbSet.Has(token) || _array_has_token(bb, token))
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

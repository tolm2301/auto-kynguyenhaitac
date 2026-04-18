global _httt_vocab_cache := Map()
global _httt_vocab_loaded := false

_feature_haitacthongthai() {
    global isRunning, g_featureText, _httt_vocab_cache

    _httt_reset_log()
    _httt_load_vocab_cache()

    _win_resize_list()
    hwnds := _win_get_list()
    if (hwnds.Length = 0)
        return

    isRunning := true
    g_featureText.Text := "Tính năng đang chạy: Hải tặc thông thái"

    try {
        iniPath := A_ScriptDir . "\resources\Question.ini"
        section := "Haitacthongthai"

        hwnd := hwnds[1]

        scaleLevels := [2.0, 2.25, 2.5]
        questionText := ""
        for idx, scl in scaleLevels {
            questionText := _ocr_from_bit_map(hwnd, 294, 190, 977, 340, 0, scl)
            questionText := _httt_clean_question_text(questionText)
            if (Trim(questionText) != "")
                break
        }

        if (Trim(questionText) = "") {
            _httt_log("OCR câu hỏi rỗng")
            return
        }

        questionMapped := questionText
        if (_httt_vocab_cache.Has("questionTokens"))
            questionMapped := _httt_map_ocr_to_vocab(questionText, _httt_vocab_cache["questionTokens"], _httt_vocab_cache["questionFixCache"])

        _httt_log("OCR question | raw=" . questionText . " | mapped=" . questionMapped)

        bestMatch := _httt_find_best_with_retry(iniPath, section, questionMapped, questionText, 0.8)
        if (bestMatch.Score <= 0) {
            _httt_log("Không tìm thấy câu hỏi đủ match | mapped=" . questionMapped . " | raw=" . questionText)
            return
        }

        if (bestMatch.Score < 0.3) {
            _httt_log("Question score thấp: " . Format("{:.3f}", bestMatch.Score))
            return
        }

        _httt_log("Q match | score=" . Format("{:.3f}", bestMatch.Score) . " | Q=" . bestMatch.Question . " | A=" . bestMatch.Answer)

        for hwndElement in hwnds {
            if !isRunning
                return

            optionMap := _httt_read_option_map(hwndElement, bestMatch.Answer)
            answerResult := _httt_find_best_answer_for_options(optionMap, bestMatch.Answer)
            if (answerResult.letter = "" || answerResult.score < 0.3) {
                _httt_log("Answer match thap | letter=" . answerResult.letter . " score=" . Format("{:.3f}", answerResult.score))
                continue
            }
            _httt_log("Answer matched | letter=" . answerResult.letter . " score=" . Format("{:.3f}", answerResult.score))

            if _httt_click_answer(hwndElement, answerResult.letter)
                _httt_log("Đã trả lời " . answerResult.letter . " | score=" . Format("{:.3f}", answerResult.score))
        }
    } finally {
        _feature_reset_running_status()
    }
}

_httt_read_question(hwnd) {
    return _ocr_from_bit_map(hwnd, 294, 190, 977, 340)
}

_httt_load_vocab_cache() {
    global _httt_vocab_cache, _httt_vocab_loaded

    if (_httt_vocab_loaded)
        return
    _httt_vocab_loaded := true

    iniPath := A_ScriptDir . "\resources\Question.ini"
    questionTokens := Map()
    answerTokens := Map()

    try {
        allData := IniRead(iniPath, "Haitacthongthai")
        Loop Parse, allData, "`n", "`r" {
            if (A_LoopField = "")
                continue
            pos := InStr(A_LoopField, "=")
            if (!pos)
                continue
            questionPart := Trim(SubStr(A_LoopField, 1, pos - 1))
            answerPart := Trim(SubStr(A_LoopField, pos + 1))
            for token in _httt_split_tokens_for_match(_httt_normalize_question_for_match(questionPart))
                questionTokens[token] := true
            for token in _httt_split_tokens_for_match(_httt_normalize(answerPart))
                answerTokens[token] := true
        }
    }

    _httt_vocab_cache["questionTokens"] := questionTokens
    _httt_vocab_cache["answerTokens"] := answerTokens
    _httt_vocab_cache["questionFixCache"] := Map()
    _httt_vocab_cache["answerFixCache"] := Map()
}

_httt_get_option_config() {
    static cfg := Map(
        "A", { ocrX1: 290, ocrY1: 352, ocrX2: 974, ocrY2: 403, clickX: 318, clickY: 377 },
        "B", { ocrX1: 290, ocrY1: 405, ocrX2: 974, ocrY2: 457, clickX: 318, clickY: 430 },
        "C", { ocrX1: 290, ocrY1: 460, ocrX2: 974, ocrY2: 509, clickX: 318, clickY: 486 },
        "D", { ocrX1: 290, ocrY1: 516, ocrX2: 974, ocrY2: 559, clickX: 318, clickY: 534 }
    )
    return cfg
}

_httt_get_confirm_button_config() {
    return { x: 907, y: 584 }
}

_httt_read_option_map(hwnd, bestMatchAnswer := "") {
    cfg := _httt_get_option_config()
    optionMap := Map()

    for letter in ["A", "B", "C", "D"] {
        opt := cfg[letter]
        optionMap[letter] := _ocr_from_bit_map(hwnd, opt.ocrX1, opt.ocrY1, opt.ocrX2, opt.ocrY2, 0, 2.5)
    }

    _httt_log("OCR options | A=[" . optionMap["A"] . "] B=[" . optionMap["B"] . "] C=[" . optionMap["C"] . "]" . "] D=[" . optionMap["D"] . "]")
    return optionMap
}

_httt_find_best_with_retry(iniPath, section, mappedText, rawText, threshold) {
    thresholdLevels := [0.8, 0.7, 0.6, 0.5, 0.4, 0.3]

    for _, currentThreshold in thresholdLevels {
        result := _httt_fuzzy_match(iniPath, section, mappedText, currentThreshold)
        if (result.Score > 0)
            return result

        if (Trim(rawText) != "") {
            result := _httt_fuzzy_match(iniPath, section, rawText, currentThreshold)
            if (result.Score > 0)
                return result
        }
    }

    return {Score: 0}
}

_httt_fuzzy_match(iniPath, section, searchStr, threshold) {
    bestScore := 0
    matchedQ := ""
    matchedA := ""

    searchNorm := _httt_normalize_question_for_match(searchStr)
    if (searchNorm = "")
        return {Score: 0}
    searchCompact := StrReplace(searchNorm, " ", "")

    try {
        allData := IniRead(iniPath, section)
    } catch {
        return {Score: 0}
    }

    Loop Parse, allData, "`n", "`r" {
        if (A_LoopField = "")
            continue

        pos := InStr(A_LoopField, "=")
        if (!pos)
            continue

        fileQ := SubStr(A_LoopField, 1, pos - 1)
        fileA := SubStr(A_LoopField, pos + 1)
        fileNorm := _httt_normalize_question_for_match(fileQ)
        fileCompact := StrReplace(fileNorm, " ", "")
        charScore := _httt_str_diff(searchCompact, fileCompact)
        tokenScore := _httt_question_token_overlap_score(searchNorm, fileNorm)
        blendScore := (charScore * 0.65 + tokenScore * 0.35)
        currentScore := Max(charScore, tokenScore, blendScore)

        if (currentScore >= threshold && currentScore > bestScore) {
            bestScore := currentScore
            matchedQ := fileQ
            matchedA := fileA
        }
    }

    if (bestScore >= threshold)
        return {Score: bestScore, Question: matchedQ, Answer: matchedA}
    return {Score: 0}
}

_httt_find_best_answer_for_options(optionMap, bestMatchAnswer) {
    global _httt_vocab_cache

    expectedNorm := _httt_normalize(_httt_extract_answer_value(bestMatchAnswer))
    if (expectedNorm = "")
        return {letter: "", score: 0.0}

    bestOption := ""
    bestScore := 0.0
    bestMatchedAnswer := bestMatchAnswer
    thresholdLevels := [0.8, 0.7, 0.6, 0.5, 0.4, 0.3]
    letterPriority := {A: 3, B: 2, C: 1, D: 0}

    for _, minThreshold in thresholdLevels {
        for letter in ["A", "B", "C", "D"] {
            if !optionMap.Has(letter)
                continue

            ocrText := optionMap[letter]
            ocrParsed := _httt_extract_option_value(ocrText, letter)
            ocrNorm := _httt_normalize(ocrParsed)
            if (ocrNorm = "")
                continue

            if (_httt_vocab_cache.Has("answerTokens"))
                ocrNorm := _httt_map_ocr_to_vocab(ocrNorm, _httt_vocab_cache["answerTokens"], _httt_vocab_cache["answerFixCache"])

            rawScore := _httt_similarity_v2(expectedNorm, ocrNorm)
            mappedScore := _httt_similarity_v2(expectedNorm, ocrNorm)
            score := Max(rawScore, mappedScore)

            if (score >= minThreshold) {
                if (score > bestScore) || (score = bestScore && letterPriority[letter] < letterPriority[bestOption]) {
                    bestScore := score
                    bestOption := letter
                    bestMatchedAnswer := ocrParsed
                }
            }
        }

        if (bestScore >= minThreshold)
            break
    }

    return {letter: bestOption, score: bestScore, matchedAnswer: bestMatchedAnswer}
}

_httt_pick_answer(answerText, optionMap) {
    expected := _httt_normalize(_httt_extract_answer_value(answerText))
    bestLetter := ""
    bestScore := -1.0
    secondScore := -1.0
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
            secondScore := bestScore
            bestScore := score
            bestLetter := letter
        } else if (score > secondScore) {
            secondScore := score
        }
    }

    gap := bestScore - secondScore
    _httt_log("Answer score | expected=" . expected . " | " . Trim(scoreLog) . "| best=" . Format("{:.3f}", bestScore) . " second=" . Format("{:.3f}", secondScore) . " gap=" . Format("{:.3f}", gap) . " pick=" . bestLetter)

    if (bestLetter = "")
        return { letter: "", score: bestScore }

    if (bestScore < 0.40) {
        _httt_log("Do tin cay thap (HTTT random ABCD), bo qua cau hoi")
        MsgBox("Độ tin cậy thấp, không auto click.`nĐáp án data: " . answerText, "HTTT - Cần xử lý tay")
        return { letter: "", score: bestScore }
    }

    return { letter: bestLetter, score: bestScore }
}

_httt_click_answer(hwnd, answerLetter) {
    cfg := _httt_get_option_config()
    confirm := _httt_get_confirm_button_config()
    if !cfg.Has(answerLetter)
        return false

    _click_post(hwnd, cfg[answerLetter].clickX, cfg[answerLetter].clickY)
    Sleep 500
    _click_post(hwnd, confirm.x, confirm.y)
    Sleep 500
    return true
}

_httt_extract_answer_value(answerText) {
    text := Trim(answerText)
    if RegExMatch(text, "^[ABCDabcd]\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])
    return text
}

_httt_extract_option_value(optionText, letter) {
    text := Trim(StrReplace(optionText, "`r", ""))
    if RegExMatch(text, "^" . letter . "\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])
    if RegExMatch(text, "^[ABCDabcd]\s*[:\-\.)]\s*(.+)$", &m)
        return Trim(m[1])
    return text
}

_httt_normalize(text) {
    value := StrLower(Trim(text))
    value := RegExReplace(value, "^[abcd]\s*[:\-\.)]\s*", "")
    value := RegExReplace(value, "[^a-z0-9]+", "")
    return value
}

_httt_similarity(a, b) {
    numA := _httt_extract_number_token(a)
    numB := _httt_extract_number_token(b)
    if (numA != "" || numB != "") {
        if (numA = numB && numA != "")
            return 1.0
        return 0.1
    }

    if (a = b)
        return 1.0
    return _httt_str_diff(a, b)
}

_httt_similarity_v2(expectedNorm, candidateNorm) {
    numA := _httt_extract_number_token(expectedNorm)
    numB := _httt_extract_number_token(candidateNorm)
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

    return _httt_str_diff(expectedNorm, candidateNorm)
}

_httt_extract_number_token(text) {
    if RegExMatch(text, "(\d+(?:[\.,]\d+)?)", &m)
        return StrReplace(m[1], ",", ".")
    return ""
}

_httt_clean_question_text(text) {
    q := Trim(text)
    q := RegExReplace(q, "(?i)thoi\s*gian\s*tra\s*loi\s*con.*$", "")
    q := RegExReplace(q, "\s+", " ")
    return Trim(q)
}

_httt_find_fuzzy_match(iniPath, section, searchStr, threshold := 0.6) {
    bestScore := 0
    bestTie := -1
    matchedQ := ""
    matchedA := ""
    candidates := []

    searchNorm := _httt_normalize_question_for_match(searchStr)
    if (searchNorm = "")
        return { Score: 0 }
    searchCompact := StrReplace(searchNorm, " ", "")

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
        fileNorm := _httt_normalize_question_for_match(fileQ)
        fileCompact := StrReplace(fileNorm, " ", "")
        charScore := _httt_str_diff(searchCompact, fileCompact)
        tokenScore := _httt_question_token_overlap_score(searchNorm, fileNorm)
        blendScore := (charScore * 0.65 + tokenScore * 0.35)
        currentScore := Max(charScore, tokenScore, blendScore)
        tieBreaker := (tokenScore * 0.001) + (charScore * 0.0001)

        if (currentScore >= threshold) {
            _httt_insert_candidate_sorted(candidates, {
                score: currentScore,
                token: tokenScore,
                char: charScore,
                blend: blendScore,
                tie: tieBreaker,
                question: fileQ
            })
        }

        if (currentScore > bestScore || (Abs(currentScore - bestScore) < 0.000001 && tieBreaker > bestTie)) {
            bestScore := currentScore
            bestTie := tieBreaker
            matchedQ := fileQ
            matchedA := fileA
        }
    }

    _httt_log_threshold_candidates(candidates, threshold)

    if (bestScore >= threshold)
        return { Score: bestScore, Question: matchedQ, Answer: matchedA }

    return { Score: 0 }
}

_httt_insert_candidate_sorted(candidates, candidate) {
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

_httt_log_threshold_candidates(candidates, threshold) {
    if (candidates.Length = 0) {
        _httt_log("Threshold candidates | >= " . threshold . " | none")
        return
    }

    _httt_log("Threshold candidates | >= " . threshold . " | count=" . candidates.Length)
    for item in candidates {
        _httt_log("Candidate | score=" . Format("{:.6f}", item.score) . " | token=" . Format("{:.6f}", item.token) . " | char=" . Format("{:.6f}", item.char) . " | blend=" . Format("{:.6f}", item.blend) . " | tie=" . Format("{:.6f}", item.tie) . " | Q=" . item.question)
    }
}

_httt_normalize_question_for_match(text) {
    t := StrLower(Trim(text))
    t := RegExReplace(t, "(?i)thoi\s*gian\s*tra\s*loi\s*con.*$", "")
    t := RegExReplace(t, "[^a-z0-9]+", " ")
    t := RegExReplace(t, "\s+", " ")
    return Trim(t)
}

_httt_question_token_overlap_score(a, b) {
    aa := _httt_split_tokens_for_match(a)
    bb := _httt_split_tokens_for_match(b)
    if (aa.Length = 0 || bb.Length = 0)
        return 0

    hit := 0
    for token in aa {
        if _httt_array_has_token(bb, token)
            hit += 1
    }
    return hit / aa.Length
}

_httt_split_tokens_for_match(text) {
    tokens := []
    if (text = "")
        return tokens

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

_httt_map_ocr_to_vocab(ocrText, vocabSet, tokenFixCache := "") {
    if (Trim(ocrText) = "")
        return ""

    normText := _httt_normalize_question_for_match(ocrText)
    tokens := _httt_split_tokens_for_match(normText)
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

                    score := _httt_str_diff(token, vocabToken)
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
    return result
}

_httt_array_has_token(arr, token) {
    for v in arr {
        if (v = token)
            return true
        if InStr(v, token) || InStr(token, v)
            return true
    }
    return false
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
    _log_append(logPath, "[" . timestamp . "] " . msg . "`n", "UTF-8")
}

_httt_reset_log() {
    logDir := A_ScriptDir . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\haitacthongthai.log"
    try FileDelete(logPath)
}

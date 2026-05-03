
; variable
global httt_question_pos := [294, 190, 977, 296]
global default_threshhold := 0.6

_feature_haitacthongthai() {
    global isRunning, g_featureText

    _httt_reset_log()

    _win_resize_list()
    isRunning := true
    g_featureText.Text := "Tính năng đang chạy: Hải tặc thông thái"

    try {
        _httt_run_round()
    } finally {
        _feature_reset_running_status()
    }
}

_feature_haitacthongthai_session(event, roundCount := 10) {
    global isRunning, g_featureText

    _httt_reset_log()
    _win_resize_list()

    if !IsObject(event)
        throw Error("Thiếu base time cho HTTT session")

    startHour := Integer(event.hour)
    startMinute := Integer(event.minute)
    baseTime := _httt_build_session_base_time(startHour, startMinute)

    isRunning := true
    g_featureText.Text := "Tính năng đang chạy: Hải tặc thông thái (" . roundCount . " câu)"

    try {
        _httt_log("Session start | base=" . Format("{:02}:{:02}:02", startHour, startMinute) . " | rounds=" . roundCount)

        Loop roundCount {
            if !isRunning
                throw Error("HTTT session stopped")

            roundIndex := A_Index
            targetTime := DateAdd(baseTime, (roundIndex - 1) * 30, "Seconds")
            _httt_wait_until(targetTime)

            if !isRunning
                throw Error("HTTT session stopped")

            _httt_safe_round_offset()
            _httt_log("Round " . roundIndex . "/" . roundCount . " | target=" . FormatTime(targetTime, "HH:mm:ss") . " | now=" . FormatTime(A_Now, "HH:mm:ss"))
            _httt_run_round(roundIndex, roundCount)

            if !isRunning
                throw Error("HTTT session stopped")
        }
    } finally {
        _feature_reset_running_status()
    }
}

_httt_run_round(roundIndex := 1, roundCount := 1) {
    global httt_question_pos, isRunning

    hwnds := _httt_get_hwnds()
    if (hwnds.Length = 0)
        return false

    baseDir := _httt_get_base_dir()
    iniPath := baseDir . "\resources\Question.ini"
    if !FileExist(iniPath) {
        _httt_log("Thiếu Question.ini: " . iniPath)
        return false
    }

    questionHwnd := hwnds[1]
    questionText := _httt_read_question(questionHwnd)
    questionText := _httt_clean_question_text(questionText)

    _httt_log("OCR question | round=" . roundIndex . "/" . roundCount . " | hwnd=" . questionHwnd . " | text=" . questionText)

    if (Trim(questionText) = "") {
        _httt_log("OCR câu hỏi rỗng | round=" . roundIndex)
        return false
    }

    bestMatch := FindBestFuzzyMatchAcrossIni(iniPath, questionText, "Haitacthongthai")
    if (bestMatch.Score < 0.3) {
        _httt_log("Question score thấp | round=" . roundIndex . " | score=" . Format("{:.3f}", bestMatch.Score))
        return false
    }

    _httt_log("Q match | round=" . roundIndex . " | score=" . Format("{:.3f}", bestMatch.Score) . " | Q=" . bestMatch.Question . " | A=" . bestMatch.Answer)

    workerPids := _httt_start_workers(hwnds, bestMatch.Answer)
    if (workerPids.Length = 0) {
        _httt_log("Không spawn được worker | round=" . roundIndex)
        return false
    }

    _httt_wait_workers(workerPids)

    if !isRunning
        return false

    return true
}

_feature_haitacthongthai_worker_entry(hwnd, answerText) {
    global g_featureText

    _httt_log("Worker start | hwnd=" . hwnd . " | answer=" . answerText)

    try {
        optionMap := _httt_read_option_map(hwnd)
        answerResult := _httt_find_best_answer_for_options(optionMap, answerText, false)
        if (answerResult.letter = "" || answerResult.score < 0.3) {
            _httt_log("Worker answer match thấp | hwnd=" . hwnd . " | letter=" . answerResult.letter . " | score=" . Format("{:.3f}", answerResult.score))
            return
        }

        _httt_log("Worker answer matched | hwnd=" . hwnd . " | letter=" . answerResult.letter . " | score=" . Format("{:.3f}", answerResult.score))

        if _httt_click_answer(hwnd, answerResult.letter)
            _httt_log("Worker đã trả lời | hwnd=" . hwnd . " | letter=" . answerResult.letter)
    } catch as err {
        _httt_log("Worker fail | hwnd=" . hwnd . " | err=" . err.Message)
    } finally {
        _feature_reset_running_status()
    }
}

_httt_start_workers(hwnds, answerText) {
    pids := []
    for hwnd in hwnds {
        pid := _httt_start_worker(hwnd, answerText)
        if (pid > 0) {
            pids.Push(pid)
            _httt_log("Spawn worker | hwnd=" . hwnd . " | pid=" . pid)
        } else {
            _httt_log("Spawn worker failed | hwnd=" . hwnd)
        }
    }
    return pids
}

_httt_get_hwnds() {
    return _win_get_list()
}

_httt_build_session_base_time(startHour, startMinute) {
    return FormatTime(A_Now, "yyyyMMdd") . Format("{:02}{:02}02", Integer(startHour), Integer(startMinute))
}

_httt_wait_until(targetTime) {
    global isRunning

    while isRunning {
        nowStamp := FormatTime(A_Now, "yyyyMMddHHmmss")
        if (nowStamp >= targetTime)
            break

        remainingSec := DateDiff(targetTime, A_Now, "Seconds")
        if (remainingSec <= 0)
            Sleep 100
        else
            Sleep Min(remainingSec * 1000, 250)
    }
}

_httt_safe_round_offset() {
    sec := Integer(FormatTime(A_Now, "ss"))
    if (Mod(sec, 30) = 0)
        Sleep 500
}

_httt_start_worker(hwnd, answerText) {
    pid := 0
    baseDir := _httt_get_base_dir()

    if A_IsCompiled {
        workerExe := _httt_resolve_worker_exe()
        if (workerExe != "") {
            runCommand := Format('"{1}" "{2}" "{3}" "{4}"', workerExe, hwnd, answerText)
            try Run(runCommand, baseDir, "Hide", &pid)
            return pid
        }

        runCommand := Format('"{1}" "{2}" "{3}" "{4}"', A_ScriptFullPath, hwnd, answerText)
        try Run(runCommand, baseDir, "Hide", &pid)
        return pid
    }

    workerScript := baseDir . "\features\haitacthongthai_worker.ahk"
    if !FileExist(workerScript)
        return 0

    runCommand := Format('"{1}" "{2}" "{3}" "{4}"', A_AhkPath, workerScript, hwnd, answerText)
    try Run(runCommand, baseDir, "Hide", &pid)
    return pid
}

_httt_resolve_worker_exe() {
    baseDir := _httt_get_base_dir()
    candidates := []
    candidates.Push(baseDir . "\haitacthongthai_worker.exe")
    candidates.Push(baseDir . "\features\haitacthongthai_worker.exe")

    for candidate in candidates {
        if FileExist(candidate)
            return candidate
    }

    return ""
}

_httt_wait_workers(pids) {
    global isRunning

    while _httt_has_alive_workers(pids) {
        if !isRunning {
            _httt_stop_worker_processes(pids)
            break
        }

        Sleep 500
    }
}

_httt_has_alive_workers(pids) {
    for pid in pids {
        if ProcessExist(pid)
            return true
    }

    return false
}

_httt_stop_worker_processes(pids) {
    for pid in pids {
        if ProcessExist(pid) {
            try ProcessClose(pid)
        }
    }
}

_httt_get_base_dir() {
    if DirExist(A_ScriptDir . "\resources")
        return A_ScriptDir

    if DirExist(A_ScriptDir . "\..\resources")
        return A_ScriptDir . "\.."

    return A_WorkingDir
}

_httt_read_question(hwnd) {
    return _ocr_from_bit_map(hwnd, httt_question_pos[1], httt_question_pos[2], httt_question_pos[3], httt_question_pos[4])
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
        optionMap[letter] := _ocr_from_bit_map(hwnd, opt.ocrX1, opt.ocrY1, opt.ocrX2, opt.ocrY2, 0, 1.8)
    }

    _httt_log("OCR options | A=[" . optionMap["A"] . "] B=[" . optionMap["B"] . "] C=[" . optionMap["C"] . "]" . "] D=[" . optionMap["D"] . "]")
    return optionMap
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

_httt_find_best_answer_for_options(optionMap, bestMatchAnswer, showWarning := true) {
    expectedRaw := _httt_extract_answer_value(bestMatchAnswer)
    expectedNorm := _httt_normalize(expectedRaw)
    if (expectedNorm = "")
        return { letter: "", score: 0.0, matchedAnswer: "", matchedOcrText: "" }

    bestOption := ""
    bestScore := 0.0
    bestMatchedAnswer := ""
    bestMatchedOcrText := ""
    
    for letter in ["A", "B", "C"] {
            if !optionMap.Has(letter)
                continue

            ocrText := optionMap[letter]
            ocrParsed := _httt_extract_option_value(ocrText, letter)
            ocrNorm := _httt_normalize(ocrParsed)
            if (ocrNorm = "")
                continue

            rawScore := _httt_similarity_v2(expectedNorm, ocrNorm)

            if (rawScore >= default_threshhold && rawScore > bestScore) {
                bestScore := rawScore
                bestOption := letter
                bestMatchedAnswer := ocrParsed
                bestMatchedOcrText := ocrParsed
            }
        }

    return {
        letter: bestOption,
        score: bestScore,
        matchedAnswer: bestMatchedAnswer,
        matchedOcrText: bestMatchedOcrText
    }
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

_httt_find_fuzzy_match(iniPath, section, searchStr, threshold := default_threshhold) {
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
    logDir := _httt_get_base_dir() . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\haitacthongthai.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    _log_append(logPath, "[" . timestamp . "] " . msg . "`n", "UTF-8")
}

_httt_reset_log() {
    logDir := _httt_get_base_dir() . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\haitacthongthai.log"
    try FileDelete(logPath)
}

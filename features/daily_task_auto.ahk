#Requires AutoHotkey v2.0

; =========================
; DAILY TASK AUTO - NVHN
; =========================

; tinh nang
global featureButton := [925, 35]
global dailyTabButton := [624, 125]
global acceptQuest := [654, 523]
global completedQuest := [615, 508]
global completedQuest2 := [680, 498]
global completedQuest3 := [624, 500]
global completedQuest4 := [652, 487]
global dragToClick := [724, 494, 674, 495]

global isMsgBox := false
global isMsgBox1 := false

global questTaskMap := [{ quest: "timkiem", task: "hoanthanhthaotactimkiemdaquydaquycothelamtangsucmanhcobancuatrangbi" }, { quest: "tangtocddoi", task: "tienhanhtangtocddoicuabancothetangcapchodoidoi" }, { quest: "tancongdoiquan", task: "tancongnpctrongpbandanhbainpcnhanctichvatrangbi" }, { quest: "cuonghoatrangbi", task: "chonchoatrangbitronggiaodienchoacuonghoasetangkhanangcosocuatrangbi" }, { quest: "thachthuctrendautruong", task: "haythachdauvoinhungnguoichoikhactrendautruongdechungminhthucluccuaban" }, { quest: "tayluyen", task: "thongquatayluyentbihoacbauvatcothegiuptbihoacbauvatnhanduochoacthaydoicac" }, { quest: "dungvang", task: "tieuvangmotcachthongminhcothesenhanduochieuquacapsonhan" }, { quest: "rakhoi", task: "hoanthanhthaotacrakhoitronggiaodiencuatauchinhkhirakhoicothenhanduocphanthuongberi" }, { quest: "nauan", task: "nauanbanmonannhanberiberi" }
]

global noticeText := "datontainvpchatcaophuhopvoimuctieucotieptuclammoiko"

; Quest
global quest1 := [438, 198, 441, 211, 559, 255]
global quest1Retry1 := [438, 198, 480, 239, 570, 268]
global quest1Retry2 := [438, 198, 476, 242, 528, 264]
global quest1Retry3 := [438, 198, 485, 244, 634, 269]
global quest2 := [389, 261, 402, 280, 516, 326]
global quest2Retry1 := [389, 261, 431, 307, 527, 327]
global quest2Retry2 := [389, 261, 431, 307, 527, 327]
global quest2Retry3 := [389, 261, 431, 307, 527, 327]
global quest3 := [485, 264, 491, 276, 648, 334]
global quest3Retry1 := [485, 264, 522, 303, 570, 268]
global quest3Retry2 := [485, 264, 527, 304, 638, 341]
global quest3Retry3 := [485, 264, 521, 297, 653, 349]
global questRegions := [quest1, quest2, quest3]
global questRegionsRetries1 := [quest1Retry1, quest2Retry1, quest3Retry1]
global questRegionsRetries2 := [quest1Retry2, quest2Retry2, quest3Retry2]
global questRegionsRetries3 := [quest1Retry3, quest2Retry3, quest3Retry3]

global retriesRegion := [479, 244, 626, 272]

; refresh
global refresh := [670, 392, 513, 315, 753, 347]

; Task
global task1 := [379, 400, 378, 436, 657, 487]
global task2 := [438, 400, 378, 436, 657, 487]
global task3 := [493, 400, 378, 436, 657, 487]
global task4 := [548, 400, 378, 436, 657, 487]
global task5 := [606, 400, 378, 436, 657, 487]
global taskRegions := [task1, task2, task3, task4, task5]

; checkpoint
global checkPoint := [364, 495, 431, 513]

; Sleep
global SLEEP_SHORT := 1000
global SLEEP_LONG := 5000

_feature_daily_task_auto() {
    global isRunning, g_featureText

    _win_resize_list()
    hwnds := _win_get_list()
    if (hwnds.Length = 0)
        return

    hwnd := hwnds[1]
    isRunning := true
    g_featureText.Text := "Tính năng đang chạy: NV hàng ngày"

    _feature_daily_task_auto_single(hwnd)
}

_feature_daily_task_auto_single(hwnd) {
    global g_featureText, isRunning

    _click_post(hwnd, featureButton[1], featureButton[2])
    Sleep SLEEP_SHORT
    _click_post(hwnd, dailyTabButton[1], dailyTabButton[2])
    Sleep SLEEP_SHORT

    isRunning := true

    while true {
        if (!isRunning) {
            g_featureText.Text := "Tính năng đang chạy: Chưa có"
            return
        }

        remainText := _ocr_nhiem_vu_con_lai(hwnd)
        Sleep SLEEP_SHORT

        ; done
        if (remainText = "0/10") {
            _click_post(hwnd, 847, 523)
            Sleep SLEEP_SHORT
            _post_with_vk_string(hwnd, "ESC")
            Sleep SLEEP_SHORT
            g_featureText.Text := "Tính năng đang chạy: NV hàng ngày"
            break
        }

        ; 1/10: chỉ cần bất kỳ task nào có 0/3
        if (remainText = "1/10") {
            if (_refresh_until_notice_ready(hwnd) != "OK") {
                Sleep 1000
                continue
            }

            if (_find_and_accept_any_zero_point_task(hwnd) = "OK") {
                _click_post(hwnd, acceptQuest[1], acceptQuest[2], 500)
                Sleep SLEEP_SHORT
                _click_post(hwnd, completedQuest[1], completedQuest[2], 500)
                Sleep 500
                _click_post(hwnd, completedQuest2[1], completedQuest2[2], 500)
                Sleep 500
                _click_post(hwnd, completedQuest3[1], completedQuest3[2], 500)
                Sleep 500
                _click_post(hwnd, completedQuest4[1], completedQuest4[2], 500)
                Sleep SLEEP_SHORT
            }
            continue
        }

        questCount := _get_quest_count_by_remain(remainText)
        if (questCount = 0) {
            Sleep 1000
            continue
        }

        matchedQuests := _collect_matched_quests(hwnd, questCount)
        if (matchedQuests.Length = 0) {
            Sleep 1000
            continue
        }

        pendingTasks := _build_pending_tasks_from_quests(matchedQuests)
        if (pendingTasks.Length = 0) {
            Sleep 1000
            continue
        }

        if isMsgBox
            MsgBox pendingTasks.Length

        successCount := _find_and_accept_tasks_from_list(hwnd, pendingTasks)

        Sleep (successCount = 0 ? SLEEP_LONG : SLEEP_SHORT)
    }
}

_get_quest_count_by_remain(remainText) {
    switch remainText {
        case "10/10":
            return 1
        case "9/10":
            return 2
        case "7/10", "4/10", "1/10":
            return 3
        case "0/10":
            return 0
        default:
            return 0
    }
}

_collect_matched_quests(hwnd, questCount) {
    global questRegions, questRegionsRetries1, questRegionsRetries2, questRegionsRetries3, questTaskMap

    results := []

    Loop questCount {
        idx := A_Index
        region := questRegions[idx]
        retryRegion := questRegionsRetries1[idx]
        retryRegion2 := questRegionsRetries2[idx]
        retryRegion3 := questRegionsRetries3[idx]

        
        bestMatch := _find_best_match_score(hwnd, region, retryRegion, retryRegion2, retryRegion3)

        if (bestMatch.Score = 0) {
            bestMatch := _find_best_match_score(hwnd, region, retryRegion, retryRegion2, retryRegion3, 1.7)
        }

        if (bestMatch.Score = 0) {
            bestMatch := _find_best_match_score(hwnd, region, retryRegion, retryRegion2, retryRegion3, 1.5)
        }

        if (bestMatch.Score = 0) {
            bestMatch := _find_best_match_score(hwnd, region, retryRegion, retryRegion2, retryRegion3, 2.3)
        }

        if (bestMatch.Score = 0) {
            bestMatch := _find_best_match_score(hwnd, region, retryRegion, retryRegion2, retryRegion3, 2.5)
        }

        Sleep SLEEP_SHORT

        if (bestMatch.Score > 0) {
            results.Push(bestMatch)
        }
    }

    return results
}


_find_best_match_score(hwnd, region, retryRegion, retryRegion2, retryRegion3, scale := 2) {
    bestMatch := { Score: 0, Quest: "", Task: "" }

    ; lần 1: OCR vùng chính
    questOCRText := _read_quest_text(hwnd, region)
    if isMsgBox
        MsgBox questOCRText

    if (questOCRText != "") {
        match1 := FindBestQuestTaskSupportNVHN(questTaskMap, questOCRText, 0.8)
        if (match1.Score > bestMatch.Score)
            bestMatch := match1
    }

    Sleep SLEEP_SHORT

    ; lần 2: OCR vùng retry riêng của quest
    if (retryRegion.Length >= 4 and bestMatch.Score = 0) {
        retryText := _read_quest_text_retry(hwnd, retryRegion, scale)

        if isMsgBox
            MsgBox retryText

        if (retryText != "") {
            match2 := FindBestQuestTaskSupportNVHN(questTaskMap, retryText, 0.8)
            if (match2.Score > bestMatch.Score)
                bestMatch := match2
        }
    }

    Sleep SLEEP_SHORT

    ; lần 3: OCR vùng retry riêng của quest
    if (retryRegion2.Length >= 4 and bestMatch.Score = 0) {
        retryText := _read_quest_text_retry(hwnd, retryRegion2, scale)

        if isMsgBox
            MsgBox retryText

        if (retryText != "") {
            match3 := FindBestQuestTaskSupportNVHN(questTaskMap, retryText, 0.8)
            if (match3.Score > bestMatch.Score)
                bestMatch := match3
        }
    }

    Sleep SLEEP_SHORT

    ; lần 3: OCR vùng retry riêng của quest
    if (retryRegion3.Length >= 4 and bestMatch.Score = 0) {
        retryText := _read_quest_text_retry(hwnd, retryRegion3, scale)

        if isMsgBox
            MsgBox retryText

        if (retryText != "") {
            match3 := FindBestQuestTaskSupportNVHN(questTaskMap, retryText, 0.8)
            if (match3.Score > bestMatch.Score)
                bestMatch := match3
        }
    }

    return bestMatch
}

_read_quest_text_retry(hwnd, retryRegion, scale := 2) {
    _click_post(hwnd, retryRegion[1], retryRegion[2])
    Sleep SLEEP_SHORT

    result := _ocr_from_bit_map(hwnd, retryRegion[3], retryRegion[4], retryRegion[5], retryRegion[6], 0, scale)

    result := _normalize_qa_text_support_nvhn(result)
    return result
}

_build_pending_tasks_from_quests(matchedQuests) {
    pendingTasks := []

    for _, questMatch in matchedQuests {
        if (questMatch.Task = "")
            continue

        pendingTasks.Push(questMatch.Task)
    }

    return pendingTasks
}

_read_quest_text(hwnd, questRegion) {
    global retriesRegion

    ; click quest trước rồi OCR
    _click_post(hwnd, questRegion[1], questRegion[2])
    Sleep SLEEP_SHORT

    result := _ocr_from_bit_map(hwnd, questRegion[3], questRegion[4], questRegion[5], questRegion[6])
    result := _normalize_qa_text_support_nvhn(result)

    if (result = "") {
        result := _ocr_from_bit_map(hwnd, retriesRegion[1], retriesRegion[2], retriesRegion[3], retriesRegion[4])
        result := _normalize_qa_text_support_nvhn(result)
    }

    return result
}

_refresh_until_notice_ready(hwnd) {
    global noticeText, refresh, SLEEP_SHORT

    Loop 20 {
        refreshText := _ocr_refresh(hwnd)

        if (StringSupportFindingScoreAndReturnBoolean(noticeText, refreshText) = "OK") {
            Sleep SLEEP_SHORT
            _post_with_vk_string(hwnd, "ESC")
            Sleep SLEEP_SHORT
            return "OK"
        }

        _click_post(hwnd, refresh[1], refresh[2])
        Sleep 1000
    }

    return "FAILED"
}

_find_and_accept_tasks_from_list(hwnd, pendingTasks) {
    global taskRegions, acceptQuest, completedQuest, SLEEP_SHORT

    successCount := 0

    while pendingTasks.length > 0 {
        if (_refresh_until_notice_ready(hwnd) != "OK") {
            Sleep 1000
            continue
        }

        ; scan đúng 5 task slot
        for _, taskRegion in taskRegions {
            matchedIndex := _ocr_check_is_quest_needed(hwnd, taskRegion, pendingTasks)

            if (matchedIndex > 0) {
                _click_post(hwnd, acceptQuest[1], acceptQuest[2])
                Sleep SLEEP_SHORT

                _click_post(hwnd, completedQuest[1], completedQuest[2])
                Sleep SLEEP_SHORT

                pendingTasks.RemoveAt(matchedIndex)
                break
            }
        }
    }

    return successCount
}

_find_and_accept_any_zero_point_task(hwnd) {
    global taskRegions

    for _, taskRegion in taskRegions {
        ; click task slot
        _click_post(hwnd, taskRegion[1], taskRegion[2])
        Sleep SLEEP_SHORT

        ; click vùng chi tiết
        _click_post(hwnd, 785, 143)
        Sleep SLEEP_SHORT

        if (_ocr_check_point(hwnd) = "OK")
            return "OK"
    }

    return "FAILED"
}

_ocr_nhiem_vu_con_lai(hwnd) {
    result := _ocr_from_bit_map(hwnd, 361, 338, 470, 378)

    if InStr(result, "10/10") or InStr(result, "10110")
        return "10/10"

    if InStr(result, "9/10") or InStr(result, "9110")
        return "9/10"

    if InStr(result, "7/10") or InStr(result, "7110")
        return "7/10"

    if InStr(result, "4/10") or InStr(result, "4110")
        return "4/10"

    if InStr(result, "1/10") or InStr(result, "1110")
        return "1/10"

    if InStr(result, "0/10")
        return "0/10"

    return result
}

_normalize_ocr_ratio_text(text) {
    value := StrLower(Trim(text))
    value := RegExReplace(value, "\s+", "")
    value := StrReplace(value, "o", "0")
    value := StrReplace(value, "l", "1")
    value := StrReplace(value, "i", "1")
    value := StrReplace(value, "\", "/")
    value := StrReplace(value, "|", "/")
    return value
}

_ocr_refresh(hwnd) {
    global refresh
    return _normalize_qa_text_support_nvhn(_ocr_from_bit_map(hwnd, refresh[3], refresh[4], refresh[5], refresh[6]))
}

_normalize_qa_text_support_nvhn(text) {
    value := StrLower(Trim(text))
    value := RegExReplace(value, "^[abc]\s*[:\-\.)]\s*", "")
    value := RegExReplace(value, "[^a-z0-9]+", "")
    return value
}

FindBestQuestTaskSupportNVHN(arrData, searchStr, threshold := 0.8) {
    bestScore := 0
    bestQuest := ""
    bestTask := ""

    searchNorm := _normalize_qa_text_support_nvhn(searchStr)
    if (searchNorm = "")
        return { Score: 0, Quest: "", Task: "" }

    for _, item in arrData {
        if !item.HasOwnProp("quest") || !item.HasOwnProp("task")
            continue

        questNorm := _normalize_qa_text_support_nvhn(item.quest)
        if (questNorm = "")
            continue

        score := StrDiff(searchNorm, questNorm)

        if (score > bestScore) {
            bestScore := score
            bestQuest := item.quest
            bestTask := item.task
        }
    }

    if (bestScore >= threshold) {
        return {
            Score: bestScore,
            Quest: bestQuest,
            Task: bestTask
        }
    }

    return {
        Score: 0,
        Quest: "",
        Task: ""
    }
}

StringSupportFindingScoreAndReturnBoolean(mainChar, charFinding, threshold := 0.8) {
    mainNorm := _normalize_qa_text_support_nvhn(mainChar)
    findNorm := _normalize_qa_text_support_nvhn(charFinding)

    if (mainNorm = "" || findNorm = "")
        return "FAILED"

    score := StrDiff(findNorm, mainNorm)

    if (score >= threshold)
        return "OK"

    return "FAILED"
}

_ocr_check_point(hwnd) {
    result := _ocr_from_bit_map(hwnd, checkPoint[1], checkPoint[2], checkPoint[3], checkPoint[4], 0, 2)

    if (result = "013" || result = "0/3" || InStr(result, "013") || InStr(result, "0/3"))
        return "OK"

    result := _ocr_from_bit_map(hwnd, checkPoint[1], checkPoint[2], checkPoint[3], checkPoint[4], 0, 1.8)

    if (result = "013" || result = "0/3" || InStr(result, "013") || InStr(result, "0/3"))
        return "OK"

    result := _ocr_from_bit_map(hwnd, checkPoint[1], checkPoint[2], checkPoint[3], checkPoint[4], 0, 1.7)

    if (result = "013" || result = "0/3" || InStr(result, "013") || InStr(result, "0/3"))
        return "OK"

    result := _ocr_from_bit_map(hwnd, checkPoint[1], checkPoint[2], checkPoint[3], checkPoint[4], 0, 1.6)

    if (result = "013" || result = "0/3" || InStr(result, "013") || InStr(result, "0/3"))
        return "OK"

    result := _ocr_from_bit_map(hwnd, checkPoint[1], checkPoint[2], checkPoint[3], checkPoint[4], 0, 1.5)

    if (result = "013" || result = "0/3" || InStr(result, "013") || InStr(result, "0/3"))
        return "OK"

    result := _ocr_from_bit_map(hwnd, checkPoint[1], checkPoint[2], checkPoint[3], checkPoint[4], 0, 1.4)

    if (result = "013" || result = "0/3" || InStr(result, "013") || InStr(result, "0/3"))
        return "OK"

    return "FAILED"
}

_normalize_ocr_point_text(text) {
    value := StrLower(Trim(text))
    value := RegExReplace(value, "\s+", "")
    value := StrReplace(value, "o", "0")
    value := StrReplace(value, "l", "1")
    value := StrReplace(value, "i", "1")
    value := StrReplace(value, "\", "/")
    value := StrReplace(value, "|", "/")
    return value
}

; trả về:
; > 0 = index của task match trong pendingTasks
; 0   = không match
_ocr_check_is_quest_needed(hwnd, taskArr, pendingTasks) {
    ; click task slot
    _click_post(hwnd, taskArr[1], taskArr[2])
    Sleep SLEEP_SHORT

    ; click vùng chi tiết
    _click_post(hwnd, 785, 143)
    Sleep SLEEP_SHORT

    ; phải có point 0/3 mới xét
    if (_ocr_check_point(hwnd) != "OK")
        return 0

    result := _normalize_qa_text_support_nvhn(_ocr_from_bit_map(hwnd, taskArr[3], taskArr[4], taskArr[5], taskArr[6]))

    if (result = "")
        return 0

    for idx, taskTarget in pendingTasks {
        if isMsgBox1
            Msgbox taskTarget
        
        if (taskTarget = "")
            continue

        if (StringSupportFindingScoreAndReturnBoolean(taskTarget, result, 0.8) = "OK")
            return idx
    }

    return 0
}
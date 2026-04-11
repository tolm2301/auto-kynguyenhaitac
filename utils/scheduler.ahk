g_activitySchedulerEnabled := false
g_activitySchedulerBusy := false
g_activityExecutedMap := Map()

_get_weekday_from_ahk() {
    currentDay := Mod(A_WDay, 7)
    if (currentDay = 0)
        currentDay := 7
    return currentDay
}

_start_activity_scheduler() {
    global g_activitySchedulerEnabled
    if g_activitySchedulerEnabled
        return

    g_activitySchedulerEnabled := true
    SetTimer(_activity_scheduler_tick, 15000)
    _activity_scheduler_tick()
}

_activity_scheduler_tick() {
    global g_activitySchedulerBusy
    if g_activitySchedulerBusy
        return

    g_activitySchedulerBusy := true
    try {
        event := _scheduler_get_due_event()
        if IsObject(event)
            _scheduler_execute_event(event)
    } catch as err {
        _scheduler_log("Scheduler error: " . err.Message)
    } finally {
        g_activitySchedulerBusy := false
    }
}

_scheduler_get_due_event() {
    global g_activityExecutedMap

    iniPath := A_ScriptDir . "\resources\events.ini"
    if !FileExist(iniPath)
        return ""

    currentDay := _get_weekday_from_ahk()
    nowMinutes := Integer(A_Hour) * 60 + Integer(A_Min)
    dueEvent := ""
    dueMinutes := -1

    loop read iniPath {
        line := Trim(A_LoopReadLine)
        if (line = "" or SubStr(line, 1, 1) = "[" or InStr(line, "=") = 0)
            continue

        parts := StrSplit(line, "=")
        eventName := Trim(parts[1])
        if !_scheduler_is_supported_event(eventName)
            continue

        eventParts := StrSplit(Trim(parts[2]), "|")
        if (eventParts.Length < 2)
            continue

        dayParts := StrSplit(Trim(eventParts[1]), ",")
        isToday := false
        for day in dayParts {
            if Integer(Trim(day)) = currentDay {
                isToday := true
                break
            }
        }
        if !isToday
            continue

        timeParts := StrSplit(Trim(eventParts[2]), ":")
        if (timeParts.Length < 2)
            continue

        eventHour := Integer(Trim(timeParts[1]))
        eventMinute := Integer(Trim(timeParts[2]))
        eventTotalMinutes := eventHour * 60 + eventMinute
        if (eventTotalMinutes > nowMinutes)
            continue

        runKey := FormatTime(A_Now, "yyyyMMdd") . "|" . eventName . "|" . Format("{:02}:{:02}", eventHour, eventMinute)
        if g_activityExecutedMap.Has(runKey)
            continue

        if (eventTotalMinutes > dueMinutes) {
            dueMinutes := eventTotalMinutes
            dueEvent := {
                name: eventName,
                hour: eventHour,
                minute: eventMinute,
                runKey: runKey
            }
        }
    }

    return dueEvent
}

_scheduler_execute_event(event) {
    global g_activityExecutedMap, g_featureText

    g_activityExecutedMap[event.runKey] := "running"
    g_featureText.Text := "Tính năng đang chạy (auto): " . event.name
    _scheduler_log("Auto run: " . event.name . " at " . Format("{:02}:{:02}", event.hour, event.minute))

    try {
        _scheduler_run_event(event.name)
        g_activityExecutedMap[event.runKey] := "done"
        _scheduler_log("Completed: " . event.name)
    } catch as err {
        g_activityExecutedMap[event.runKey] := "failed"
        _scheduler_log("Failed: " . event.name . " - " . err.Message)
    }
}

_scheduler_run_event(eventName) {
    global g_inputCount

    count := Integer(g_inputCount.Value)
    if (count <= 0)
        count := 1

    switch eventName {
        case "Rồng Punk":
            _feature_punk()
        case "Kraken":
            _feature_kraken()
        case "Kaido":
            _feature_kaido()
        case "Daily":
            _feature_daily()
        case "Tầm bảo chiến":
            _feature_tam_bao_chien()
        case "Cường Hoá":
            _feature_enhance(count)
        case "Ra Khơi":
            _feature_rakhoi(count)
        case "Năm Mới Phát Tài":
            _feature_nammoiphattai(count)
        case "Ảnh hồn":
            _feature_anhhon(count)
        case "Tấn công hải quân":
            _feature_tanconghaiquan()
        case "Hỏi đáp có thưởng":
            _feature_hoidapcothuong()
        default:
            throw Error("Event chưa được map feature: " . eventName)
    }
}

_scheduler_is_supported_event(eventName) {
    static supported := Map(
        "Rồng Punk", true,
        "Kraken", true,
        "Kaido", true,
        "Daily", true,
        "Tầm bảo chiến", true,
        "Cường Hoá", true,
        "Ra Khơi", true,
        "Năm Mới Phát Tài", true,
        "Ảnh hồn", true,
        "Tấn công hải quân", true,
        "Hỏi đáp có thưởng", true
    )

    return supported.Has(eventName)
}

_scheduler_log(msg) {
    logDir := A_ScriptDir . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\scheduler.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    FileAppend("[" . timestamp . "] " . msg . "`n", logPath, "UTF-8")
}

isRunning := false
g_nextEventText := ""
g_eventTimerEnabled := false

_gui_init() {
    global g_inputCount, isRunning, g_featureText, g_nextEventText, g_nextEventControl

    myGui := Gui("", "Auto VHT")

    myGui.Icon := A_ScriptDir . "\resources\icon.ico"
    myGui.AddText("x10 y10 w200 h30", "Nhập số lượt:")
    g_inputCount := myGui.AddEdit("w50 h30 vInputCount x100 y10", "1")
    g_featureText := myGui.AddText("x10 y75 w220 h30", "Tính năng đang chạy: Chưa có")

    myTab := myGui.AddTab("x10 y105 w210 h310", ["Main", "Boss", "Phụ trợ"])

    g_nextEventControl := myGui.AddText("x10 y420 w260 h30", "")
    _update_event_text()

    ; Main Tab
    myTab.UseTab(1)
    btnDaily := myGui.AddButton("w200 h30 x10 y130", "Daily")
    btnTBC := myGui.AddButton("w200 h30 x10 y165", "Tầm bảo chiến")
    btnHaiTacThongThai := myGui.AddButton("w200 h30 x10 y200", "Hải tặc thông thái")

    ; Boss Tab (auto by scheduler)
    myTab.UseTab(2)
    myGui.AddText("x15 y135 w190 h20", "Boss chạy tự động theo giờ")
    myGui.AddText("x15 y160 w190 h40", "Sửa thời gian trong resources/events.ini")

    ; Support tab
    myTab.UseTab(3)
    btnEnhance := myGui.AddButton("w200 h30 x10 y130", "Cường Hoá")
    btnRaKhoi := myGui.AddButton("w200 h30 x10 y165", "Ra Khơi")
    btnNamMoiPhatTai := myGui.AddButton("w200 h30 x10 y190", "Năm Mới Phát Tài")
    btnAnhHon := myGui.AddButton("w200 h30 x10 y225", "Ảnh hồn")
    btnTanCongHaiQuan := myGui.AddButton("w200 h30 x10 y260", "Tấn công hải quân")
    btnHdTT := myGui.AddButton("w200 h30 x10 y295", "Hỏi đáp có thưởng")

    myTab.UseTab(0)

    btnStop := myGui.AddButton("w50 h30 x10 y40", "Dừng")
    btnTest := myGui.AddButton("w50 h30 x60 y40", "Test")
    btnChangeName := myGui.AddButton("w50 h30 x110 y40", "Change")
    btnResize := myGui.AddButton("w50 h30 x160 y40", "Resize")

    ; Main Tab
    btnDaily.OnEvent("Click", (*) => _feature_daily())
    btnTBC.OnEvent("Click", (*) => _feature_tam_bao_chien())
    btnHaiTacThongThai.OnEvent("Click", (*) => _feature_haitacthongthai())

    ; Support tab
    btnEnhance.OnEvent("Click", (*) => _feature_enhance(g_inputCount.Value))
    btnRaKhoi.OnEvent("Click", (*) => _feature_rakhoi(g_inputCount.Value))
    btnNamMoiPhatTai.OnEvent("Click", (*) => _feature_nammoiphattai(g_inputCount.Value))
    btnAnhHon.OnEvent("Click", (*) => _feature_anhhon(g_inputCount.Value))
    btnTanCongHaiQuan.OnEvent("Click", (*) => _feature_tanconghaiquan())
    btnHdTT.OnEvent("Click", (*) => _feature_hoidapcothuong())

    btnStop.OnEvent("Click", (*) => _feature_stop())
    btnTest.OnEvent("Click", (*) => _feature_test())
    btnChangeName.OnEvent("Click", (*) => _feature_change_win())
    btnResize.OnEvent("Click", (*) => _win_resize_list())

    myGui.OnEvent("Close", (*) => ExitApp())

    myGui.Show()
    _start_event_timer()
    _start_activity_scheduler()
}

_get_next_event_text() {
    iniPath := A_ScriptDir . "\resources\events.ini"
    if !FileExist(iniPath)
        return "Sự kiện tiếp theo: Không có lịch"

    currentDay := _get_weekday_from_ahk()
    currentHour := Integer(A_Hour)
    currentMinute := Integer(A_Min)

    if (currentHour >= 22)
        return "Trạng thái: Kết thúc hoạt động"

    eventList := []
    loop read iniPath {
        if InStr(A_LoopReadLine, "[") or InStr(A_LoopReadLine, "=") = 0
            continue
        parts := StrSplit(A_LoopReadLine, "=")
        eventName := Trim(parts[1])
        eventTimeStr := Trim(parts[2])
        timeParts := StrSplit(eventTimeStr, "|")
        daysStr := Trim(timeParts[1])
        timeStr := Trim(timeParts[2])
        eventHour := Integer(StrSplit(timeStr, ":")[1])
        eventMinute := Integer(StrSplit(timeStr, ":")[2])

        days := StrSplit(daysStr, ",")
        for day in days {
            day := Integer(Trim(day))
            if (day = currentDay)
                eventList.Push({name: eventName, hour: eventHour, minute: eventMinute, day: day})
        }
    }

    if (eventList.Length = 0)
        return "Sự kiện tiếp theo: Không có hôm nay"

    nextEvent := ""
    minDiff := 999999

    for event in eventList {
        diff := (event.hour - currentHour) * 60 + (event.minute - currentMinute)
        if (diff > 0 and diff < minDiff) {
            minDiff := diff
            nextEvent := event
        }
    }

    if (nextEvent = "")
        return "Sự kiện tiếp theo: Không còn hôm nay"

    timeStr := Format("{:02}:{:02}", nextEvent.hour, nextEvent.minute)
    return "Sự kiện tiếp theo: " . nextEvent.name . " - " . timeStr
}

_update_event_text() {
    global g_nextEventControl
    g_nextEventControl.Value := _get_next_event_text()
}

_start_event_timer() {
    global g_eventTimerEnabled
    if !g_eventTimerEnabled {
        g_eventTimerEnabled := true
        SetTimer(_update_event_text, 60000)
    }
}

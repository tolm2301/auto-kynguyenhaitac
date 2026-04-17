isRunning := false
g_nextEventText := ""
g_eventTimerEnabled := false

_gui_init() {
    global g_inputCount, isRunning, g_featureText, g_nextEventText, g_nextEventControl

    guiCfg := {
        width: 360,
        height: 525,
        marginX: 14,
        marginY: 12,
        tabX: 14,
        tabY: 165,
        tabW: 332,
        tabH: 295,
        sectionW: 300,
        sectionBtnH: 34
    }

    myGui := Gui("+Resize +MinSize340x500", "Auto VHT - Control Panel")
    myGui.Icon := A_ScriptDir . "\resources\icon.ico"
    myGui.MarginX := guiCfg.marginX
    myGui.MarginY := guiCfg.marginY
    myGui.BackColor := "F5F7FB"

    myGui.SetFont("s12 Bold", "Segoe UI")
    myGui.AddText("x14 y10 w330 h26", "AUTO VHT")
    myGui.SetFont("s9 c666666", "Segoe UI")
    myGui.AddText("x14 y34 w330 h20", "Bảng điều khiển tự động - giao diện tối ưu")

    myGui.SetFont("s10", "Segoe UI")
    myGui.AddGroupBox("x14 y56 w332 h72", "Thiết lập nhanh")
    myGui.AddText("x28 y86 w100 h24 +0x200", "Số lượt chạy")
    g_inputCount := myGui.AddEdit("x130 y84 w64 h26 vInputCount", "1")

    btnStop := myGui.AddButton("x208 y82 w62 h28", "Dừng")
    btnTest := myGui.AddButton("x276 y82 w62 h28", "Test")
    btnChangeName := myGui.AddButton("x208 y112 w62 h28", "Đổi tên")
    btnResize := myGui.AddButton("x276 y112 w62 h28", "Resize")

    myGui.SetFont("s10 Bold c1F2937", "Segoe UI")
    g_featureText := myGui.AddText("x14 y134 w332 h24 +0x200", "Tính năng đang chạy: Chưa có")

    myGui.SetFont("s10", "Segoe UI")
    myTab := myGui.AddTab("x" guiCfg.tabX " y" guiCfg.tabY " w" guiCfg.tabW " h" guiCfg.tabH, ["Main", "Boss", "Phụ trợ"])

    myGui.SetFont("s9 c374151", "Segoe UI")
    g_nextEventControl := myGui.AddText("x14 y472 w332 h28 +0x200", "")
    _update_event_text()

    ; Main Tab
    myTab.UseTab(1)
    btnDaily := myGui.AddButton("x30 y205 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Daily")
    btnTBC := myGui.AddButton("x30 y245 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Tầm bảo chiến")
    btnHaiTacThongThai := myGui.AddButton("x30 y285 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Hải tặc thông thái")

    ; Boss Tab (auto by scheduler)
    myTab.UseTab(2)
    myGui.SetFont("s10 Bold c1F2937", "Segoe UI")
    myGui.AddText("x30 y205 w300 h22", "Boss chạy tự động theo lịch")
    myGui.SetFont("s9 c4B5563", "Segoe UI")
    myGui.AddText("x30 y232 w300 h40", "Bạn có thể chỉnh khung giờ trong`nresources/events.ini")

    ; Support tab
    myTab.UseTab(3)
    btnEnhance := myGui.AddButton("x30 y195 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Cường Hoá")
    btnRaKhoi := myGui.AddButton("x30 y232 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Ra Khơi")
    btnNamMoiPhatTai := myGui.AddButton("x30 y269 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Năm Mới Phát Tài")
    btnAnhHon := myGui.AddButton("x30 y306 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Ảnh hồn")
    btnTanCongHaiQuan := myGui.AddButton("x30 y343 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Tấn công hải quân")
    btnHdTT := myGui.AddButton("x30 y380 w" guiCfg.sectionW " h" guiCfg.sectionBtnH, "Hỏi đáp có thưởng")

    myTab.UseTab(0)

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

    myGui.OnEvent("Close", _app_shutdown)

    myGui.Show("w" guiCfg.width " h" guiCfg.height)
    _start_event_timer()
    _start_activity_scheduler()
}

_app_shutdown(*) {
    try _feature_stop()
    ExitApp()
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

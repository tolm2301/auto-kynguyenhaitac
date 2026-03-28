
isRunning := false
g_nextEventText := ""

_gui_init() {
    global g_inputCount, isRunning, g_featureText, g_nextEventText

    myGui := Gui("", "Auto VHT")

    myGui.Icon := A_ScriptDir . "\resources\icon.ico"
    myGui.AddText("x10 y10 w200 h30", "Nhập số lượt:")
    g_inputCount := myGui.AddEdit("w50 h30 vInputCount x100 y10", "1")
    g_featureText := myGui.AddText("x10 y75 w200 h30", "Tính năng đang chạy: Chưa có")

    myTab := myGui.AddTab("x10 y105 w210 h310", ["Main", "Boss", "Phụ trợ"])

    g_nextEventText := myGui.AddText("x10 y420 w210 h30", _get_next_event_text())

    ; Main Tab
    myTab.UseTab(1)
    btnDaily := myGui.AddButton("w200 h30 x10 y130", "Daily")

    ; Event tab
    myTab.UseTab(2)
    btnPunk := myGui.AddButton("w200 h30 x10 y130", "Rồng Punk")
    btnKraken := myGui.AddButton("w200 h30 x10 y165", "Kraken")
    btnKaido := myGui.AddButton("w200 h30 x10 y190", "Kaido")

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

    btnDaily.OnEvent("Click", (*) => _feature_daily())

    btnPunk.OnEvent("Click", (*) => _feature_punk())
    btnKraken.OnEvent("Click", (*) => _feature_kraken())
    btnKaido.OnEvent("Click", (*) => _feature_kaido())

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
}

_get_next_event_text() {
    iniPath := A_ScriptDir . "\resources\events.ini"
    if !FileExist(iniPath)
        return "Sự kiện tiếp theo: Không có lịch"

    currentDay := Mod(A_WDay, 7)
    if (currentDay = 0)
        currentDay := 7

    currentHour := A_Hour
    currentMinute := A_Min

    if (currentHour >= 22) {
        return "Trạng thái: Kết thúc hoạt động"
    }

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
            if (day = currentDay) {
                eventList.Push({name: eventName, hour: eventHour, minute: eventMinute, day: day})
            }
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

    if (nextEvent = "") {
        return "Sự kiện tiếp theo: Không còn hôm nay"
    }

    hours := nextEvent.hour
    minutes := nextEvent.minute
    timeStr := Format("{:02}:{:02}", hours, minutes)

    return "Sự kiện tiếp theo: " . nextEvent.name . " - " . timeStr
}


isRunning := false

_gui_init() {
    global g_inputCount, isRunning, g_featureText

    myGui := Gui("", "Auto VHT")

    myGui.Icon := A_ScriptDir . "\resources\icon.ico"
    myGui.AddText("x10 y10 w200 h30", "Nhập số lượt:")
    g_inputCount := myGui.AddEdit("w50 h30 vInputCount x100 y10", "1")
    g_featureText := myGui.AddText("x10 y75 w200 h30", "Tính năng đang chạy: Chưa có")

    ; === BUTTON ===
    btnStop := myGui.AddButton("w50 h30 x10 y40", "Dừng")
    btnTest := myGui.AddButton("w50 h30 x60 y40", "Test")
    btnChangeName := myGui.AddButton("w50 h30 x110 y40", "Change")
    btnResize := myGui.AddButton("w200 h30 x10 y100", "Resize Game")

    ; FEATURE
    btnEnhance := myGui.AddButton("w200 h30 x10 y140", "Cường Hoá")
    btnRaKhoi := myGui.AddButton("w200 h30 x10 y180", "Ra Khơi")
    btnNamMoiPhatTai := myGui.AddButton("w200 h30 x10 y220", "Năm Mới Phát Tài")
    btnDaily := myGui.AddButton("w200 h30 x10 y300", "Daily")
    btnAnhHon := myGui.AddButton("w200 h30 x10 y340", "Ảnh hồn")
    btnTanCongHaiQuan := myGui.AddButton("w200 h30 x10 y380", "Tấn công hải quân")
    btnHdTT := myGui.AddButton("w200 h30 x10 y420", "Hỏi đáp có thưởng - Hải Tặc thông thái")

    ; BOSS
    btnPunk := myGui.AddButton("w100 h30 x10 y260", "Rồng Punk")
    btnKraken := myGui.AddButton("w100 h30 x110 y260", "Kraken")

    ; === EVENT HANDLER ===
    btnStop.OnEvent("Click", (*) => _feature_stop())
    btnTest.OnEvent("Click", (*) => _feature_test())
    btnChangeName.OnEvent("Click", (*) => _feature_change_win())
    btnResize.OnEvent("Click", (*) => _win_resize_game())
    
    ; FEATURE
    btnEnhance.OnEvent("Click", (*) => _feature_enhance(g_inputCount.Value))
    btnRaKhoi.OnEvent("Click", (*) => _feature_rakhoi(g_inputCount.Value))
    btnNamMoiPhatTai.OnEvent("Click", (*) => _feature_nammoiphattai(g_inputCount.Value))
    btnAnhHon.OnEvent("Click", (*) => _feature_anhhon(g_inputCount.Value))
    btnDaily.OnEvent("Click", (*) => _feature_daily())
    btnTanCongHaiQuan.OnEvent("Click", (*) => _feature_tanconghaiquan())
    btnHdTT.OnEvent("Click", (*) => _feature_hoidapcothuong())
    
    ; BOSS
    btnPunk.OnEvent("Click", (*) => _feature_punk())
    btnKraken.OnEvent("Click", (*) => _feature_kraken())

    myGui.Show()
}
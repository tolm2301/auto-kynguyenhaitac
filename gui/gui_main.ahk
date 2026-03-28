
isRunning := false

_gui_init() {
    global g_inputCount, isRunning, g_featureText, g_giftcodeInput, g_prefixInput, g_countInput

    myGui := Gui("+AlwaysOnTop", "Auto VHT")

    myGui.Icon := A_ScriptDir . "\resources\icon.ico"
    myGui.AddText("x10 y10 w200 h30", "Nhập số lượt:")
    g_inputCount := myGui.AddEdit("w50 h30 vInputCount x100 y10", "1")
    g_featureText := myGui.AddText("x10 y75 w200 h30", "Tính năng đang chạy: Chưa có")

    ; === GIFT CODE ===
    myGui.AddText("x10 y110 w60 h20", "Prefix:")
    g_prefixInput := myGui.AddEdit("w140 h25 x10 y130 vPrefixInput", "KN426")
    myGui.AddText("x10 y158 w60 h20", "Số lượt:")
    g_countInput := myGui.AddEdit("w140 h25 x10 y178 vCountInput", "10")
    btnGiftcode := myGui.AddButton("w200 h30 x10 y210", "Tạo & Nhập Gift Code")

    ; === BUTTON ===
    btnStop := myGui.AddButton("w50 h30 x10 y250", "Dừng")
    btnTest := myGui.AddButton("w50 h30 x60 y250", "Test")
    btnChangeName := myGui.AddButton("w50 h30 x110 y250", "Change")
    btnResize := myGui.AddButton("w200 h30 x10 y285", "Resize Game")

    ; FEATURE
    btnEnhance := myGui.AddButton("w200 h30 x10 y325", "Cường Hoá")
    btnRaKhoi := myGui.AddButton("w200 h30 x10 y365", "Ra Khơi")
    btnNamMoiPhatTai := myGui.AddButton("w200 h30 x10 y405", "Năm Mới Phát Tài")
    btnDaily := myGui.AddButton("w200 h30 x10 y485", "Daily")
    btnAnhHon := myGui.AddButton("w200 h30 x10 y525", "Ảnh hồn")
    btnTanCongHaiQuan := myGui.AddButton("w200 h30 x10 y565", "Tấn công hải quân")
    btnHdTT := myGui.AddButton("w200 h30 x10 y605", "Hỏi đáp có thưởng - Hải Tặc thông thái")

    ; BOSS
    btnPunk := myGui.AddButton("w100 h30 x10 y445", "Rồng Punk")
    btnKraken := myGui.AddButton("w100 h30 x110 y445", "Kraken")

    ; === EVENT HANDLER ===
    btnStop.OnEvent("Click", (*) => _feature_stop())
    btnTest.OnEvent("Click", (*) => _feature_test())
    btnChangeName.OnEvent("Click", (*) => _feature_change_win())
    btnResize.OnEvent("Click", (*) => _win_resize_list())
    btnGiftcode.OnEvent("Click", (*) => _feature_giftcode_pattern(g_prefixInput.Value, Integer(g_countInput.Value)))
    
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

    myGui.OnEvent("Close", (*) => ExitApp())

    myGui.Show()
}
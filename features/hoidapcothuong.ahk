_feature_hoidapcothuong() {
    vX := SysGet(76), vY := SysGet(77), vW := SysGet(78), vH := SysGet(79)
    hbm := CreateScreenShot(vX, vY, vW, vH)
    
    MyGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale")
    MyGui.BackColor := "Black"
    MyGui.Add("Pic", "x0 y0 w" vW " h" vH, "HBITMAP:*" hbm)
    MyGui.Show("x" vX " y" vY " w" vW " h" vH)
    WinSetTransparent(200, MyGui) 

    Area := GetSelectionCoords()
    MyGui.Destroy()
    DllCall("DeleteObject", "Ptr", hbm)

    if (Area.w < 5 || Area.h < 5)
        return

    try {
        ; 2. OCR bằng engine 'en'
        Result := OCR.FromRect(Area.x, Area.y, Area.w, Area.h, { lang: "en" })
        
        if (Result.Text == "")
            return

        ; 3. Làm sạch văn bản quét được
        ScannedText := Result.Text
        ScannedText := RemoveVNSigns(ScannedText)
        ScannedText := RegExReplace(ScannedText, "\s+", " ")
        ScannedText := Trim(ScannedText)

        ; 4. Tìm kiếm tương đồng trong file INI
        BestMatch := FindFuzzyMatch(A_ScriptDir . "\resources\Question.ini", "Questions", ScannedText, 0.6) ; Ngưỡng 60%

        if (BestMatch.Score > 0) {
            MsgBox("DÔ GIỐNG: " . Round(BestMatch.Score * 100) . "%`n`nCÂU HỎI QUÉT: " . ScannedText . "`n`nCÂU KHỚP NHẤT: " . BestMatch.Question . "`n`nĐÁP ÁN: " . BestMatch.Answer, "KẾT QUẢ")
        } else {
            MsgBox("CÂU HỎI: " . ScannedText . "`n`nĐÁP ÁN: CHƯA CÓ TRONG DATA (Độ giống < 60%)", "THÔNG BÁO")
        }
        
    } catch Error as e {
        MsgBox("Lỗi: " . e.Message)
    }
}

; --- Hàm tìm kiếm tương đồng (Fuzzy Search) ---
FindFuzzyMatch(IniPath, Section, SearchStr, Threshold := 0.6) {
    BestScore := 0
    MatchedQ := ""
    MatchedA := ""
    
    ; Đọc toàn bộ nội dung Section
    try {
        AllData := IniRead(IniPath, Section)
    } catch {
        return {Score: 0}
    }
    
    Loop Parse, AllData, "`n", "`r" {
        if (A_LoopField == "")
            continue
            
        ; Tách key (Câu hỏi) và value (Đáp án)
        Pos := InStr(A_LoopField, "=")
        if (!Pos) 
            continue
        
        FileQ := SubStr(A_LoopField, 1, Pos-1)
        FileQ := RemoveVNSigns(FileQ)
        FileA := SubStr(A_LoopField, Pos+1)
        
        ; Tính độ tương đồng giữa SearchStr và FileQ (0.0 -> 1.0)
        CurrentScore := StrDiff(SearchStr, FileQ)
        
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

; --- Hàm tính toán độ khác biệt chuỗi (Levenshtein Distance) ---
StrDiff(s1, s2) {
    L1 := StrLen(s1), L2 := StrLen(s2)
    if (L1 == 0 || L2 == 0) 
        return 0
    
    ; Đưa về chữ thường để so sánh cho chuẩn
    s1 := StrLower(s1), s2 := StrLower(s2)
    
    MaxLen := Max(L1, L2)
    Dist := Array()
    Loop L1 + 1 {
        i := A_Index - 1
        Dist.Push(Array())
        Loop L2 + 1 {
            j := A_Index - 1
            Dist[i+1].Push(i == 0 ? j : (j == 0 ? i : 0))
        }
    }
    
    Loop L1 {
        i := A_Index
        Loop L2 {
            j := A_Index
            cost := (SubStr(s1, i, 1) == SubStr(s2, j, 1) ? 0 : 1)
            Dist[i+1][j+1] := Min(Dist[i][j+1] + 1, Dist[i+1][j] + 1, Dist[i][j] + cost)
        }
    }
    
    ; Trả về tỉ lệ % giống nhau
    return 1 - (Dist[L1+1][L2+1] / MaxLen)
}

; --- Các hàm bổ trợ (Giữ nguyên) ---
RemoveVNSigns(str) {
    static vnsigns := Map(
        "a", "á|à|ả|ã|ạ|ă|ắ|ằ|ẳ|ẵ|ặ|â|ấ|ầ|ẩ|ẫ|ậ|ä|å|æ",
        "A", "Á|À|Ả|Ã|Ạ|Ă|Ắ|Ằ|Ẳ|Ẵ|Ặ|Â|Ấ|Ầ|Ẩ|Ẫ|Ậ",
        "d", "đ|ð", "D", "Đ",
        "e", "é|è|ẻ|ẽ|ẹ|ê|ế|ề|ể|ễ|ệ|ë",
        "E", "É|È|Ẻ|Ẽ|Ẹ|Ê|Ế|Ề|Ể|Ễ|Ệ",
        "i", "í|ì|ỉ|ĩ|ị|ï|î", "I", "Í|Ì|Ỉ|Ĩ|Ị",
        "o", "ó|ò|ỏ|õ|ọ|ô|ố|ồ|ổ|ỗ|ộ|ơ|ớ|ờ|ở|ỡ|ợ|ö|ô|ø",
        "O", "Ó|Ò|Ỏ|Õ|Ọ|Ô|Ố|Ồ|Ổ|Ỗ|Ộ|Ơ|Ớ|Ờ|Ở|Ỡ|Ợ",
        "u", "ú|ù|ủ|ũ|ụ|ư|ứ|ừ|ử|ữ|ự|ü|û|w",
        "U", "Ú|Ù|Ủ|Ũ|Ụ|Ư|Ứ|Ừ|Ử|Ữ|Ự",
        "y", "ý|ỳ|ỷ|ỹ|ỵ", "Y", "Ý|Ì|Ỷ|Ỹ|Ỵ"
    )
    for res, signs in vnsigns
        str := RegExReplace(str, "i)(" . signs . ")", res)
    str := RegExReplace(str, "[^a-zA-Z0-9\s?]", "")
    return StrLower(str)
}

CreateScreenShot(x, y, w, h) {
    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    hbm := DllCall("CreateCompatibleBitmap", "Ptr", hdcScreen, "Int", w, "Int", h, "Ptr")
    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hbm)
    DllCall("BitBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdcScreen, "Int", x, "Int", y, "UInt", 0x00CC0020)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen), DllCall("DeleteDC", "Ptr", hdcMem)
    return hbm
}

GetSelectionCoords() {
    CoordMode "Mouse", "Screen"
    KeyWait "LButton", "D"
    MouseGetPos(&sX, &sY)
    RectGui := Gui("-Caption +AlwaysOnTop +ToolWindow +LastFound"), RectGui.BackColor := "Red"
    WinSetTransparent(100, RectGui)
    Area := { x: 0, y: 0, w: 0, h: 0 }
    While GetKeyState("LButton", "P") {
        MouseGetPos(&cX, &cY)
        Area.x := Min(sX, cX), Area.y := Min(sY, cY), Area.w := Abs(sX - cX), Area.h := Abs(sY - cY)
        RectGui.Show("x" Area.x " y" Area.y " w" Area.w " h" Area.h " NA"), Sleep(10)
    }
    RectGui.Destroy()
    return Area
}
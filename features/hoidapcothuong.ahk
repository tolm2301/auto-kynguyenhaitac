_feature_hoidapcothuong() {
    _win_resize_list
    hwnds := _win_get_list()

    try {
        ; 2. OCR bằng engine 'en'
        global ocr_result

        hwnd := hwnds[1]

        if (getHour() >= 11 and getHour() <= 13) {
            ocr_result := _ocr_from_bit_map(hwnd, 0, 0, 1280, 720)
        } else {
            ocr_result := _ocr_from_bit_map(hwnd, 632, 153, 878, 186)
        }

        section := "Questions"

        if (getHour() >= 11 and getHour() <= 13) {
            section := "Hoidapcothuong"
        }

        ; 4. Tìm kiếm tương đồng trong file INI
        BestMatch := FindFuzzyMatch(A_ScriptDir . "\resources\Question.ini", section, ocr_result, 0.5) ; Ngưỡng 40%

        if (BestMatch.Score > 0) {
            MsgBox("CÂU HỎI: " . BestMatch.Question . "`n`nĐÁP ÁN: " . BestMatch.Answer, "KẾT QUẢ")
        } else {
            MsgBox("CÂU HỎI: " . ocr_result . "`n`nĐÁP ÁN: CHƯA CÓ TRONG DATA (Độ giống < 60%)", "THÔNG BÁO")
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
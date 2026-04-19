_get_gmt_7() {
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("HEAD", "https://www.google.com", false)
        whr.Send()

        dateStr := whr.GetResponseHeader("Date")
        
        ado := ComObject("ADODB.Connection")
        
        dt := DateAdd(format_to_iso_date_time(dateStr), 7, "Hours") 
        return FormatTime(dt, "yyyy-MM-ddTHH:mm:ss") . ".000+07:00"
    } catch {
        return "Lỗi kết nối hoặc không lấy được giờ"
    }
}

format_to_iso_date_time(httpDate) {
    static Months := {Jan:"01",Feb:"02",Mar:"03",Apr:"04",May:"05",Jun:"06",Jul:"07",Aug:"08",Sep:"09",Oct:"10",Nov:"11",Dec:"12"}
    RegExMatch(httpDate, "\w+, (\d+) (\w+) (\d+) (\d+):(\d+):(\d+)", &m)
    return m[3] . Months.%m[2]% . Format("{:02}", m[1]) . m[4] . m[5] . m[6]
}

; --- CÁC HÀM XỬ LÝ TRÍCH XUẤT ---
getYear() => SubStr(_get_gmt_7(), 1, 4)
getMonth() => SubStr(_get_gmt_7(), 6, 2)
getDate() => SubStr(_get_gmt_7(), 9, 2)
getHour() => SubStr(_get_gmt_7(), 12, 2)
getMinute() => SubStr(_get_gmt_7(), 15, 2)
getSecond() => SubStr(_get_gmt_7(), 18, 2)
getMiliSecond() => SubStr(_get_gmt_7(), 21, 3)
getDayOfTheWeekNumber() {
    dt := SubStr(_get_gmt_7(), 1, 19)
    dt := StrReplace(dt, "-", "")
    dt := StrReplace(dt, ":", "")
    dt := StrReplace(dt, "T", "")
    return FormatTime(dt, "WDay")
}
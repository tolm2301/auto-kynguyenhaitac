# Debug and Stability Skill (AHK2)

## Mục tiêu
Giảm lỗi runtime, dễ truy vết sự cố, và giữ automation chạy ổn định dài hạn.

## Logging pattern

```autohotkey
Log(msg, level := "INFO") {
    ts := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    line := "[" ts "] [" level "] " msg "`n"
    FileAppend(line, A_ScriptDir "\\logs\\automation.log", "UTF-8")
}
```

## Retry pattern

```autohotkey
Retry(actionFn, maxTry := 3, delayMs := 500) {
    loop maxTry {
        try {
            if actionFn.Call()
                return true
        } catch as err {
            Log("Retry " A_Index " error: " err.Message, "WARN")
        }
        Sleep(delayMs)
    }
    return false
}
```

## Timeout guard

```autohotkey
WaitUntil(predicateFn, timeoutMs := 3000, tickMs := 100) {
    start := A_TickCount
    while (A_TickCount - start < timeoutMs) {
        if predicateFn.Call()
            return true
        Sleep(tickMs)
    }
    return false
}
```

## Checklist debug nhanh
1. Xác minh `CoordMode` (Screen/Window/Client) trước khi click/search.
2. Log các biến đầu vào quan trọng (region, image path, title).
3. Ghi rõ fail point: bước nào, retry thứ mấy.
4. Bắt exception ở entry function để không crash toàn app.
5. Khi lỗi khó tái hiện: chụp ảnh màn hình + log timestamp.

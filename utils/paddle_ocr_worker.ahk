#Requires AutoHotkey v2.0

global g_ocr_worker_state := 0

_ocr_worker_init() {
    global g_ocr_worker_state

    if IsObject(g_ocr_worker_state)
        return g_ocr_worker_state

    pythonExe := EnvGet("OCR_WORKER_PYTHON")
    if (pythonExe = "")
        pythonExe := "python"

    state := Map()
    state["pythonExe"] := pythonExe
    state["workerScriptPath"] := A_ScriptDir . "\tools\ocr_worker.py"
    state["ipcDir"] := A_Temp . "\auto_kynguyenhaitac_ocr"
    state["requestDir"] := state["ipcDir"] . "\requests"
    state["responseDir"] := state["ipcDir"] . "\responses"
    state["readyFilePath"] := state["ipcDir"] . "\worker.ready"
    state["requestTimeoutMs"] := 15000
    state["startupTimeoutMs"] := 20000
    state["pollIntervalMs"] := 60
    state["lang"] := "vi"
    state["keepTempFiles"] := false
    state["workerPid"] := 0
    state["logFilePath"] := A_ScriptDir . "\logs\ocr_worker.log"
    state["pythonLogPath"] := A_ScriptDir . "\logs\ocr_worker_py.log"
    state["lastStartCommand"] := ""
    state["lastError"] := ""

    g_ocr_worker_state := state
    _ocr_worker_prepare_runtime_dirs(state)
    return g_ocr_worker_state
}

_ocr_worker_prepare_runtime_dirs(state := 0) {
    if !IsObject(state)
        state := _ocr_worker_init()

    try DirCreate(state["ipcDir"])
    try DirCreate(state["requestDir"])
    try DirCreate(state["responseDir"])
    try DirCreate(A_ScriptDir . "\logs")
}

_ocr_worker_apply_options(ocrOptions := 0) {
    state := _ocr_worker_init()
    if !IsObject(ocrOptions)
        return state

    if (Type(ocrOptions) != "Map")
        return state

    if ocrOptions.Has("lang") {
        lang := Trim(ocrOptions["lang"])
        if (lang != "")
            state["lang"] := lang
    }

    if ocrOptions.Has("timeoutMs") {
        timeoutMs := Integer(ocrOptions["timeoutMs"])
        if (timeoutMs > 0)
            state["requestTimeoutMs"] := timeoutMs
    }

    if ocrOptions.Has("keepTempFiles")
        state["keepTempFiles"] := !!ocrOptions["keepTempFiles"]

    if ocrOptions.Has("pythonExe") {
        pythonExe := Trim(ocrOptions["pythonExe"])
        if (pythonExe != "")
            state["pythonExe"] := pythonExe
    }

    return state
}

_ocr_worker_ensure_ready() {
    state := _ocr_worker_init()
    _ocr_worker_prepare_runtime_dirs(state)

    if _ocr_worker_has_ready_marker(state)
        return true

    return _ocr_worker_start_background(state)
}

_ocr_worker_has_ready_marker(state := 0) {
    if !IsObject(state)
        state := _ocr_worker_init()

    readyPath := state["readyFilePath"]
    if !FileExist(readyPath)
        return false

    try {
        readyText := FileRead(readyPath, "UTF-8")
        if !(InStr(readyText, "READY=1") > 0)
            return false

        if RegExMatch(readyText, "m)^PID=(\d+)$", &pidMatch)
            return ProcessExist(Integer(pidMatch[1])) > 0

        return true
    } catch {
        return false
    }
}

_ocr_worker_start_background(state := 0) {
    if !IsObject(state)
        state := _ocr_worker_init()

    if !FileExist(state["workerScriptPath"]) {
        state["lastError"] := "Worker script not found: " . state["workerScriptPath"]
        _ocr_worker_trace("ERROR", "StartBackground missingScript", Map("path", state["workerScriptPath"]))
        return false
    }

    readyPath := state["readyFilePath"]
    try FileDelete(readyPath)

    command := Format('"{1}" "{2}" --server --ipc-dir "{3}" --ready-file "{4}" --log-file "{5}" --lang "{6}"'
        , state["pythonExe"], state["workerScriptPath"], state["ipcDir"], readyPath, state["pythonLogPath"], state["lang"])
    state["lastStartCommand"] := command

    _ocr_worker_trace("INFO", "StartBackground command", Map(
        "command", command,
        "pythonExe", state["pythonExe"],
        "workerScriptPath", state["workerScriptPath"],
        "ipcDir", state["ipcDir"]
    ))

    try {
        pid := 0
        Run(command, A_ScriptDir, "Hide", &pid)
        state["workerPid"] := pid
    } catch Error as err {
        state["lastError"] := err.Message
        _ocr_worker_trace("ERROR", "StartBackground run failed", Map("err", err.Message, "command", command))
        return false
    }

    startedAt := A_TickCount
    timeoutMs := state["startupTimeoutMs"]
    while ((A_TickCount - startedAt) <= timeoutMs) {
        if _ocr_worker_has_ready_marker(state) {
            _ocr_worker_trace("INFO", "StartBackground ready", Map("workerPid", state["workerPid"], "waitedMs", A_TickCount - startedAt))
            return true
        }
        Sleep(state["pollIntervalMs"])
    }

    state["lastError"] := "OCR worker not ready within timeout"
    _ocr_worker_trace("ERROR", "StartBackground timeout", Map(
        "startupTimeoutMs", timeoutMs,
        "workerPid", state["workerPid"],
        "readyFilePath", state["readyFilePath"],
        "command", command
    ))
    return false
}

_ocr_worker_from_hbitmap(hBitmap, ocrOptions := 0) {
    state := _ocr_worker_apply_options(ocrOptions)
    startedAt := A_TickCount

    result := Map(
        "ok", false,
        "text", "",
        "err", "",
        "elapsedMs", 0
    )

    try {
        if !hBitmap
            throw Error("Invalid HBITMAP")

        if !_ocr_worker_ensure_ready()
            throw Error("OCR worker is not ready. lastError=" . state["lastError"])

        reqId := _ocr_worker_build_request_id()
        imagePath := state["ipcDir"] . "\\img_" . reqId . ".png"
        reqTmpPath := state["requestDir"] . "\\req_" . reqId . ".tmp"
        reqPath := state["requestDir"] . "\\req_" . reqId . ".req"
        respPath := state["responseDir"] . "\\resp_" . reqId . ".resp"

        _ocr_save_bitmap_to_file(hBitmap, imagePath)

        reqText := "REQUEST_ID=" . reqId . "`n"
        reqText .= "IMAGE_PATH=" . imagePath . "`n"
        reqText .= "RESPONSE_PATH=" . respPath . "`n"
        reqText .= "LANG=" . state["lang"] . "`n"

        try FileDelete(reqTmpPath)
        try FileDelete(reqPath)
        try FileDelete(respPath)

        FileAppend(reqText, reqTmpPath, "UTF-8")
        FileMove(reqTmpPath, reqPath, 1)

        _ocr_worker_trace("INFO", "Request queued", Map(
            "requestId", reqId,
            "imagePath", imagePath,
            "requestPath", reqPath,
            "responsePath", respPath
        ))

        waitResult := _ocr_worker_wait_response(respPath, state["requestTimeoutMs"], state["pollIntervalMs"])
        if !waitResult["ok"]
            throw Error(waitResult["err"])

        parsed := _ocr_worker_parse_response(waitResult["data"])
        result["ok"] := parsed["ok"]
        result["text"] := parsed["text"]
        result["err"] := parsed["err"]
        result["elapsedMs"] := parsed["elapsedMs"]

        _ocr_worker_trace("INFO", "Response parsed", Map(
            "requestId", reqId,
            "ok", result["ok"],
            "elapsedMs", result["elapsedMs"],
            "textPreview", _ocr_worker_short_text(result["text"]),
            "err", result["err"]
        ))

        if !state["keepTempFiles"] {
            try FileDelete(imagePath)
            try FileDelete(reqPath)
            try FileDelete(respPath)
        }
    } catch Error as err {
        result["ok"] := false
        result["text"] := ""
        result["err"] := err.Message
        _ocr_worker_trace("ERROR", "FromHBitmap failed", Map(
            "err", err.Message,
            "what", err.What,
            "line", err.Line,
            "extra", err.Extra
        ))
    }

    result["elapsedMs"] := A_TickCount - startedAt
    return result
}

_ocr_worker_wait_response(respPath, timeoutMs, pollIntervalMs) {
    startedAt := A_TickCount
    while ((A_TickCount - startedAt) <= timeoutMs) {
        if FileExist(respPath) {
            try {
                return Map("ok", true, "data", FileRead(respPath, "UTF-8"), "err", "")
            } catch Error as err {
                return Map("ok", false, "data", "", "err", "Read response failed: " . err.Message)
            }
        }
        Sleep(pollIntervalMs)
    }

    return Map("ok", false, "data", "", "err", "Wait response timeout: " . respPath)
}

_ocr_worker_parse_response(rawText) {
    result := Map(
        "ok", false,
        "text", "",
        "err", "",
        "elapsedMs", 0
    )

    for line in StrSplit(rawText, "`n", "`r") {
        if (line = "")
            continue

        if InStr(line, "OK=") = 1 {
            result["ok"] := (Trim(SubStr(line, 4)) = "1")
            continue
        }

        if InStr(line, "ELAPSED_MS=") = 1 {
            elapsedText := Trim(SubStr(line, 12))
            if (elapsedText != "")
                result["elapsedMs"] := Integer(elapsedText)
            continue
        }
    }

    result["err"] := _ocr_worker_extract_block(rawText, "ERR=`n", "`n--ERR_END--")
    result["text"] := _ocr_worker_extract_block(rawText, "TEXT=`n", "`n--TEXT_END--")

    if (!result["ok"] and result["err"] = "")
        result["err"] := "Worker returned not-ok without error details"

    return result
}

_ocr_worker_extract_block(rawText, startMarker, endMarker) {
    startPos := InStr(rawText, startMarker)
    if !startPos
        return ""

    contentStart := startPos + StrLen(startMarker)
    endPos := InStr(rawText, endMarker, false, contentStart)
    if !endPos
        return Trim(SubStr(rawText, contentStart), "`r`n")

    return Trim(SubStr(rawText, contentStart, endPos - contentStart), "`r`n")
}

_ocr_worker_build_request_id() {
    return Format("{1}_{2}_{3}", A_NowUTC, A_TickCount, Random(10000, 99999))
}

_ocr_worker_trace(level, message, details := "", debugContext := 0) {
    state := _ocr_worker_init()
    payload := _ocr_worker_to_text(details)
    ctxText := _ocr_worker_to_text(debugContext)
    if (ctxText != "") {
        if (payload = "")
            payload := "ctx=" . ctxText
        else
            payload .= "; ctx=" . ctxText
    }

    line := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    line .= " [" . level . "] " . message
    if (payload != "")
        line .= " | " . payload
    line .= "`r`n"

    _log_append(state["logFilePath"], line, "UTF-8")
    OutputDebug(line)
}

_ocr_worker_trace_capture_request(debugContext) {
    details := Map()
    details["hwnd"] := _ocr_worker_ctx_get(debugContext, "hwnd", "")
    details["region"] := _ocr_worker_ctx_get(debugContext, "region", "")
    details["scale"] := _ocr_worker_ctx_get(debugContext, "scale", "")
    details["scaledSize"] := _ocr_worker_ctx_get(debugContext, "scaledSize", "")
    details["debugImagePath"] := _ocr_worker_ctx_get(debugContext, "debugImagePath", "")
    details["captureElapsedMs"] := _ocr_worker_ctx_get(debugContext, "captureElapsedMs", "")
    _ocr_worker_trace("INFO", "TraceCaptureRequest", details, debugContext)
}

_ocr_worker_trace_capture_result(debugContext, result, totalElapsedMs) {
    details := Map()
    details["ok"] := _ocr_worker_try_get(result, "ok", false)
    details["err"] := _ocr_worker_try_get(result, "err", "")
    details["text"] := _ocr_worker_short_text(_ocr_worker_try_get(result, "text", ""))
    details["ocrElapsedMs"] := _ocr_worker_try_get(result, "elapsedMs", 0)
    details["totalElapsedMs"] := totalElapsedMs
    _ocr_worker_trace("INFO", "TraceCaptureResult", details, debugContext)
}

_ocr_worker_ctx_get(ctx, key, defaultValue := "") {
    if !IsObject(ctx)
        return defaultValue
    if (Type(ctx) != "Map")
        return defaultValue
    if !ctx.Has(key)
        return defaultValue
    return ctx[key]
}

_ocr_worker_try_get(source, key, defaultValue := "") {
    if !IsObject(source)
        return defaultValue
    if (Type(source) != "Map")
        return defaultValue
    if !source.Has(key)
        return defaultValue
    return source[key]
}

_ocr_worker_short_text(value) {
    text := Trim(value)
    if (StrLen(text) <= 160)
        return text
    return SubStr(text, 1, 157) . "..."
}

_ocr_worker_to_text(data) {
    return _ocr_worker_value_to_text(data)
}

_ocr_worker_value_to_text(value, depth := 0) {
    if (depth > 2)
        return "..."

    valueType := Type(value)
    if (valueType = "String")
        return _ocr_worker_short_text(value)

    if (valueType = "Integer" or valueType = "Float")
        return value

    if IsObject(value) {
        if (valueType = "Map") {
            parts := []
            for key, item in value
                parts.Push(key . "=" . _ocr_worker_value_to_text(item, depth + 1))
            return "{" . _ocr_worker_join(parts, "; ") . "}"
        }

        if (valueType = "Array") {
            parts := []
            for item in value
                parts.Push(_ocr_worker_value_to_text(item, depth + 1))
            return "[" . _ocr_worker_join(parts, ",") . "]"
        }
    }

    return value
}

_ocr_worker_join(items, separator := ",") {
    out := ""
    for index, item in items {
        if (index > 1)
            out .= separator
        out .= item
    }
    return out
}

_ui_get_base_dir() {
    if DirExist(A_ScriptDir . "\resources")
        return A_ScriptDir

    if DirExist(A_ScriptDir . "\..\resources")
        return A_ScriptDir . "\.."

    return A_ScriptDir
}

_ui_get_ini_path() {
    return _ui_get_base_dir() . "\resources\ui.ini"
}

_ui_log_warning(message) {
    logPath := _ui_get_base_dir() . "\logs\ui_config_warning.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    _log_append(logPath, "[" . timestamp . "] WARN: " . message . "`n")
}

_ui_get_hoat_dong_button() {
    defaultButton := [662, 39]
    iniPath := _ui_get_ini_path()
    section := "UI"
    key := "hoat_dong_button"

    if !FileExist(iniPath) {
        _ui_log_warning("Thiếu file ini UI: " . iniPath . " | dùng default hoat_dong_button=662,39")
        return defaultButton
    }

    try rawValue := IniRead(iniPath, section, key, "")
    catch as err {
        _ui_log_warning("Không đọc được " . key . " từ " . iniPath . " | " . err.Message . " | dùng default hoat_dong_button=662,39")
        return defaultButton
    }

    if (rawValue = "") {
        _ui_log_warning("Thiếu key " . key . " trong [" . section . "] của " . iniPath . " | dùng default hoat_dong_button=662,39")
        return defaultButton
    }

    parts := StrSplit(rawValue, ",")
    if (parts.Length < 2) {
        _ui_log_warning("Giá trị " . key . " không hợp lệ: " . rawValue . " | dùng default hoat_dong_button=662,39")
        return defaultButton
    }

    x := Trim(parts[1])
    y := Trim(parts[2])

    if !RegExMatch(x, "^-?\d+$") || !RegExMatch(y, "^-?\d+$") {
        _ui_log_warning("Giá trị " . key . " không phải số: " . rawValue . " | dùng default hoat_dong_button=662,39")
        return defaultButton
    }

    return [Integer(x), Integer(y)]
}

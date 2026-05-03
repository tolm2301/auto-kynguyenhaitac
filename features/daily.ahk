#Include ..\utils\ui_config.ahk

global hoat_dong_button := _ui_get_hoat_dong_button()


_feature_daily() {

    global isRunning, g_featureText, g_dailyWorkerPids, g_dailyStopFile
    

    _daily_init_runtime()
    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: Daily"
    hwnds := _win_get_list()
    isRunning := true

    try {
        g_dailyWorkerPids := []
        g_dailyStopFile := _daily_build_stop_file()

        for hwnd in hwnds {
            pid := _daily_start_worker(hwnd, g_dailyStopFile)
            if (pid > 0)
                g_dailyWorkerPids.Push(pid)
        }

        _daily_wait_workers(g_dailyWorkerPids, g_dailyStopFile)

        if FileExist(g_dailyStopFile)
            try FileDelete(g_dailyStopFile)

        g_dailyStopFile := ""
        g_dailyWorkerPids := []
    } finally {
        _feature_reset_running_status()
    }
}

_feature_daily_worker_entry(hwnd, stopFile := "") {
    global isRunning, g_dailyStopFile

    _daily_init_runtime()
    isRunning := true
    g_dailyStopFile := stopFile

    _feature_daily_single_hwnd(hwnd)
}

_daily_init_runtime() {
    global FEATURE_TASK_SLEEP := 5000
    global FEATURE_TASK_LONG_SLEEP := 15000
    global LOAD_SLEEP := 2000
    global SHORT_LOAD_SLEEP := 1000
    global EXIT_FEATURE_SLEEP := 7000
}

_daily_get_task_list() {
    tasks := []

    if (getDayOfTheWeekNumber() = 7) {
        tasks.Push(["huyet_chien_den_cung", huyet_chien_den_cung])
        tasks.Push(["tan_cong_hai_quan", tan_cong_hai_quan])
    }
    if (getDayOfTheWeekNumber() = 2) {
        tasks.Push(["reverse_12", reverse_12])
        tasks.Push(["dinh_phong", dinh_phong])
    }

    tasks.Push(["che_do", _che_do])                         ;1
    tasks.Push(["anh_hon", _anh_hon])                       ;2
    tasks.Push(["all_blue", _all_blue])                     ;3
    tasks.Push(["imple_down", _imple_down])                 ;4
    tasks.Push(["dung_luyen", _dung_luyen])                 ;5
    tasks.Push(["vung_bien_than_bi", _vung_bien_than_bi])   ;6
    tasks.Push(["haki", _haki])                             ;7
    tasks.Push(["nguyen_to", _nguyen_to])                   ;8
    tasks.Push(["tap_kick", _tap_kick])                     ;9
    tasks.Push(["tang_qua", _tang_qua])                     ;10
    tasks.Push(["bao_thach", _bao_thach])                   ;11
    tasks.Push(["tinh_ban", _tinh_ban])                     ;12
    tasks.Push(["ra_khoi", _ra_khoi])                       ;13
    tasks.Push(["linh_treo_thuong", _linh_treo_thuong])     ;14
    tasks.Push(["dau_truong", _dau_truong])                 ;15
    tasks.Push(["huan_luyen", _huan_luyen])                 ;16
    tasks.Push(["nau_an", _nau_an])                         ;17
    tasks.Push(["tam_bao", _tam_bao])                       ;18
    tasks.Push(["boi_duong_tinh_linh", _boi_duong_tinh_linh])                       ;19
    tasks.Push(["nhan_thuong_linh_danh_thue", _nhan_thuong_linh_danh_thue])         ;20
    tasks.Push(["dat_hang", _dat_hang])                                             ;21
    tasks.Push(["linh_the_bai", _linh_the_bai])                                     ;22
    tasks.Push(["cuong_hoa_tau_chien", _cuong_hoa_tau_chien])                       ;23
    tasks.Push(["cong_hoi", _cong_hien])                                            ;24
    tasks.Push(["nhan_hop_qua", _nhan_hop_qua])                                     ;25
    tasks.Push(["nha_xuong", _nha_xuong])                                        ;26
    tasks.Push(["daily_task_auto", _feature_daily_task_auto_run])                  ;27

    return tasks
}

_daily_get_base_dir() {
    if DirExist(A_ScriptDir . "\resources")
        return A_ScriptDir

    if DirExist(A_ScriptDir . "\..\resources")
        return A_ScriptDir . "\.."

    return A_WorkingDir
}

_daily_get_state_path() {
    return _daily_get_base_dir() . "\resources\dailystate.ini"
}

_daily_get_state_section() {
    return "Daily"
}

_daily_get_today_key() {
    return FormatTime(A_Now, "yyyyMMdd")
}

_daily_load_progress(tasks, totalTasks) {
    statePath := _daily_get_state_path()
    section := _daily_get_state_section()
    defaultState := [1, 0, ""]

    if !FileExist(statePath)
        return defaultState

    try {
        savedIndexRaw := IniRead(statePath, section, "lastCompletedTaskIndex", "0")
        savedTaskId := IniRead(statePath, section, "lastCompletedTaskId", "")
        savedIndex := Integer(savedIndexRaw)

        if (savedIndex < 0 or savedIndex > totalTasks)
            return defaultState

        completedIndex := savedIndex

        if (savedTaskId != "") {
            Loop totalTasks {
                if (tasks[A_Index][1] = savedTaskId) {
                    completedIndex := A_Index
                    break
                }
            }
        }

        startIndex := completedIndex + 1
        if (startIndex > totalTasks)
            return defaultState

        return [startIndex, completedIndex, savedTaskId]
    } catch {
        return defaultState
    }
}

_daily_save_progress(taskIndex, taskId) {
    statePath := _daily_get_state_path()
    section := _daily_get_state_section()
    SplitPath(statePath, , &stateDir)

    try {
        if (stateDir != "" and !DirExist(stateDir))
            DirCreate(stateDir)

        IniWrite(taskIndex, statePath, section, "lastCompletedTaskIndex")
        IniWrite(taskId, statePath, section, "lastCompletedTaskId")
        IniWrite(A_Now, statePath, section, "updatedAt")
    } catch {
    }
}

_daily_reset_progress() {
    statePath := _daily_get_state_path()
    section := _daily_get_state_section()

    if !FileExist(statePath)
        return

    try IniDelete(statePath, section)
}

_daily_log(msg) {
    logDir := _daily_get_base_dir() . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\daily.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    _log_append(logPath, "[" . timestamp . "] " . msg . "`n", "UTF-8")
}

_feature_daily_single_hwnd(hwnd) {
    tasks := _daily_get_task_list()
    totalTasks := tasks.Length
    progress := _daily_load_progress(tasks, totalTasks)
    startIndex := progress[1]

    if (startIndex > 1) {
        _daily_log("Resume từ task #" . startIndex . " (đã xong #" . progress[2] . " | id=" . progress[3] . ")")
    }

    Loop totalTasks {
        taskIndex := A_Index
        if (taskIndex < startIndex)
            continue

        if !_daily_should_continue() {
            _daily_log("Stop signal hwnd=" . hwnd . " tại task #" . taskIndex)
            return
        }

        task := tasks[taskIndex]
        try {
            task[2].Call(hwnd)
            _daily_save_progress(taskIndex, task[1])
            _daily_log("Done hwnd=" . hwnd . " task #" . taskIndex . " | id=" . task[1])
        } catch as err {
            _daily_log("Fail hwnd=" . hwnd . " task #" . taskIndex . " | id=" . task[1] . " | err=" . err.Message)
            throw err
        }
    }

    _daily_reset_progress()
    _daily_log("Complete daily hwnd=" . hwnd . ", reset progress")
}

_daily_should_continue() {
    global isRunning, g_dailyStopFile

    if (IsSet(isRunning) and !isRunning)
        return false

    if (IsSet(g_dailyStopFile) and g_dailyStopFile != "" and FileExist(g_dailyStopFile))
        return false

    return true
}

_daily_build_stop_file() {
    logDir := _daily_get_base_dir() . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    return logDir . "\daily_stop_" . A_NowUTC . "_" . A_TickCount . ".flag"
}

_daily_signal_stop(stopFile) {
    if (stopFile = "")
        return

    SplitPath(stopFile, , &dirPath)
    if (dirPath != "" and !DirExist(dirPath))
        DirCreate(dirPath)

    if !FileExist(stopFile)
        FileAppend("", stopFile)
}

_daily_start_worker(hwnd, stopFile) {
    pid := 0

    if A_IsCompiled {
        workerExe := _daily_resolve_worker_exe()
        if (workerExe = "")
            return 0

        runCommand := Format('"{1}" "{2}" "{3}"', workerExe, hwnd, stopFile)
        try Run(runCommand, _daily_get_base_dir(), "Hide", &pid)
        return pid
    }

    baseDir := _daily_get_base_dir()
    workerScript := baseDir . "\features\daily_worker.ahk"
    if !FileExist(workerScript)
        return 0

    runCommand := Format('"{1}" "{2}" "{3}" "{4}"', A_AhkPath, workerScript, hwnd, stopFile)
    try Run(runCommand, baseDir, "Hide", &pid)

    return pid
}

_daily_resolve_worker_exe() {
    candidates := []
    candidates.Push(A_ScriptDir . "\daily_worker.exe")
    candidates.Push(A_ScriptDir . "\features\daily_worker.exe")

    for candidate in candidates {
        if FileExist(candidate)
            return candidate
    }

    return ""
}

_daily_has_alive_workers(pids) {
    for pid in pids {
        if ProcessExist(pid)
            return true
    }

    return false
}

_daily_stop_worker_processes(pids) {
    for pid in pids {
        if ProcessExist(pid) {
            try ProcessClose(pid)
        }
    }
}

_daily_wait_workers(pids, stopFile) {
    global isRunning

    while _daily_has_alive_workers(pids) {
        if !isRunning {
            _daily_signal_stop(stopFile)
            _daily_stop_worker_processes(pids)
            break
        }

        Sleep 500
    }
}

_scroll_task(hwnd) {
    _click_post(hwnd, 925, 562)
    Sleep LOAD_SLEEP
}

huyet_chien_den_cung(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 1041, 125)
    Sleep FEATURE_TASK_SLEEP

    ; nhan thuong
    _click_post(hwnd, 797, 529)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ENTER")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_nha_xuong(hwnd) {
     ; go to tinh nang
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 977, 195)
    Sleep FEATURE_TASK_SLEEP

    ; nhan thuong
    _click_post(hwnd, 1071, 381)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 852, 287)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1211, 51)
    Sleep EXIT_FEATURE_SLEEP
}

tan_cong_hai_quan(hwnd) {
    ; go to tinh nang
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 555, 195)
    Sleep FEATURE_TASK_SLEEP

    ; buy round
    _click_post(hwnd, 630, 632)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 689, 331)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 576, 421)
    Sleep LOAD_SLEEP

    _click_post(hwnd, 1180, 31)
    Sleep LOAD_SLEEP

    count := 1
    loop Integer(4) {
        ; go to tinh nang
        _click_post(hwnd, 925, 35)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 555, 195)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 756, 512)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 756, 512)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 579, 359)
        if (count = 1) {
            Sleep FEATURE_TASK_SLEEP
        } else {
            Sleep LOAD_SLEEP
        }
        count := count + 1

        _click_post(hwnd, 1230, 635)
        Sleep LOAD_SLEEP
        _post_with_vk_string(hwnd, "ENTER")
        Sleep EXIT_FEATURE_SLEEP
    }

    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1180, 31)
    Sleep EXIT_FEATURE_SLEEP
}

_nhan_hop_qua(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP

    ; hop 1
    _click_post(hwnd, 393, 176)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 630, 460)
    Sleep LOAD_SLEEP

    ; hop 2
    _click_post(hwnd, 507, 176)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 630, 460)
    Sleep LOAD_SLEEP

    ; hop 3
    _click_post(hwnd, 619, 176)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 630, 460)
    Sleep LOAD_SLEEP

    ;hop 4
    _click_post(hwnd, 742, 176)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 630, 460)
    Sleep LOAD_SLEEP

    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_linh_treo_thuong(hwnd) {
    _click_post(hwnd, 1184, 616)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 855, 533)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep FEATURE_TASK_SLEEP
}

_tam_bao(hwnd) {
    _click_post(hwnd, 993, 40)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 836, 122)
    Sleep FEATURE_TASK_SLEEP

    Loop Integer(5) {
        _click_post(hwnd, 938, 38)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 683, 364)
        Sleep LOAD_SLEEP
        _multi_click_post(hwnd, 908, 310, 50)
        Sleep LOAD_SLEEP
        _click_post(hwnd, 557, 570)
        Sleep 60000
        _click_post(hwnd, 150, 248)
        Sleep FEATURE_TASK_SLEEP
    }

    _click_post(hwnd, 1211, 36)
    Sleep FEATURE_TASK_SLEEP
}

_dau_truong(hwnd) {
    _click_post(hwnd, 993, 40)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 763, 122)
    Sleep FEATURE_TASK_SLEEP
    Loop Integer(6) {
        _multi_click_post(hwnd, 759, 258, 15, 1000)
        _click_post(hwnd, 1013, 662)
        Sleep LOAD_SLEEP
        _post_with_vk_string(hwnd, "ESC")
        Sleep FEATURE_TASK_SLEEP
    }
    _click_post(hwnd, 1211, 36)
    Sleep FEATURE_TASK_SLEEP
}

_dat_hang(hwnd) {
    x := 704
    y := 245

    ; 1
    _click_post(hwnd, 1072, 614)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1000, 541)
    Sleep LOAD_SLEEP
    _click_post(hwnd, x, y)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 501, 268, 10, 700)
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP

    ;2
    _click_post(hwnd, 1072, 614)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1000, 541)
    Sleep LOAD_SLEEP
    _click_post(hwnd, x, 302)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 501, 268, 10, 700)
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP

    _click_post(hwnd, 1072, 614)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1000, 541)
    Sleep LOAD_SLEEP
    _click_post(hwnd, x, 357)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 501, 268, 10, 700)
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP

    _click_post(hwnd, 1072, 614)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1000, 541)
    Sleep LOAD_SLEEP
    _click_post(hwnd, x, 418)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 501, 268, 10, 700)
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP

    _click_post(hwnd, 1072, 614)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1000, 541)
    Sleep LOAD_SLEEP
    _click_post(hwnd, x, 476)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 501, 268, 10, 700)
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP

    Sleep EXIT_FEATURE_SLEEP
}

_boi_duong_tinh_linh(hwnd) {
    _click_post(hwnd, 692, 599)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 483, 610)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1037, 422)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ENTER")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1227, 38)
    Sleep EXIT_FEATURE_SLEEP
}

reverse_12(hwnd) {
    _click_post(hwnd, 926, 41)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 1045, 193)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 409, 503)
    Sleep FEATURE_TASK_LONG_SLEEP

    ; nhan qua
    _click_post(hwnd, 674, 533)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 576, 421)
    Sleep LOAD_SLEEP

    ; thoat
    _click_post(hwnd, 1222, 26)
    Sleep EXIT_FEATURE_SLEEP
}

dinh_phong(hwnd) {
    _click_post(hwnd, 926, 41)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 1045, 193)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 623, 503)
    Sleep FEATURE_TASK_LONG_SLEEP

    ; nhan qua
    _click_post(hwnd, 674, 533)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 576, 326)
    Sleep LOAD_SLEEP

    ; thoat
    _click_post(hwnd, 1222, 26)
    Sleep EXIT_FEATURE_SLEEP
}

_nhan_thuong_linh_danh_thue(hwnd) {
    _click_post(hwnd, 926, 41)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 1045, 193)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 409, 503)
    Sleep FEATURE_TASK_LONG_SLEEP
    _click_post(hwnd, 869, 33)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 738, 186)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 746, 285)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ENTER")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1222, 26)
    Sleep EXIT_FEATURE_SLEEP
}

_cuong_hoa_tau_chien(hwnd) {
    _click_post(hwnd, hoat_dong_button[1], hoat_dong_button[2])
    Sleep FEATURE_TASK_SLEEP
    _multi_click_post(hwnd, 419, 524, 2, LOAD_SLEEP)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 332, 200)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 619, 560)

    ;; start
    Sleep FEATURE_TASK_SLEEP
    _multi_click_post(hwnd, 768, 340, 20)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 768, 427, 20)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 768, 515, 20)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_mua_chien_tich(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _scroll_task(hwnd)
    _click_post(hwnd, 872, 453)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 533, 500)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 459, 349, 5)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_cong_hien(hwnd) {
    ; go cong hoi
    _click_post(hwnd, 1071, 597)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1036, 519)
    Sleep FEATURE_TASK_SLEEP

    ; start cong hien
    _click_post(hwnd, 493, 119)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 492, 336)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 705, 344)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 583, 397)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP

    ; go cong hoi
    _click_post(hwnd, 1071, 597)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1036, 519)
    Sleep FEATURE_TASK_SLEEP

    ; start VNC
    _click_post(hwnd, 656, 118)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 533, 498)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 467, 348, 5, LOAD_SLEEP)
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP

    ; go cong hoi
    _click_post(hwnd, 1071, 597)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1036, 519)
    Sleep FEATURE_TASK_SLEEP

    ; start VNC
    _click_post(hwnd, 731, 118)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 533, 498)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 467, 348, 5, LOAD_SLEEP)
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_hoi_dam(hwnd) {
    _click_post(hwnd, 61, 365)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 876, 484)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 499, 457, 6, 2000)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_linh_the_bai(hwnd) {
    _click_post(hwnd, hoat_dong_button[1], hoat_dong_button[2])
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 419, 524)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 400, 323)
    Sleep FEATURE_TASK_SLEEP

    ;Start
    _click_post(hwnd, 692, 559)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_huan_luyen(hwnd) {
    _click_post(hwnd, 69, 201)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 576, 194)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 623, 544, 2)

    Sleep LOAD_SLEEP
    _click_post(hwnd, 576, 283)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 623, 544, 2)

    Sleep LOAD_SLEEP
    _click_post(hwnd, 576, 361)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 623, 544, 2)

    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_nau_an(hwnd) {
    _click_post(hwnd, 33, 225)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 518, 148)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    x1 := 365
    x2 := 599
    x3 := 827
    y1 := 266
    y2 := 389
    y3 := 510
    _support_nau_an(hwnd, x3, y3)
    _support_nau_an(hwnd, x2, y3)
    _support_nau_an(hwnd, x1, y3)

    _support_nau_an(hwnd, x3, y2)
    _support_nau_an(hwnd, x2, y2)
    _support_nau_an(hwnd, x1, y2)

    _support_nau_an(hwnd, x3, y1)
    _support_nau_an(hwnd, x2, y1)
    _support_nau_an(hwnd, x1, y1)

    Sleep EXIT_FEATURE_SLEEP
}

_support_nau_an(hwnd, x, y) {
    _click_post(hwnd, 33, 225)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, x, y)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 581, 449, 10)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
}

_ra_khoi(hwnd) {
    _click_post(hwnd, 45, 270)
    Sleep FEATURE_TASK_SLEEP
    Loop Integer(15) {
        _click_post(hwnd, 804, 210)
        sleep LOAD_SLEEP
    }
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_che_do(hwnd) {
    _click_post(hwnd, 925, 35)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 551, 125)
    Sleep FEATURE_TASK_LONG_SLEEP
    loop Integer(7) {
        _click_post(hwnd, 279, 405)
        Sleep LOAD_SLEEP
        _post_with_vk_string(hwnd, "Enter")
        Sleep LOAD_SLEEP
    }
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1089, 334)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1143, 414)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1208, 38)
    Sleep EXIT_FEATURE_SLEEP
}

_anh_hon(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 690, 125)
    Sleep FEATURE_TASK_LONG_SLEEP
    ;
    _click_post(hwnd, 511, 623)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 711, 387)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 623, 440)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "Enter")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1222, 41)
    Sleep EXIT_FEATURE_SLEEP
}

_all_blue(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 765, 125)
    Sleep FEATURE_TASK_LONG_SLEEP
    ; thu thap
    _support_all_blue(hwnd, 319, 201)
    _support_all_blue(hwnd, 738, 243)
    _support_all_blue(hwnd, 277, 446)
    _support_all_blue(hwnd, 614, 512)
    _support_all_blue(hwnd, 897, 505)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1222, 41)
    Sleep EXIT_FEATURE_SLEEP

}

_imple_down(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 832, 125)
    Sleep FEATURE_TASK_LONG_SLEEP
    _multi_click_post(hwnd, 557, 624, 4)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1222, 41)
    Sleep EXIT_FEATURE_SLEEP
}

_dung_luyen(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 972, 125)
    Sleep FEATURE_TASK_LONG_SLEEP
    ;
    _click_post(hwnd, 548, 548)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "Enter")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1189, 46)
    Sleep EXIT_FEATURE_SLEEP
}

_vung_bien_than_bi(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 625, 181)
    Sleep FEATURE_TASK_LONG_SLEEP
    Loop Integer(10) {
        _support_vung_bien_than_bi(hwnd)
    }
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1222, 41)
    Sleep EXIT_FEATURE_SLEEP
}

_haki(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 697, 181)
    Sleep FEATURE_TASK_LONG_SLEEP
    ;
    _click_post(hwnd, 574, 615)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "Esc")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1222, 41)
    Sleep EXIT_FEATURE_SLEEP
}

_nguyen_to(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 925, 35)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 835, 181)
    Sleep FEATURE_TASK_LONG_SLEEP
    ;
    ; mua nguyen to
    _click_post(hwnd, 936, 43)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 688, 252)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 470, 354)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 549, 470)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 626, 575, 7)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1222, 41)
    Sleep EXIT_FEATURE_SLEEP
}

_tap_kick(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, hoat_dong_button[1], hoat_dong_button[2])
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 405, 321)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 886, 554)
    Sleep LOAD_SLEEP
    ;
    _click_post(hwnd, 364, 201)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 699, 546)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

; tangqua
_tang_qua(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 576, 612)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 416, 136)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 569, 461)
    Sleep LOAD_SLEEP
    _click_post(hwnd, 560, 445)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

; bao thach
_bao_thach(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 858, 615)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 679, 389)
    Sleep FEATURE_TASK_LONG_SLEEP
    ;; tim bao thach
    _click_post(hwnd, 415, 59)
    Sleep LOAD_SLEEP
    _multi_click_post(hwnd, 710, 408, 3)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    ;; Me tran
    _click_post(hwnd, 864, 38)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 828, 224)
    Sleep LOAD_SLEEP
    Loop Integer(5) {
        _click_post(hwnd, 569, 368)
        Sleep 4000
        _click_post(hwnd, 569, 408)
        Sleep 4000
    }
    _post_with_vk_string(hwnd, "ESC")
    Sleep LOAD_SLEEP
    _click_post(hwnd, 1235, 29)
    Sleep EXIT_FEATURE_SLEEP

}

_tinh_ban(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 957, 615)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 336, 559)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_treo_thuong(hwnd) {
    ; go to tinh nag
    _click_post(hwnd, 1179, 615)
    Sleep FEATURE_TASK_SLEEP
    _click_post(hwnd, 855, 533)
    Sleep LOAD_SLEEP
    _post_with_vk_string(hwnd, "ESC")
    Sleep EXIT_FEATURE_SLEEP
}

_support_all_blue(hwnd, x, y) {
    Sleep LOAD_SLEEP
    _click_post(hwnd, x, y)
    Sleep LOAD_SLEEP
    Loop Integer(10) {
        _click_post(hwnd, x, y)
        Sleep SHORT_LOAD_SLEEP
        _post_with_vk_string(hwnd, "Esc")
    }
}

_support_vung_bien_than_bi(hwnd) {
    _click_post(hwnd, 563, 583)
    _support_tra_loi_vbtb(hwnd)
    Sleep SHORT_LOAD_SLEEP
}

_support_tra_loi_vbtb(hwnd) {
    Sleep SHORT_LOAD_SLEEP
    _click_post(hwnd, 524, 332)
    Sleep SHORT_LOAD_SLEEP
    _click_post(hwnd, 860, 647)
    Sleep SHORT_LOAD_SLEEP
    _click_post(hwnd, 508, 345)
    Sleep SHORT_LOAD_SLEEP
    _click_post(hwnd, 543, 229)
    Sleep SHORT_LOAD_SLEEP
}

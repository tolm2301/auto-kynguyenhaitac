global vuon_ac_ma_feature_tab := [929, 39]
global vuon_ac_ma_screen_tab := [902, 191]
global vuon_ac_ma_exit_button := [1210, 49]
global vuon_ac_ma_seed_bag := [1001, 623]
global vuon_ac_ma_seed_1 := [432, 640]
global vuon_ac_ma_seed_2 := [367, 640]
global vuon_ac_ma_fertilizer_bag := [1135, 626]
global vuon_ac_ma_fertilizer := [364, 640]
global vuon_ac_ma_water_bottle := [1213, 625]
global VUON_AC_MA_LOAD_SLEEP := 500
global g_vuonAcMaWorkerPid := 0
global g_vuonAcMaWorkerPids := []
global vuon_ac_ma_pots := [
    [606, 190],
    [730, 251],
    [863, 304],
    [995, 359],
    [1119, 410],
    [337, 338],
    [473, 388],
    [605, 445],
    [739, 531],
    [868, 579]
]

_feature_trong_cay() {
    _vuon_ac_ma_run("Trồng cây")
}

_feature_bon_phan() {
    _vuon_ac_ma_run("Bón phân")
}

_feature_tuoi_nuoc() {
    _vuon_ac_ma_run("Tưới nước")
}

_feature_thu_hoach() {
    _vuon_ac_ma_run("Thu hoạch")
}

_vuon_ac_ma_run(actionName) {
    global isRunning, g_featureText
    global g_vuonAcMaWorkerPid, g_vuonAcMaWorkerPids

    _win_resize_list()
    hwnds := _win_get_list()
    isRunning := true
    g_featureText.text := "Tính năng đang chạy: Vườn ác ma - " . actionName

    try {
        _vuon_ac_ma_log("Start | action=" . actionName . " | hwndCount=" . hwnds.Length)

        if (hwnds.Length = 0) {
            _vuon_ac_ma_log("Skip | action=" . actionName . " | reason=no hwnd")
            return
        }

        g_vuonAcMaWorkerPids := _vuon_ac_ma_start_workers(hwnds, actionName)
        if (g_vuonAcMaWorkerPids.Length = 0) {
            g_vuonAcMaWorkerPid := 0
            g_vuonAcMaWorkerPids := []
            _vuon_ac_ma_log("Spawn failed | action=" . actionName . " | reason=no worker started")
            return
        }

        _vuon_ac_ma_wait_workers(g_vuonAcMaWorkerPids)
    } catch as err {
        _vuon_ac_ma_log("Error | action=" . actionName . " | err=" . err.Message)
    } finally {
        if (IsObject(g_vuonAcMaWorkerPids) and g_vuonAcMaWorkerPids.Length > 0)
            _vuon_ac_ma_stop_worker_processes(g_vuonAcMaWorkerPids)

        g_vuonAcMaWorkerPid := 0
        g_vuonAcMaWorkerPids := []
        _feature_reset_running_status()
    }
}

_feature_vuon_ac_ma_worker_entry(hwnd, actionName) {
    try {
        _vuon_ac_ma_log("Worker start | action=" . actionName . " | hwnd=" . hwnd)

        if !_vuon_ac_ma_is_ready(hwnd)
            throw Error("Invalid hwnd: " . hwnd)

        switch actionName {
            case "Trồng cây":
                _vuon_ac_ma_trong_cay(hwnd)
            case "Bón phân":
                _vuon_ac_ma_bon_phan(hwnd)
            case "Tưới nước":
                _vuon_ac_ma_tuoi_nuoc(hwnd)
            case "Thu hoạch":
                _vuon_ac_ma_thu_hoach(hwnd)
            default:
                throw Error("Hành động Vườn ác ma không hợp lệ: " . actionName)
        }
    } catch as err {
        _vuon_ac_ma_log("Worker error | action=" . actionName . " | hwnd=" . hwnd . " | err=" . err.Message)
    } finally {
        _feature_reset_running_status()
    }
}

_vuon_ac_ma_trong_cay(hwnd) {
    _vuon_ac_ma_log("Trồng cây | enter")
    _vuon_ac_ma_enter_feature(hwnd)

    _vuon_ac_ma_click(hwnd, vuon_ac_ma_seed_bag[1], vuon_ac_ma_seed_bag[2])
    Sleep VUON_AC_MA_LOAD_SLEEP

    _vuon_ac_ma_do_plant_cycle(hwnd, vuon_ac_ma_seed_1, "Cây 1")
    _vuon_ac_ma_do_plant_cycle(hwnd, vuon_ac_ma_seed_2, "Cây 2")

    _vuon_ac_ma_exit_feature(hwnd)
    _vuon_ac_ma_log("Trồng cây | done")
}

_vuon_ac_ma_bon_phan(hwnd) {
    _vuon_ac_ma_log("Bón phân | enter")
    _vuon_ac_ma_enter_feature(hwnd)

    _vuon_ac_ma_click(hwnd, vuon_ac_ma_fertilizer_bag[1], vuon_ac_ma_fertilizer_bag[2])
    Sleep VUON_AC_MA_LOAD_SLEEP

    _vuon_ac_ma_do_item_cycle(hwnd, vuon_ac_ma_fertilizer, "Bón phân")

    _vuon_ac_ma_exit_feature(hwnd)
    _vuon_ac_ma_log("Bón phân | done")
}

_vuon_ac_ma_tuoi_nuoc(hwnd) {
    _vuon_ac_ma_log("Tưới nước | enter")
    _vuon_ac_ma_enter_feature(hwnd)

    _vuon_ac_ma_do_item_cycle(hwnd, vuon_ac_ma_water_bottle, "Tưới nước")

    _vuon_ac_ma_exit_feature(hwnd)
    _vuon_ac_ma_log("Tưới nước | done")
}

_vuon_ac_ma_thu_hoach(hwnd) {
    _vuon_ac_ma_log("Thu hoạch | enter")
    _vuon_ac_ma_enter_feature(hwnd)

    for pot in vuon_ac_ma_pots {
        harvestY := pot[2] - 70
        _vuon_ac_ma_click(hwnd, pot[1], harvestY)
        Sleep VUON_AC_MA_LOAD_SLEEP
    }

    _vuon_ac_ma_exit_feature(hwnd)
    _vuon_ac_ma_log("Thu hoạch | done")
}

_vuon_ac_ma_enter_feature(hwnd) {
    _vuon_ac_ma_click(hwnd, vuon_ac_ma_feature_tab[1], vuon_ac_ma_feature_tab[2])
    Sleep VUON_AC_MA_LOAD_SLEEP
    _vuon_ac_ma_click(hwnd, vuon_ac_ma_screen_tab[1], vuon_ac_ma_screen_tab[2])
    _vuon_ac_ma_log("Enter | load wait 3000ms")
    Sleep 3000
}

_vuon_ac_ma_exit_feature(hwnd) {
    _vuon_ac_ma_log("Exit | ESC cleanup")
    _post_with_vk_string(hwnd, "ESC")
    Sleep VUON_AC_MA_LOAD_SLEEP
    _vuon_ac_ma_click(hwnd, vuon_ac_ma_exit_button[1], vuon_ac_ma_exit_button[2])
    Sleep VUON_AC_MA_LOAD_SLEEP
}

_vuon_ac_ma_do_plant_cycle(hwnd, selectedSeed, cycleName) {
    _vuon_ac_ma_log(cycleName . " | select")
    _vuon_ac_ma_click(hwnd, selectedSeed[1], selectedSeed[2])
    Sleep VUON_AC_MA_LOAD_SLEEP

    totalPots := vuon_ac_ma_pots.Length
    Loop totalPots {
        pot := vuon_ac_ma_pots[A_Index]
        _vuon_ac_ma_click(hwnd, pot[1], pot[2])
        Sleep VUON_AC_MA_LOAD_SLEEP

        if (A_Index < totalPots) {
            _vuon_ac_ma_reset(hwnd)
            Sleep VUON_AC_MA_LOAD_SLEEP
            _vuon_ac_ma_click(hwnd, selectedSeed[1], selectedSeed[2])
            Sleep VUON_AC_MA_LOAD_SLEEP
        }
    }
}

_vuon_ac_ma_do_item_cycle(hwnd, itemCoord, cycleName) {
    _vuon_ac_ma_log(cycleName . " | select")
    _vuon_ac_ma_click(hwnd, itemCoord[1], itemCoord[2])
    Sleep VUON_AC_MA_LOAD_SLEEP

    totalPots := vuon_ac_ma_pots.Length
    Loop totalPots {
        pot := vuon_ac_ma_pots[A_Index]
        _vuon_ac_ma_click(hwnd, pot[1], pot[2])
        Sleep VUON_AC_MA_LOAD_SLEEP

        if (A_Index < totalPots) {
            _vuon_ac_ma_reset(hwnd)
            Sleep VUON_AC_MA_LOAD_SLEEP
            _vuon_ac_ma_click(hwnd, itemCoord[1], itemCoord[2])
            Sleep VUON_AC_MA_LOAD_SLEEP
        }
    }
}

_vuon_ac_ma_reset(hwnd) {
    _post_with_vk_string(hwnd, "ESC")
    Sleep VUON_AC_MA_LOAD_SLEEP
}

_vuon_ac_ma_click(hwnd, x, y, delay := 50) {
    _click_post(hwnd, x, y, delay)
}

_vuon_ac_ma_is_ready(hwnd) {
    return (hwnd && _win_is_game_window(hwnd))
}

_vuon_ac_ma_start_worker(hwnd, actionName) {
    pid := 0
    baseDir := _vuon_ac_ma_get_base_dir()

    if A_IsCompiled {
        workerExe := _vuon_ac_ma_resolve_worker_exe(baseDir)
        if (workerExe != "") {
            _vuon_ac_ma_log("Spawn branch=EXE | hwnd=" . hwnd . " | exe=" . workerExe)
            runCommand := Format('"{1}" "{2}" "{3}"', workerExe, hwnd, actionName)
            try Run(runCommand, baseDir, "Hide", &pid)
            return pid
        }

        _vuon_ac_ma_log("Spawn branch=MAIN-EXE | hwnd=" . hwnd . " | script=" . A_ScriptFullPath)
        runCommand := Format('"{1}" --vuon-ac-ma-worker "{2}" "{3}"', A_ScriptFullPath, hwnd, actionName)
        try Run(runCommand, baseDir, "Hide", &pid)
        return pid
    }

    workerScript := baseDir . "\features\vuon_ac_ma_worker.ahk"
    if !FileExist(workerScript)
        return 0

    _vuon_ac_ma_log("Spawn branch=AHK | hwnd=" . hwnd . " | script=" . workerScript)
    runCommand := Format('"{1}" "{2}" "{3}" "{4}"', A_AhkPath, workerScript, hwnd, actionName)
    try Run(runCommand, baseDir, "Hide", &pid)
    return pid
}

_vuon_ac_ma_start_workers(hwnds, actionName) {
    pids := []

    for hwnd in hwnds {
        if !_vuon_ac_ma_is_ready(hwnd) {
            _vuon_ac_ma_log("Skip worker | action=" . actionName . " | invalid hwnd=" . hwnd)
            continue
        }

        pid := _vuon_ac_ma_start_worker(hwnd, actionName)
        if (pid > 0) {
            pids.Push(pid)
            _vuon_ac_ma_log("Spawn worker | action=" . actionName . " | hwnd=" . hwnd . " | pid=" . pid)
        } else {
            _vuon_ac_ma_log("Spawn worker failed | action=" . actionName . " | hwnd=" . hwnd)
        }
    }

    return pids
}

_vuon_ac_ma_resolve_worker_exe(baseDir) {
    candidates := []
    candidates.Push(baseDir . "\vuon_ac_ma_worker.exe")
    candidates.Push(baseDir . "\features\vuon_ac_ma_worker.exe")

    for candidate in candidates {
        if FileExist(candidate)
            return candidate
    }

    return ""
}

_vuon_ac_ma_has_alive_workers(pids) {
    for pid in pids {
        if ProcessExist(pid)
            return true
    }

    return false
}

_vuon_ac_ma_stop_worker_processes(pids) {
    for pid in pids {
        if ProcessExist(pid) {
            try ProcessClose(pid)
        }
    }
}

_vuon_ac_ma_wait_workers(pids) {
    global isRunning, g_vuonAcMaWorkerPid

    while _vuon_ac_ma_has_alive_workers(pids) {
        if !isRunning {
            _vuon_ac_ma_stop_worker_processes(pids)
            break
        }

        Sleep 500
    }

    if (pids.Length > 0)
        g_vuonAcMaWorkerPid := pids[1]
}

_vuon_ac_ma_get_base_dir() {
    if DirExist(A_ScriptDir . "\resources")
        return A_ScriptDir

    if DirExist(A_ScriptDir . "\..\resources")
        return A_ScriptDir . "\.."

    return A_WorkingDir
}

_vuon_ac_ma_log(msg) {
    logDir := _vuon_ac_ma_get_base_dir() . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)

    logPath := logDir . "\vuon_ac_ma.log"
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    _log_append(logPath, "[" . timestamp . "] " . msg . "`n", "UTF-8")
}

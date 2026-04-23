_now_hour() {
    return Integer(getHour())
}

_now_minute() {
    return Integer(getMinute())
}

_feature_punk() {
    _boss_run_parallel("punk", "Rồng punk")
}

_feature_kraken() {
    _boss_run_parallel("kraken", "Kraken")
}

_feature_kaido() {
    _boss_run_parallel("kaido", "Kaido")
}

_boss_run_parallel(mode, featureName) {
    global isRunning, g_featureText, g_bossWorkerPids

    _win_resize_list()
    g_featureText.text := "Tính năng đang chạy: " . featureName
    hwnds := _win_get_list()
    isRunning := true

    try {
        g_bossWorkerPids := _boss_start_workers(mode, hwnds)
        _boss_wait_workers(g_bossWorkerPids)
    } finally {
        _boss_stop_worker_processes(g_bossWorkerPids)
        g_bossWorkerPids := []
        _feature_reset_running_status()
    }
}

_boss_start_workers(mode, hwnds) {
    pids := []
    for hwnd in hwnds {
        pid := _boss_start_worker(mode, hwnd)
        if (pid > 0)
            pids.Push(pid)
    }
    return pids
}

_boss_start_worker(mode, hwnd) {
    pid := 0

    if A_IsCompiled {
        workerExe := _boss_resolve_worker_exe()
        if (workerExe = "")
            return 0

        runCommand := Format('"{1}" "{2}" "{3}"', workerExe, mode, hwnd)
        try Run(runCommand, A_ScriptDir, "Hide", &pid)
        return pid
    }

    workerScript := A_ScriptDir . "\features\boss_worker.ahk"
    if !FileExist(workerScript)
        return 0

    runCommand := Format('"{1}" "{2}" "{3}" "{4}"', A_AhkPath, workerScript, mode, hwnd)
    try Run(runCommand, A_ScriptDir, "Hide", &pid)
    return pid
}

_boss_resolve_worker_exe() {
    candidates := []
    candidates.Push(A_ScriptDir . "\boss_worker.exe")
    candidates.Push(A_ScriptDir . "\features\boss_worker.exe")

    for candidate in candidates {
        if FileExist(candidate)
            return candidate
    }

    return ""
}

_boss_wait_workers(pids) {
    global isRunning

    while _boss_has_alive_workers(pids) {
        if !isRunning {
            _boss_stop_worker_processes(pids)
            break
        }

        Sleep 500
    }
}

_boss_has_alive_workers(pids) {
    for pid in pids {
        if ProcessExist(pid)
            return true
    }

    return false
}

_boss_stop_worker_processes(pids) {
    for pid in pids {
        if ProcessExist(pid) {
            try ProcessClose(pid)
        }
    }
}

_boss_worker_entry(mode, hwnd) {
    try {
        switch StrLower(mode) {
            case "punk":
                _boss_run_punk_single(hwnd)
            case "kraken":
                _boss_run_kraken_single(hwnd)
            case "kaido":
                _boss_run_kaido_single(hwnd)
            default:
                throw Error("Boss mode không hợp lệ: " . mode)
        }
    } catch as err {
        _log_append(A_ScriptDir . "\logs\boss_worker_error.log", "[" . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "] " . err.Message . "`n")
    }
}

_boss_run_punk_single(hwnd) {
    Sleep 3000
    _click_post(hwnd, 729, 35)
    Sleep 3000
    _click_post(hwnd, 339, 200)
    Sleep 2000
    _click_post(hwnd, 893, 558)
    Sleep 3000
    _click_post(hwnd, 680, 73)
    Sleep 5000
    _multi_click_post(hwnd, 582, 145, 10)
    Sleep 1000

    _boss_fight_loop(hwnd)
}

_boss_run_kraken_single(hwnd) {
    Sleep 3000
    _click_post(hwnd, 729, 35)
    Sleep 3000
    _click_post(hwnd, 402, 259)
    Sleep 2000
    _click_post(hwnd, 893, 558)
    Sleep 3000
    _click_post(hwnd, 680, 73)
    Sleep 5000
    _multi_click_post(hwnd, 582, 145, 10)
    Sleep 1000

    _boss_fight_loop(hwnd)
}

_boss_run_kaido_single(hwnd) {
    Sleep 3000
    _click_post(hwnd, 1125, 541)
    Sleep 5000
    _click_post(hwnd, 1129, 122)
    Sleep 1000
    _click_post(hwnd, 1129, 173)
    Sleep 1000

    _boss_fight_loop(hwnd, false)
}

_boss_fight_loop(hwnd, shouldClickAttack := true) {
    endTick := A_TickCount + 15 * 60 * 1000

    while true {
        if (A_TickCount >= endTick) {
            Sleep 5000
            _post_with_vk_string(hwnd, "ESC")
            return
        }

        if shouldClickAttack
            _click_post(hwnd, 748, 156)

        Sleep 2000
    }
}

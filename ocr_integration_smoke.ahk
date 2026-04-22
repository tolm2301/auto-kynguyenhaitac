#Requires AutoHotkey v2.0

#Include utils\log_file.ahk
#Include utils\paddle_ocr.ahk
#Include utils\window.ahk

_feature_ocr_integration_smoke() {
    py311 := "C:\Users\ToLM\AppData\Local\Python\pythoncore-3.11-64\python.exe"
    EnvSet("OCR_WORKER_PYTHON", py311)

    imgPath := A_ScriptDir . "\.opencode\documents\images\nhiemvuhangngay\001.png"
    if !FileExist(imgPath)
        throw Error("Test image not found: " . imgPath)

    gui1 := Gui("+AlwaysOnTop +ToolWindow", "OCR Integration Smoke")
    gui1.MarginX := 0
    gui1.MarginY := 0
    gui1.AddPicture("x0 y0 w1280 h720", imgPath)
    gui1.Show("x10 y10 w1280 h720")

    Sleep(1200)

    text := _ocr_from_bit_map(gui1.Hwnd, 0, 0, 1280, 720)
    _log_append(A_ScriptDir . "\logs\ocr_integration_test.log", "text=`n" . text . "`n", "UTF-8")

    gui1.Destroy()
    FileAppend("OCR_SMOKE_OK=1`nTEXT_LEN=" . StrLen(text) . "`nTEXT_PREVIEW=" . SubStr(text, 1, 180) . "`n", "*")
}

try {
    _feature_ocr_integration_smoke()
    ExitApp(0)
} catch Error as err {
    FileAppend("OCR_SMOKE_OK=0`nERR=" . err.Message . "`n", "*")
    ExitApp(2)
}

#Requires AutoHotkey v2.0

#Include paddle_ocr_worker.ahk

_paddle_ocr_init() {
    return _ocr_worker_init()
}

_paddle_ocr_from_hbitmap(hBitmap, ocrOptions := 0) {
    return _ocr_worker_from_hbitmap(hBitmap, ocrOptions)
}

_paddle_ocr_trace(level, message, details := "", debugContext := 0) {
    _ocr_worker_trace(level, message, details, debugContext)
}

_paddle_ocr_trace_capture_request(debugContext) {
    _ocr_worker_trace_capture_request(debugContext)
}

_paddle_ocr_trace_capture_result(debugContext, result, totalElapsedMs) {
    _ocr_worker_trace_capture_result(debugContext, result, totalElapsedMs)
}

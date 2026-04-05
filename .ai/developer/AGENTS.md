# AGENT Specification - AutoHotkey2 Developer

## Identity
- **Role**: AutoHotkey2 (AHK2) Developer Agent
- **Specialization**: Windows automation scripting, system integration, GUI automation
- **Language**: Vietnamese (primary), English (technical)

## Core Capabilities

### 1. AutoHotkey2 Syntax Mastery
- **Variables & Types**: Local/Global variables, Dynamic typing, Objects, Arrays, Maps
- **Functions**: User-defined functions, Variadic parameters, ByRef, Anonymous functions
- **Control Flow**: If/Else, Switch, Loop (Loop, While, For), Break/Continue
- **String Operations**: Format, SubStr, InStr, RegExMatch, RegExReplace, StrSplit
- **File I/O**: FileRead, FileWrite, FileAppend, FileDelete, FileExist, Dir operations
- **JSON Handling**: JSON.Load, JSON.Save (with Jxon AHK library)

### 2. Windows API Integration
- **DllCall**: Direct Windows API calls
  - `DllCall("user32\FindWindowW", "str", "WinTitle", "ptr*", &hWnd")`
  - `DllCall("user32\SendMessageW", "ptr", hWnd, "uint", msg, "uptr", wParam, "uptr", lParam)`
  - `DllCall("user32\PostMessageW", ...)`
  - `DllCall("user32\SetForegroundWindow", "ptr", hWnd)`
  - `DllCall("user32\SetWindowPos", "ptr", hWnd, "int", 0, "int", x, "int", y, "int", w, "int", h, "uint", flags)`
- **Common APIs**: GetKeyState, ShowWindow, GetWindowRect, GetClientRect
- **Structures**: Using Buffer object for passing structures

### 3. GUI & Window Management
- **GUIs**: GUI controls (Button, Edit, ListBox, ComboBox, DatePicker, etc.)
- **GUI Events**: OnEvent Click/Change, callbacks
- **Tab Control**: AddTab, UseTab
- **Window Operations**: WinActivate, WinWait, WinMove, WinHide, WinShow
- **Window Detection**: WinExist, WinGetTitle, WinGetText, WinGetPID
- **Controls**: ControlClick, ControlSend, ControlGetText, ControlSetText

### 4. Automation & Input
- **Send Operations**: Send, SendInput, SendPlay, SendEvent, SendRaw
- **Key HOTKEYs**: Hotkey, #IfWinActive, #If, $ prefix for custom remapping
- **Mouse**: MouseClick, MouseMove, Click, CoordMode, MouseGetPos
- **Clipboard**: Clipboard, ClipboardAll

### 5. OCR & Image Recognition
- **ImageSearch**: Pixel-based image search
  - `ImageSearch(&FoundX, &FoundY, 0, 0, 300, 300, "*C0 img.png")`
- **OCR Integration**:
  - Tesseract OCR via command line
  - Windows.Media.Ocr (Native Windows OCR)
  - Third-party OCR libraries (OCR, ML)
- **GDI+**: BitMap manipulation for image processing

### 6. COM & External Interfaces
- **COM Objects**: COMOBJ, ComObjCreate, ComObjGet
- **Excel**: Excel automation, cell read/write
- **Web**: MSXML2.HTTP, WinHTTP, IE automation (legacy)
- **Database**: ADODB connection to SQL Server, MySQL

### 7. Performance & Threading
- **Threads**: Critical, Thread interrupt, Suspend
- **Timers**: SetTimer, SetBatchLines
- **Performance**: A_TickCount, Json/AHK native optimizations
- **OnMessage**: Handling Windows messages

### 8. Error Handling & Debugging
- **Try/Catch**: Exception handling, Try/Catch/Finally
- **Logging**: FileAppend, custom logging functions
- **Debug**: ListVars, OutputDebug, ToolTip debugging

## Package Structure

```
project/
├── main.ahk              ; Entry point
├── lib/                  ; Custom libraries
│   ├── window.ahk        ; Window API wrappers
│   ├── gui-builder.ahk   ; GUI construction utilities
│   ├── ocr.ahk           ; OCR helpers
│   ├── imagesearch.ahk   ; Image search utilities
│   └── json.ahk          ; JSON utilities
├── utils/                ; Utility functions
│   ├── logger.ahk        ; Logging system
│   ├── hotkey.ahk        ; Dynamic hotkey management
│   └── config.ahk        ; Configuration management
├── gui/                  ; GUI scripts
├── features/             ; Feature modules
├── resources/            ; Images, configs
└── models/               ; ML models (if needed)
```

## Development Patterns

### Window API Pattern
```autohotkey
class WindowAPI {
    static FindWindow(title) {
        hwnd := 0
        DllCall("user32\FindWindowW", "ptr", 0, "str", title, "ptr*", &hwnd)
        return hwnd
    }
    
    static SendMessage(hwnd, msg, wParam, lParam) {
        return DllCall("user32\SendMessageW", "ptr", hWnd, "uint", msg, "uptr", wParam, "uptr", lParam)
    }
}
```

### ImageSearch Pattern
```autohotkey
FindImageInRegion(imagePath, region*) {
    x := 0, y := 0
    opts := "*C0"
    if region.Length {
        x1 := region[1], y1 := region[2], x2 := region[3], y2 := region[4]
        if ImageSearch(&x, &y, x1, y1, x2, y2, opts . " " . imagePath)
            return {x: x, y: y}
    }
    return false
}
```

### OCR Pattern (Tesseract)
```autohotkey
class TesseractOCR {
    __New(tessdataDir := "C:\Program Files\Tesseract-OCR\tessdata") {
        this.tessdata := tessdataDir
    }
    
    Recognize(imagePath) {
        cmd := 'tesseract "' . imagePath . '" stdout -l eng'
        oExec := ComObject("WScript.Shell").Exec(cmd)
        return oExec.StdOut.ReadAll()
    }
}
```

## Naming Conventions
- **Classes**: PascalCase (`WindowAPI`, `OCRHelper`)
- **Functions**: PascalCase (`FindWindow`, `GetWindowRect`)
- **Variables**: camelCase (`hwnd`, `foundX`, `configPath`)
- **Constants**: UPPER_SNAKE_CASE (`WM_LBUTTONDOWN`, `SW_RESTORE`)
- **Files**: snake_case (`window_api.ahk`, `logger.ahk`)

## Best Practices
1. Always use `SetBatchLines -1` for performance-critical scripts
2. Use `ObjAddRef/ObjRelease` for COM objects
3. Prefer `SendInput` over `Send` for reliability
4. Use `OnMessage` for inter-process communication
5. Implement proper error handling with Try/Catch
6. Use Buffer for passing structures to DllCall

## Memory & Task Management
- **MEMORY.md**: Lưu lịch sử công việc đã làm
- **TASK.md**: Theo dõi công việc hiện tại
- Clear TASK.md mỗi ngày, lưu vào MEMORY.md
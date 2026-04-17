---
name: python-automation
description: Windows automation with Python using pywin32, DllCall, OCR, ImageSearch, and GUI control
license: MIT
compatibility: opencode
---

## What I do
- Automate Windows via pywin32 (Win32 API, COM, DllCall)
- Implement OCR with Windows.Media.Ocr or Tesseract
- ImageSearch with multi-template matching
- Control windows/apps via ControlClick, PostMessage, SendMessage

## Strategy priority
1. `ControlClick` / `ControlSend` via ClassNN or control handle
2. `PostMessage` / `SendMessage` to specific control/window
3. `WinActivate + SendInput`
4. Direct coordinate click (last resort only)

## Win32 API wrapper
```python
import ctypes
from ctypes import wintypes

user32 = ctypes.windll.user32

def find_window(title: str) -> int:
    return user32.FindWindowW(None, title)

def set_foreground(hwnd: int) -> bool:
    return bool(user32.SetForegroundWindow(hwnd))

def send_message(hwnd: int, msg: int, wparam: int = 0, lparam: int = 0) -> int:
    return user32.SendMessageW(hwnd, msg, wparam, lparam)
```

## Control pattern
```python
import subprocess
import time

def activate_and_click(win_title: str, control_name: str):
    hwnd = find_window(win_title)
    if not hwnd:
        raise RuntimeError(f"Window not found: {win_title}")

    set_foreground(hwnd)
    time.sleep(0.1)

    # Use ControlClick if available, otherwise fall back to coordinate click
    # Implementation depends on specific use case
```

## OCR pattern
```python
from PIL import Image
import pytesseract

def normalize_ocr_text(raw_text: str) -> str:
    import re
    text = raw_text.strip()
    text = re.sub(r"\s+", "", text)
    text = re.sub(r"[^0-9]", "", text)
    return text

def ocr_region(image_path: str) -> str:
    img = Image.open(image_path)
    return pytesseract.image_to_string(img, lang="eng")
```

## ImageSearch pattern
```python
from PIL import Image
import numpy as np

def find_any_image(
    image_paths: list[str],
    region: tuple[int, int, int, int],
) -> dict:
    """Search for any of the provided template images in the region."""
    for image_path in image_paths:
        # Implementation using template matching
        # Return {ok: True, x: int, y: int, image: str} on success
        pass
    return {"ok": False}
```

## Stability checklist
1. Verify correct window: title + pid if needed
2. Always use timeout for `WinWait*` operations
3. Use retry when control responds slowly
4. Log clearly which step failed: window, control, action

## When to use me
Use this when building Windows automation features that interact with applications, games, or system controls.

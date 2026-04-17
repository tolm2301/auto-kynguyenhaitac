import ctypes
from ctypes import wintypes
import win32gui
import win32con
from typing import Optional, List, Tuple
from .logger import get_logger

logger = get_logger()

GAME_TITLE = "Kỷ Nguyên Hải Tặc"
GAME_TITLE_1 = "Kỷ Nguyên Hải Tặc 1"
GAME_WIDTH = 1280
GAME_HEIGHT = 720

SWP_NOZORDER = 0x0004
SWP_NOACTIVATE = 0x0010
SWP_SHOWWINDOW = 0x0040


def get_game_window(title: str = None) -> Optional[int]:
    """Get game window handle by title."""
    if title is None:
        title = GAME_TITLE
    
    hwnd = win32gui.FindWindow(None, title)
    
    if not hwnd:
        hwnd = win32gui.FindWindow(None, GAME_TITLE_1)
        if hwnd:
            title = GAME_TITLE_1
    
    if not hwnd:
        logger.error(f'Không tìm thấy cửa sổ game: {title}')
        return None
    
    logger.debug(f'Tìm thấy cửa sổ game: {title} (hwnd={hwnd})')
    return hwnd


def get_game_window_1() -> Optional[int]:
    """Get game window with title 'Kỷ Nguyên Hải Tặc 1'."""
    return get_game_window(GAME_TITLE_1)


BROWSER_PROCESSES = {
    "chrome.exe", "msedge.exe", "firefox.exe", "brave.exe",
    "opera.exe", "opera_gx.exe", "iexplore.exe",
}


def _is_browser_process(process_name: str) -> bool:
    """Check if process is a browser (to exclude browser-based game windows)."""
    return process_name.lower() in BROWSER_PROCESSES


def get_game_windows(include_hidden: bool = True) -> List[int]:
    """Get list of all game window handles.

    Args:
        include_hidden: If True, also find hidden windows (matching AHK DetectHiddenWindows).
    """
    import win32process

    hwnds = []

    def enum_callback(hwnd, _):
        # Include hidden windows if requested
        if not include_hidden and not win32gui.IsWindowVisible(hwnd):
            return True

        title = win32gui.GetWindowText(hwnd)
        if GAME_TITLE not in title and GAME_TITLE_1 not in title:
            return True

        # Exclude browser processes
        try:
            _, pid = win32process.GetWindowThreadProcessId(hwnd)
            import ctypes
            buf = ctypes.create_unicode_buffer(260)
            ctypes.windll.kernel32.OpenProcess(0x0400, False, pid)
            handle = ctypes.windll.kernel32.OpenProcess(0x0410, False, pid)
            if handle:
                ctypes.windll.psapi.GetModuleBaseNameW(handle, 0, buf, 260)
                ctypes.windll.kernel32.CloseHandle(handle)
                process_name = buf.value
                if _is_browser_process(process_name):
                    return True
        except Exception:
            pass

        hwnds.append(hwnd)
        return True

    win32gui.EnumWindows(enum_callback, None)

    if not hwnds:
        logger.warning('Không tìm thấy cửa sổ game nào')
    else:
        logger.info(f'Tìm thấy {len(hwnds)} cửa sổ game: {hwnds}')

    return hwnds


def resize_game(hwnd: int = None, activate: bool = False) -> bool:
    """
    Resize single game window to 1280x720.
    
    Args:
        hwnd: Window handle, if None will find game window
        activate: If True, bring window to foreground (default False)
    """
    if hwnd is None:
        hwnd = get_game_window()
    
    if not hwnd:
        return False
    
    try:
        x, y, _, _ = win32gui.GetWindowRect(hwnd)
        
        flags = SWP_NOZORDER | SWP_NOACTIVATE | SWP_SHOWWINDOW
        ctypes.windll.user32.SetWindowPos(
            hwnd, 0, x, y, GAME_WIDTH, GAME_HEIGHT, 
            flags
        )
        
        if activate:
            win32gui.SetForegroundWindow(hwnd)
        
        logger.info(f'Resize game window {hwnd} to {GAME_WIDTH}x{GAME_HEIGHT}')
        return True
        
    except Exception as e:
        logger.error(f'Lỗi resize game: {e}')
        return False


def resize_all_games() -> int:
    """Resize all game windows to 1280x720. Returns number of resized windows."""
    hwnds = get_game_windows()
    count = 0
    
    flags = SWP_NOZORDER | SWP_NOACTIVATE | SWP_SHOWWINDOW
    
    for hwnd in hwnds:
        try:
            x, y, _, _ = win32gui.GetWindowRect(hwnd)
            
            ctypes.windll.user32.SetWindowPos(
                hwnd, 0, x, y, GAME_WIDTH, GAME_HEIGHT,
                flags
            )
            count += 1
            logger.debug(f'Resize window {hwnd}')
            
        except Exception as e:
            logger.error(f'Lỗi resize window {hwnd}: {e}')
    
    logger.info(f'Resize {count}/{len(hwnds)} cửa sổ game')
    return count


def get_window_rect(hwnd: int) -> Tuple[int, int, int, int]:
    """Get window rectangle (x, y, width, height)."""
    rect = win32gui.GetWindowRect(hwnd)
    return (rect[0], rect[1], rect[2] - rect[0], rect[3] - rect[1])


def activate_window(hwnd: int) -> bool:
    """Activate and bring window to foreground."""
    try:
        win32gui.SetForegroundWindow(hwnd)
        return True
    except Exception as e:
        logger.error(f'Lỗi activate window: {e}')
        return False

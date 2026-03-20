import ctypes
import time
from ctypes import wintypes
from typing import Optional
from .logger import get_logger
from .window import get_game_window, get_game_windows

logger = get_logger()

WM_LBUTTONDOWN = 0x0201
WM_LBUTTONUP = 0x0202
WM_MOUSEMOVE = 0x0200
WM_KEYDOWN = 0x0100
WM_KEYUP = 0x0101


def _make_lparam(x: int, y: int) -> int:
    """Create lParam for mouse messages."""
    return (y << 16) | (x & 0xFFFF)


def _get_scan_code(vk_code: int) -> int:
    """Get scan code from virtual key code."""
    return ctypes.windll.user32.MapVirtualKeyA(vk_code, 0)


def click_post(hwnd: int, x: int, y: int, delay: float = 0.03) -> bool:
    """Send mouse click to window at coordinates (x, y)."""
    try:
        lparam = _make_lparam(x, y)
        
        ctypes.windll.user32.PostMessageW(hwnd, WM_LBUTTONDOWN, 1, lparam)
        time.sleep(delay)
        ctypes.windll.user32.PostMessageW(hwnd, WM_LBUTTONUP, 0, lparam)
        
        logger.debug(f'Click: hwnd={hwnd}, x={x}, y={y}')
        return True
        
    except Exception as e:
        logger.error(f'Lỗi click_post: {e}')
        return False


def multi_click_post(hwnd: int, x: int, y: int, count: int, delay: float = 0.5) -> bool:
    """Send multiple mouse clicks to window."""
    try:
        for i in range(count):
            click_post(hwnd, x, y)
            logger.debug(f'Multi-click [{i+1}/{count}]: x={x}, y={y}')
            time.sleep(delay)
        return True
        
    except Exception as e:
        logger.error(f'Lỗi multi_click_post: {e}')
        return False


def drag_mouse(hwnd: int, x1: int, y1: int, x2: int, y2: int, steps: int = 25) -> bool:
    """Drag mouse from (x1, y1) to (x2, y2)."""
    try:
        lparam1 = _make_lparam(x1, y1)
        lparam2 = _make_lparam(x2, y2)
        
        ctypes.windll.user32.PostMessageW(hwnd, WM_LBUTTONDOWN, 0, lparam1)
        time.sleep(0.2)
        
        for i in range(1, steps + 1):
            intermediate_x = x1 + ((x2 - x1) * i) / steps
            intermediate_y = y1 + ((y2 - y1) * i) / steps
            lparam_move = _make_lparam(int(intermediate_x), int(intermediate_y))
            
            ctypes.windll.user32.PostMessageW(hwnd, WM_MOUSEMOVE, 0, lparam_move)
            time.sleep(0.01)
        
        ctypes.windll.user32.PostMessageW(hwnd, WM_LBUTTONDOWN, 0, lparam2)
        time.sleep(0.1)
        ctypes.windll.user32.PostMessageW(hwnd, WM_LBUTTONUP, 0, lparam2)
        
        logger.debug(f'Drag: ({x1},{y1}) -> ({x2},{y2}), steps={steps}')
        return True
        
    except Exception as e:
        logger.error(f'Lỗi drag_mouse: {e}')
        return False


def post_key(hwnd: int, vk_code: int, delay: float = 0.01) -> bool:
    """Send key press to window."""
    try:
        sc = _get_scan_code(vk_code)
        
        lparam_down = (sc << 16) | 1
        lparam_up = (sc << 16) | 0xC0000001
        
        ctypes.windll.user32.PostMessageW(hwnd, WM_KEYDOWN, vk_code, lparam_down)
        time.sleep(delay)
        ctypes.windll.user32.PostMessageW(hwnd, WM_KEYUP, vk_code, lparam_up)
        
        logger.debug(f'Key: vk={vk_code:#x}, hwnd={hwnd}')
        return True
        
    except Exception as e:
        logger.error(f'Lỗi post_key: {e}')
        return False


def post_key_string(hwnd: int, key_string: str, delay: float = 0.01) -> bool:
    """Send key string (e.g., 'ESC', 'Enter', '1') to window."""
    vk_map = {
        'ESC': 0x1B,
        'Enter': 0x0D,
        'Tab': 0x09,
        'Space': 0x20,
    }
    
    try:
        for char in key_string:
            if key_string.upper() in vk_map:
                vk = vk_map[key_string.upper()]
            else:
                vk = ord(char.upper())
            
            post_key(hwnd, vk, delay)
            
        return True
        
    except Exception as e:
        logger.error(f'Lỗi post_key_string: {e}')
        return False


VK_CODES = {
    '0': 0x30, '1': 0x31, '2': 0x32, '3': 0x33, '4': 0x34,
    '5': 0x35, '6': 0x36, '7': 0x37, '8': 0x38, '9': 0x39,
    'A': 0x41, 'B': 0x42, 'C': 0x43, 'D': 0x44, 'E': 0x45,
    'F': 0x46, 'G': 0x47, 'H': 0x48, 'I': 0x49, 'J': 0x4A,
    'K': 0x4B, 'L': 0x4C, 'M': 0x4D, 'N': 0x4E, 'O': 0x4F,
    'P': 0x50, 'Q': 0x51, 'R': 0x52, 'S': 0x53, 'T': 0x54,
    'U': 0x55, 'V': 0x56, 'W': 0x57, 'X': 0x58, 'Y': 0x59,
    'Z': 0x5A,
    'Esc': 0x1B, 'Escape': 0x1B,
    'Enter': 0x0D, 'Return': 0x0D,
    'Tab': 0x09,
    'Space': 0x20, ' ': 0x20,
}


def send_key(hwnd: int, key: str, delay: float = 0.01) -> bool:
    """Send key by name (e.g., '1', 'Esc', 'Enter')."""
    vk = VK_CODES.get(key, ord(key.upper()) if len(key) == 1 else 0)
    if not vk:
        logger.error(f'Unknown key: {key}')
        return False
    return post_key(hwnd, vk, delay)


def send_keys(hwnd: int, keys: list, delays: list = None) -> bool:
    """Send multiple keys with optional delays."""
    for i, key in enumerate(keys):
        if not send_key(hwnd, key):
            return False
        if delays and i < len(delays):
            time.sleep(delays[i])
    return True

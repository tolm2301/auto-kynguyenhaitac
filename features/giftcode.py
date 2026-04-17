"""
Gift code feature - automatically input gift codes into the game.

Ported from AHK features/giftcode.ahk
"""

import time
import random
import string
from typing import Optional

from utils import get_logger, get_game_window, resize_game, click_post, send_key
from utils.state import set_running, stop as state_stop, get_is_running

logger = get_logger()

# Gift code button and input coordinates
GIFT_CODE_BTN = (273, 73)
GIFT_CODE_INPUT = (620, 343)
GIFT_CODE_SUBMIT = (739, 343)


def _post_string(hwnd: int, text: str) -> bool:
    """Send a string of characters to a window via WM_CHAR messages."""
    import ctypes

    WM_CHAR = 0x0102

    try:
        for ch in text:
            char_code = ord(ch)
            ctypes.windll.user32.PostMessageW(hwnd, WM_CHAR, char_code, 1)
            time.sleep(0.005)
        return True
    except Exception as e:
        logger.error(f"Error posting string: {e}")
        return False


def _input_gift_code(hwnd: int, code: str) -> bool:
    """Input a single gift code into the game window."""
    try:
        # Click gift code button
        click_post(hwnd, GIFT_CODE_BTN[0], GIFT_CODE_BTN[1])
        time.sleep(0.05)

        # Click input field
        click_post(hwnd, GIFT_CODE_INPUT[0], GIFT_CODE_INPUT[1])
        time.sleep(0.05)

        # Type the code
        _post_string(hwnd, code)
        time.sleep(0.1)

        # Click submit
        click_post(hwnd, GIFT_CODE_SUBMIT[0], GIFT_CODE_SUBMIT[1])
        time.sleep(0.1)

        # Close dialog
        send_key(hwnd, 'Esc')
        time.sleep(0.1)

        logger.info(f"Submitted gift code: {code}")
        return True
    except Exception as e:
        logger.error(f"Error inputting gift code: {e}")
        return False


def _generate_code(prefix: str) -> str:
    """Generate a random gift code with given prefix."""
    rand_num = random.randint(0, 100)
    chars = string.ascii_lowercase + string.digits
    suffix = ''.join(random.choice(chars) for _ in range(14))
    return f"{prefix}_{rand_num}-{suffix}"


def feature_giftcode(codes: str, status_callback=None) -> bool:
    """
    Feature: Input gift codes.

    Args:
        codes: Newline-separated list of gift codes
        status_callback: Optional callback for status updates
    """
    if not codes or not codes.strip():
        logger.error("Vui lòng nhập gift code!")
        return False

    if status_callback:
        status_callback("Tính năng đang chạy: Gift Code")

    if not resize_game():
        logger.error("Không resize được game")
        state_stop()
        return False

    hwnd = get_game_window()
    if not hwnd:
        logger.error("Không tìm thấy cửa sổ game!")
        state_stop()
        return False

    set_running("Gift Code", None, status_callback)
    logger.info("Starting gift code input")

    try:
        code_list = [c.strip() for c in codes.replace('\r', '').split('\n') if c.strip()]

        for code in code_list:
            if not get_is_running():
                return True

            _input_gift_code(hwnd, code)
            time.sleep(0.3)
    except Exception as e:
        logger.error(f"Gift code error: {e}")
    finally:
        state_stop()

    logger.info("Feature giftcode completed")
    return True


def feature_giftcode_pattern(prefix: str, count: int, status_callback=None) -> bool:
    """
    Feature: Generate and input gift codes with a pattern.

    Args:
        prefix: Code prefix
        count: Number of codes to generate
        status_callback: Optional callback for status updates
    """
    if not prefix or not prefix.strip():
        logger.error("Vui lòng nhập prefix!")
        return False

    if status_callback:
        status_callback(f"Tính năng đang chạy: Gift Code Pattern ({prefix})")

    if not resize_game():
        logger.error("Không resize được game")
        state_stop()
        return False

    hwnd = get_game_window()
    if not hwnd:
        logger.error("Không tìm thấy cửa sổ game!")
        state_stop()
        return False

    set_running("Gift Code Pattern", None, status_callback)
    logger.info(f"Starting gift code pattern: {prefix} x {count}")

    try:
        for i in range(count):
            if not get_is_running():
                return True

            code = _generate_code(prefix)
            logger.info(f"Generated code {i + 1}/{count}: {code}")
            _input_gift_code(hwnd, code)
            time.sleep(0.3)
    except Exception as e:
        logger.error(f"Gift code pattern error: {e}")
    finally:
        state_stop()

    logger.info("Feature giftcode pattern completed")
    return True
